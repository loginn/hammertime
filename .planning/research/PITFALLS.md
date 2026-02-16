# Pitfalls Research

**Domain:** Pack-based idle ARPG combat system integration
**Researched:** 2026-02-16
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Armor Formula Division by Zero and Edge Cases

**What goes wrong:**
Damage reduction formulas using `armor / (armor + constant)` fail at extremes: division by zero with uncapped armor, negative armor creating inverted damage reduction, and resistance caps not enforced leading to invincibility or one-shot deaths.

**Why it happens:**
Developers port standard ARPG formulas (Path of Exile uses `Damage Reduction = Armour/(Armour + 12 * Damage)`, capped at 90%) without implementing the full edge case handling. The formula appears mathematically sound but breaks when armor goes negative (from debuffs), exceeds intended caps, or when incoming damage is zero.

**How to avoid:**
1. **Hard cap all mitigation at 90%** (industry standard per PoE, Diablo)
2. **Implement floor at -100%** for negative armor (vulnerability debuffs)
3. **Clamp resistances to range [-100, 90]** before calculation
4. **Add epsilon check** before division: `if damage < 0.01: return 0`
5. **Use separate formulas** for positive vs negative armor (asymmetric scaling)
6. **Test with extreme values**: armor=0, armor=999999, armor=-1000, damage=0, damage=0.001

**Warning signs:**
- Hero survives with 0 health displayed
- Negative damage numbers appearing
- Combat log shows "NaN" or "inf" values
- 1-damage hits killing hero from full health
- Armor stat display showing negative percentages
- Combat becomes trivial with moderate armor investment

**Phase to address:**
Phase 1 (damage reduction implementation) — include test suite with edge cases in acceptance criteria.

---

### Pitfall 2: Progression Curve Disruption from Gameplay Loop Change

**What goes wrong:**
Switching from time-based to pack-based clearing breaks the carefully tuned v1.0-v1.1 progression curve. Currency drop rates balanced for "X per minute" become "X per pack," but pack clear speed varies wildly with gear, creating exponential acceleration or grinding halt. Players with optimized v1.1 gear suddenly progress 10x faster or slower than intended.

**Why it happens:**
Incremental games rely on tightly balanced faucets (resources in) and sinks (resources out). Time-based systems have predictable resource generation rates. Pack-based systems make generation variable based on combat effectiveness, which compounds with gear progression. As noted in game economy research, "if faucet output accumulates faster than sinks consume, purchasing power drops and progression becomes meaningless."

**How to avoid:**
1. **Normalize currency drops to DPS tiers**: High DPS players fight harder packs with proportional rewards
2. **Implement pack scaling**: Area 1 = 3 monsters/pack, Area 300 = 8 monsters/pack, adjust currency per monster to maintain total per-clear rate
3. **Add statistical baseline testing**: Simulate 1000 area clears at each gear tier (beginner, mid, endgame) and verify currency/hour matches v1.1 baseline ±20%
4. **Preserve existing LootTable.roll_currency_drops() rates** — these are already balanced, just need to maintain per-clear frequency
5. **Add debug telemetry**: Track actual clears/minute, currency/minute, compare to v1.1 benchmarks

**Warning signs:**
- Playtest feedback: "I'm stuck, can't afford to craft"
- Playtest feedback: "I have 9999 hammers after 10 minutes"
- Area 100 clears in 2 seconds but currency gain feels slow
- Area 10 takes 30 seconds and currency gain is too fast
- Drop simulator shows extreme variance between gear tiers

**Phase to address:**
Phase 3 (drop split implementation) and Phase 4 (combat pacing) — explicit verification step to compare v1.1 vs v1.2 progression curves.

---

### Pitfall 3: Combat Pacing Mismatch for Idle Games

**What goes wrong:**
Combat either resolves instantly (feels like a clicker, not idle) or drags for 2-3 minutes per pack (frustrating, player alt-tabs and forgets the game). The "idle" aspect requires combat to be fast enough to feel automated but slow enough to feel strategic. Getting this wrong makes the game unplayable.

**Why it happens:**
Active vs passive play tension: games balanced for active clicking feel glacially slow in idle mode. Community discussions show idle games commonly suffer from "2-3 minutes to kill one enemy" problems. Developers design for "satisfying active experience" but idle games need "satisfying passive experience." These have opposing requirements.

**How to avoid:**
1. **Target combat duration: 5-15 seconds per pack** at appropriate gear level
2. **Implement time-to-kill (TTK) normalization**: If hero DPS = 100 and pack HP = 1500, fight lasts 15s. Scale pack HP logarithmically with area to maintain TTK as DPS increases
3. **Add combat speed multiplier setting**: 1x, 2x, 4x speed options (UI toggle)
4. **Avoid animation bottlenecks**: Don't tie combat resolution to animation completion
5. **Use exponential pack HP scaling** with logarithmic curve flattening at high areas (match PoE2 approach: early packs scale fast, late game stabilizes)
6. **Test with underpowered gear**: If player ignores upgrades, combat should become challenging but not impossible

**Warning signs:**
- Pack dies in <1 second consistently
- Pack takes >30 seconds to clear
- Playtester says "I can't tell if I'm winning"
- Health bars don't visibly move for 5+ seconds
- Combat feels like waiting, not playing
- Player stops checking game because "nothing happens"

**Phase to address:**
Phase 4 (combat pacing) — primary focus. Requires tuning pack HP curve against existing StatCalculator DPS formulas.

---

### Pitfall 4: State Management Race Conditions During Combat

**What goes wrong:**
Hero starts clearing Area 5, player unequips weapon mid-combat, DPS recalculates to 0, division by zero crashes game or pack becomes unkillable. Or: hero dies, UI shows "Clearing Area 10," player clicks "Clear" again, spawns two parallel combat loops, double-drops currency, breaks economy.

**Why it happens:**
GameState autoload is globally mutable. Combat is asynchronous (timed loops). Equipment changes trigger `Hero.update_stats()` which modifies `total_dps` while combat logic reads it. Godot autoloads don't have built-in transaction safety. As noted in game state management research, "clients handle presentation while server manages integrity" — but single-player idle games combine both roles in one autoload, creating race condition vulnerability.

**How to avoid:**
1. **Lock equipment during combat**: Disable unequip/craft actions while `Hero.is_clearing == true`
2. **Snapshot combat stats**: When combat starts, copy `hero.total_dps`, `hero.total_armor`, etc. to local variables, use snapshots for entire pack fight
3. **Atomic state transitions**: Use signal-based state machine (IDLE → COMBAT_STARTING → COMBAT_ACTIVE → COMBAT_ENDING → IDLE), prevent re-entry
4. **Validate state before actions**: Check `!hero.is_clearing` before starting new combat
5. **Add state transition logging**: Print "STATE: IDLE → COMBAT_ACTIVE" to detect double-transitions in testing
6. **Use GameEvents signal bus** (already exists in autoloads/) for combat lifecycle: `combat_started.emit()`, `combat_ended.emit()`, views listen and disable actions

**Warning signs:**
- "Hero took NaN damage" in console
- Currency count jumps by 2x expected amount
- Clicking "Clear Area" multiple times spawns multiple timers
- Unequipping weapon mid-combat freezes game
- Hero dies but UI still shows "Clearing..."
- Debug prints show overlapping combat loops

**Phase to address:**
Phase 2 (pack-based combat loop) — implement state machine and locking from start. Phase 5 (death mechanics) — verify state transitions handle death edge case.

---

### Pitfall 5: Resistance Cap Bypass and Invincibility

**What goes wrong:**
Player stacks fire resistance to 150% via suffixes on all gear slots. Elemental damage formula doesn't cap resistance. Hero becomes immune to fire damage despite resistances having 75% soft cap and 90% hard cap in standard ARPGs. Or worse: resistance formula uses `damage * (1 - resistance/100)` without clamping, 150% resistance creates negative damage, healing the hero when hit.

**Why it happens:**
Hero.calculate_defense() sums resistances from all items without bounds checking. Developers assume "items can't roll that high" but forget Magic items can get +15% resistance suffix, Rare items get 3 suffixes, plus weapon suffix, plus ring suffix = 5 sources × 15% = 75% from suffixes alone. Add in implicit modifiers or percentage-based affixes and cap is easily exceeded. Path of Exile caps at 90% with explicit bounds, Diablo 2 caps at 75% (95% with items), Diablo 4 uses diminishing returns multiplication.

**How to avoid:**
1. **Clamp all resistances to [-100, 90]** range in calculate_defense()
2. **Display capped and uncapped values**: UI shows "Fire Res: 75% (150% uncapped)" to inform player
3. **Apply cap before damage calculation**, never trust raw values
4. **Add overcap testing**: Create test hero with 200% resistance, verify damage reduction = 90%
5. **Consider diminishing returns**: Diablo 4's multiplicative stacking prevents extreme values organically
6. **Add elemental penetration mechanic later** (allows uncapped resistance to matter vs penetration debuffs)

**Warning signs:**
- Hero takes 0 damage from elemental attacks
- Negative damage numbers in combat log
- Resistance stat shows >100% value
- Fire enemies become completely trivial
- Boss fights feel broken/too easy at certain resistance thresholds
- Testing reveals invincibility builds

**Phase to address:**
Phase 1 (defensive prefix foundation) — when elemental resistance prefixes are implemented, add capping logic immediately. Phase 4 (combat pacing) — verify caps are working in actual combat.

---

### Pitfall 6: Drop Split Implementation Breaking LootTable

**What goes wrong:**
LootTable currently handles both item and currency drops via `roll_rarity()` and `roll_currency_drops()`. Drop split requires "packs drop currency, maps drop items." Developer adds `source_type` parameter to methods, breaks existing crafting_view.gd calls that don't pass parameter, game crashes on craft. Or: currency drop rates get accidentally halved because both pack-clear AND map-clear call currency logic.

**Why it happens:**
LootTable is used by both future combat system (pack drops) AND existing crafting system (simulate drops for testing). Changing method signatures breaks backward compatibility. Adding conditional logic ("if source == pack: drop currency, else: drop items") creates branching paths that are hard to test. The class conflates "loot generation" with "loot source."

**How to avoid:**
1. **Create separate methods, don't modify existing**: Add `roll_pack_drops()` and `roll_map_drops()`, keep `roll_rarity()` and `roll_currency_drops()` unchanged for existing callers
2. **Deprecate carefully**: Mark old methods with `# DEPRECATED: Use roll_pack_drops() instead` comments
3. **Test existing flows first**: Run drop_simulator.gd before and after changes, verify identical output for unchanged code paths
4. **Use composition over modification**: Create `PackDropper` and `MapDropper` wrapper classes that call LootTable internally
5. **Add integration test**: Verify crafting_view still works after LootTable changes

**Warning signs:**
- Existing crafting UI breaks after combat implementation
- Drop simulator results change unexpectedly
- Currency drops become inconsistent
- Items drop from sources that shouldn't drop them
- Test failures in unrelated systems after LootTable edit
- "Too many arguments" or "Missing argument" errors from existing code

**Phase to address:**
Phase 3 (drop split) — design phase explicitly calls out backward compatibility requirement. Add regression tests before modifying LootTable.

---

### Pitfall 7: Negative Armor Amplification Asymmetry

**What goes wrong:**
Enemy applies -50 armor debuff. Hero has 100 armor. Developer uses same formula for positive and negative: `DR = armor/(armor+100)`. At 50 armor, DR = 33%. At 100 armor, DR = 50%. So -50 armor debuff increased damage by 1.5x. BUT: +50 armor buff only reduced damage by 0.8x. Asymmetric benefit makes debuffs overpowered, trivializes defensive investment, creates death spiral (debuff → take more damage → die faster → can't recover).

**Why it happens:**
Armor formula `armor/(armor+K)` has diminishing returns by design (Path of Exile's asymmetric scaling). This is intentional for positive armor (prevents infinite stacking) but creates problems for negative armor. As noted in damage formula research: "If defense is decreased by X%, damage taken increases by X%, but if defense is increased by X%, damage reduction is not X%." Developers apply one formula to both positive and negative ranges without realizing the asymmetry.

**How to avoid:**
1. **Use separate formula for negative armor**: Positive: `DR = armor/(armor+K)`, Negative: `DR = armor/K` (linear penalty, not hyperbolic)
2. **Cap negative armor effect at -50% DR** to prevent death spirals
3. **Test symmetry**: If +50 armor reduces damage by X%, -50 armor should increase damage by ~X% (not 3X%)
4. **Consider additive debuffs**: Instead of modifying armor stat, apply separate "vulnerability" multiplier to final damage
5. **Use Path of Exile's approach**: Negative armor below zero uses different constant (divide by 5 at minimum)

**Warning signs:**
- Small armor debuffs feel catastrophically punishing
- Enemies with armor reduction abilities become "must avoid"
- Defensive builds feel mandatory (can't survive without high armor)
- Death from full health in <1 second against debuff enemies
- Players complain "armor doesn't matter, I die anyway"
- Testing shows -100 armor = 500% damage taken (unreasonably high)

**Phase to address:**
Phase 1 (defensive prefix foundation) — when armor calculation is implemented, document and test negative armor separately. Flag for Phase 6+ when monster debuffs are added.

---

### Pitfall 8: Integer Overflow in Damage Calculations

**What goes wrong:**
Endgame hero has 10,000 DPS. Pack has 5 monsters. Fight lasts 15 seconds. Total damage = 10,000 × 15 = 150,000. Godot GDScript uses 64-bit ints by default but intermediate calculations can overflow if mixing int/float incorrectly. Or worse: damage formula does `int(base_damage) * int(crit_multiplier) * int(speed)` and intermediate result exceeds 2^31, wraps to negative, hero deals -50,000 damage and heals the enemy.

**Why it happens:**
GDScript's loose typing allows mixing int and float without explicit casts. StatCalculator uses `float` for DPS but combat might convert to `int` for display. As documented in Final Fantasy VII damage overflow: "Final damage overflowed by going beyond 2^31 - 1 at an earlier stage of computation." Developers don't anticipate extreme values during endgame optimization.

**How to avoid:**
1. **Use float for ALL damage calculations**: Never cast to int until final display
2. **Clamp results before type conversion**: `int(clamp(damage, 0, 999999))` for display
3. **Add overflow test cases**: Test with DPS=999999, verify damage doesn't wrap negative
4. **Use `INF` constant checks**: `if damage >= INF or is_nan(damage): damage = 0`
5. **Log suspect values**: Print warning if damage > 1,000,000 (indicates possible overflow)
6. **Prefer multiplication order**: `(damage * multiplier) * time` safer than `damage * (multiplier * time)` due to intermediate precision

**Warning signs:**
- Damage numbers suddenly become negative
- High DPS builds deal less damage than low DPS
- Combat log shows wildly inconsistent damage values
- Hero one-shots self on crit
- Damage value displays as negative in UI
- Large numbers render as "1.234e+6" (scientific notation in UI)

**Phase to address:**
Phase 2 (pack-based combat) and Phase 4 (combat pacing) — when damage application is implemented, enforce float types and add overflow tests.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skipping resistance caps in v1.2, adding later | Faster combat implementation | Invincibility builds discovered post-launch, requires retroactive rebalancing | Never — caps are 3 lines of code |
| Using time.sleep() instead of proper async combat | Simple combat loop implementation | Freezes UI, can't cancel combat, breaks on slow devices | Never — Godot has Timer nodes and yield |
| Hardcoding pack HP values per area | Avoid complex scaling formula | Rebalancing requires editing 300 lines, impossible to tune progression curve | Acceptable for prototyping only |
| Sharing LootTable between combat and crafting without versioning | Don't duplicate code | Breaking change to combat breaks crafting, regression bugs | Acceptable if integration tests exist |
| Storing combat state in UI layer (gameplay_view) instead of GameState | Avoids refactoring GameState autoload | Can't save/load during combat, state lost on scene change, testing requires UI | Never — combat is game logic, not view logic |
| Allowing equipment changes during combat | Simpler state management | Race conditions, stat snapshot bugs, exploit potential | Never — lock equipment with `is_clearing` flag |
| Using global `randf()` without seed control | Default randomness works | Drop testing irreproducible, balancing requires manual playtesting | Acceptable for v1.2, add seed control in v1.3+ |
| Linear pack HP scaling (HP = area * 100) | Easy to implement | Early areas trivial, late areas impossible, no difficulty curve | Acceptable for proof-of-concept only |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| StatCalculator → Combat | Calling calculate_dps() every frame during combat | Snapshot stats at combat start, reuse for duration |
| GameState → Gameplay View | Reading hero.total_dps directly in _process() | Cache value, update only on equipment_changed signal |
| LootTable → Currency Drops | Calling roll_currency_drops() per monster instead of per pack | Call once per pack, multiply by pack size if needed |
| Hero → Death Mechanics | Setting is_alive=false and assuming everything stops | Emit hero_died signal, let systems respond (stop combat, show UI) |
| Combat Loop → Timer | Using `await get_tree().create_timer()` without cancellation | Store Timer reference, call stop() on combat end |
| Damage Calculation → Resistance | Applying resistance after armor in damage chain | Apply in parallel: armor reduces physical, resistance reduces elemental, sum final reductions |
| Pack HP → Area Scaling | Forgetting that DPS also scales with area (better gear drops) | Pack HP scaling must outpace DPS scaling or combat becomes trivial |
| Drop Split → Existing Crafting | Modifying roll_rarity() to require area_level param | Add new methods, keep old signatures for backward compatibility |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Recalculating hero stats every frame | FPS drops during combat, fan noise | Calculate once on equip_item(), cache result, update on change only | 60 FPS → 30 FPS with 5 items equipped |
| Creating new Timer nodes per pack without cleanup | Memory leak, game slows after 100 packs | Reuse single Timer, or use Queue.free() after combat | Game crashes after ~1000 area clears |
| Storing entire combat log in memory | Expanding memory usage over time | Circular buffer (last 100 entries) or clear on area change | 100MB+ memory usage after 1 hour |
| Using String concatenation in combat loop | GC pressure, stuttering | Use PackedStringArray or StringBuilder pattern | Micro-stutters every 5 seconds |
| Emitting signals with complex objects per damage tick | Signal bus congestion | Emit on pack_cleared, not per hit | Noticeable lag with 20+ monsters per pack |
| Calling update_stats() on every affix change during crafting | Crafting feels sluggish | Batch updates: set `_suppress_update=true`, modify all affixes, call update_stats() once | Crafting a 6-mod rare takes 2+ seconds |
| Deep copying Hero object for stat snapshots | Memory allocation per combat | Reference immutable stats snapshot class | Combat start delay noticeable (>200ms) |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No visual feedback during combat | Player can't tell if combat is happening | Add pulsing health bar, damage numbers, pack HP indicator |
| Combat starts instantly on button click | Accidental clicks waste time | Add 0.5s animation or "Starting combat..." state transition |
| Death has no consequence | No tension, combat feels meaningless | Lose area progress or pay currency to revive (idle games need stakes) |
| No way to cancel combat | Trapped in 2-minute fight after misclick | Add "Retreat" button with consequences (lose loot, take damage) |
| Resistance stats hidden until first elemental hit | Player doesn't know resistances matter | Show resistances in hero view with "0% → 75%" tooltips |
| Pack HP not visible | Can't gauge fight duration | Show HP bar or "5 monsters remaining" counter |
| Currency drops invisible during combat | Player ignores drops, doesn't understand rewards | Show "+5 Runic" floating text or post-combat summary |
| No indication of why hero died | Frustrating, feels unfair | Combat log showing "Took 50 fire damage (0% resistance)" |
| Combat speed feels wrong but no setting | Player abandons game | Add 1x/2x/4x speed toggle in settings |
| Area difficulty not visible before starting | Player enters impossible area, wastes time | Show recommended DPS or "Area 50 (Hard)" indicator |

## "Looks Done But Isn't" Checklist

- [ ] **Combat System:** Often missing cancellation logic — verify clicking area transition mid-combat doesn't break state
- [ ] **Damage Reduction:** Often missing negative armor handling — verify debuffs use separate formula or cap at -100%
- [ ] **Resistance Caps:** Often missing upper bound enforcement — verify 200% resistance still = 90% DR
- [ ] **Drop Split:** Often missing backward compatibility — verify existing crafting/simulator still works after LootTable changes
- [ ] **Death Mechanics:** Often missing state cleanup — verify hero.is_clearing=false and timers stopped on death
- [ ] **Pack Scaling:** Often missing DPS normalization — verify Area 300 packs don't die in 0.1s with endgame gear
- [ ] **Combat Pacing:** Often missing underpowered testing — verify combat possible (not pleasant) with white items
- [ ] **State Locking:** Often missing re-entry prevention — verify can't start combat twice by double-clicking
- [ ] **Stat Snapshots:** Often missing race condition prevention — verify unequipping weapon mid-combat doesn't crash
- [ ] **UI Feedback:** Often missing "combat in progress" indicators — verify player knows combat is happening
- [ ] **Currency Normalization:** Often missing economy rebalance verification — verify currency/hour matches v1.1 baseline
- [ ] **Overflow Protection:** Often missing extreme value testing — verify 999,999 DPS doesn't cause negative damage

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Progression curve broken (too fast/slow) | MEDIUM | Run drop simulator with 1000 trials per area tier, compare to v1.1 baseline, adjust LootTable multipliers, re-verify |
| Invincibility builds discovered | LOW | Add resistance caps to calculate_defense(), no save file migration needed (caps apply on next stat recalc) |
| Combat pacing wrong (too fast/slow) | MEDIUM | Add HP_SCALE_MULTIPLIER constant to pack generation, tune via testing, update global constant |
| Race condition crashes during combat | HIGH | Refactor to state machine, add equipment locking, requires architectural change + regression testing |
| Death mechanics don't clean up state | MEDIUM | Add death handler that emits signal, subscribe all systems, verify cleanup in each subscriber |
| Drop split broke existing features | HIGH | Revert LootTable changes, create new classes for combat drops, migrate callers incrementally |
| Negative armor creates death spiral | LOW | Add clamping to armor formula, test with negative values, adjust constants if needed |
| Integer overflow in damage | LOW | Change all damage vars from `var damage: int` to `var damage: float`, add clamp before display |
| No combat cancellation | MEDIUM | Store Timer reference, add cancel button, handle early exit (no drops, restore state) |
| Resistance stacking too powerful | LOW | Add diminishing returns formula (Diablo 4 style) or hard caps (PoE style), retune expected values |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Armor formula division by zero | Phase 1: Defensive Prefix Foundation | Test suite with armor=0, armor=-1000, resistance=150%, verify DR capped at 90% |
| Progression curve disruption | Phase 3: Drop Split + Phase 4: Pacing | Compare v1.1 vs v1.2 currency/hour via simulator, ±20% tolerance |
| Combat pacing mismatch | Phase 4: Combat Pacing | Playtest with beginner/mid/endgame gear, verify 5-15s TTK per pack |
| State management race conditions | Phase 2: Pack-Based Combat | Try unequipping items during combat, verify graceful handling or prevention |
| Resistance cap bypass | Phase 1: Defensive Prefix Foundation | Create test hero with 200% resistance, verify damage reduction = 90% |
| Drop split breaking LootTable | Phase 3: Drop Split | Run existing drop_simulator and crafting flows, verify no regressions |
| Negative armor amplification | Phase 1: Defensive Prefix Foundation | Test with armor=-100, verify damage increase reasonable (<200%) |
| Integer overflow | Phase 2: Pack-Based Combat | Test with DPS=999999, verify no negative damage or NaN |

## Domain-Specific Warnings

### When Adding Pack-Based Combat to Time-Based Game

**Pack HP Tuning is Non-Linear:**
Don't use `pack_hp = area_level * constant`. Hero DPS scales exponentially via gear (Area 1 weapon = 10 DPS, Area 100 weapon = 500 DPS due to better implicits + affixes + tiers). Pack HP must scale faster than DPS to maintain challenge. Use logarithmic curves: `pack_hp = BASE_HP * log(area_level + 1) * SCALE_FACTOR`. Path of Exile 2 uses `Armour/(Armour + 12 * Damage)` which inherently has diminishing returns.

**Drop Rate Testing Requires Both Statistical AND Playtest Validation:**
Drop simulator shows "60 Runic per hour" but doesn't account for human behavior (AFK time, interruptions). Idle games need 80% passive efficiency (player checks every 15 min) and 100% active efficiency (player present). Test both: 1) Run simulator for statistical baseline, 2) Playtest with actual timer to verify feel.

**Damage Types Must Be Balanced Simultaneously:**
Can't balance physical damage then add elemental later. If armor reduces physical by 50% but fire resistance is 0%, fire becomes meta. All damage types and mitigation must ship together or create tier lists. Either launch v1.2 with physical-only (defer elemental), OR implement all types in Phase 1 (preferred).

### When Integrating StatCalculator with Combat

StatCalculator currently handles **offense** (DPS calculation with proper order of operations). Combat adds **defense** (damage reduction). These must compose correctly:

```
Incoming Damage = Enemy Base Damage
→ Apply armor reduction (physical)
→ Apply resistance reduction (elemental)
→ Apply evasion check (RNG miss)
→ Apply energy shield absorption (soak before health)
→ Final damage to health
```

**Pitfall:** Applying reductions in wrong order changes effective survivability exponentially. Test composition explicitly.

### When Replacing Core Gameplay Loop

v1.0-v1.1 established player expectations: "I craft items to progress." v1.2 changes to "I clear packs to get currency to craft items." This is **additive** (combat unlocks crafting) not **replacement** (combat instead of crafting). Pitfall: If combat feels mandatory, crafting becomes chore. If crafting feels mandatory, combat is just a currency grind.

**Prevention:** Combat should feel optional for pure crafters (can buy/find items), crafting should feel optional for pure fighters (can find good drops). Both paths should work, combination should be optimal.

## Sources

**ARPG Damage Formulas:**
- [Path of Exile 2 Armour Formula](https://mobalytics.gg/poe-2/guides/armour) - Armour/(Armour+12*Damage), 90% cap
- [Path of Exile Wiki: Damage Reduction](https://www.poewiki.net/wiki/Damage_reduction) - 90% max, -200% min caps
- [Diablo 4 Armor and Resistances](https://www.thegamer.com/diablo-4-how-armor-and-resistances-work/) - Diminishing returns via multiplication
- [Melvor Idle Damage Reduction](https://wiki.melvoridle.com/w/Damage_Reduction) - Additive damage reduction example

**Damage Formula Edge Cases:**
- [Last Epoch Forum: Negative Armor](https://forum.lastepoch.com/t/negative-armor-formula/26045) - Singular behavior between -700 and -500
- [The Simplest Non-Problematic Damage Formula](https://tung.github.io/posts/simplest-non-problematic-damage-formula/) - Special-casing extremes is norm
- [Armor Formula Edge Cases](https://forum.albiononline.com/index.php/Thread/101286-What-is-the-formula-for-Armor-Damage-reduction/) - Asymmetric scaling issues
- [WoW Damage Reduction Formula](https://wowpedia.fandom.com/wiki/Damage_reduction) - armor/(armor+K) with different constants

**Idle Game Pacing:**
- [Idle Game Pacing Problems](https://steamcommunity.com/app/992070/discussions/0/2997674076186864255/) - "2-3 minutes to kill one enemy"
- [How to Design Idle Games](https://machinations.io/articles/idle-games-and-how-to-design-them/) - Simple core loop, complex meta loop
- [Balancing Tips: Idle Idol](https://www.gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol) - Math management patterns
- [The Math of Idle Games Part III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii) - Progression curve design

**Incremental Game Economy:**
- [Designing Game Economies](https://medium.com/@msahinn21/designing-game-economies-inflation-resource-management-and-balance-fa1e6c894670) - Faucets, sinks, inflation
- [I Designed Economies for $150M Games](https://www.gamedeveloper.com/production/i-designed-economies-for-150m-games-here-s-my-ultimate-handbook) - Professional economy design
- [Game Economy Inflation](https://machinations.io/articles/what-is-game-economy-inflation-how-to-foresee-it-and-how-to-overcome-it-in-your-game-design) - Balancing production and consumption

**Godot State Management:**
- [Godot Autoload Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html) - When to use autoloads
- [Godot Singletons](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) - Official autoload documentation
- [Unity Game State Management](https://docs.unity.com/ugs/en-us/manual/cloud-code/manual/game-state-management) - Server-side state patterns

**ARPG UI and Combat Feedback:**
- [Path of Exile: Visual Clarity Issues](https://www.pathofexile.com/forum/view-thread/3898159) - Community feedback on combat clarity
- [Top ARPGs in 2026](https://www.tribality.com/articles/top-action-rpgs-arpgs-in-2026-the-best-isometric-loot-driven-games/) - Diablo IV's audiovisual feedback praised

**Integer Overflow:**
- [Final Fantasy VII Damage Overflow](https://finalfantasy.fandom.com/wiki/Damage_overflow_glitch_in_Final_Fantasy_VII) - Exceeding 2^31-1 in damage calculation

**Resistance Caps:**
- [PoE Wiki: Resistance](https://www.poewiki.net/wiki/Resistance) - 90% hard cap, -200% floor
- [Diablo Resistances](https://diablo.fandom.com/wiki/Resistances) - 75% default cap, 95% max

**Combat Rebalancing:**
- [Pantheon Spring 2026 Combat Update](https://www.pantheonmmo.com/news/spring-2026-combat-and-progression-update/) - TTK increases, sustainability focus

---

*Pitfalls research for: Pack-based idle ARPG combat system integration*
*Researched: 2026-02-16*
*Primary risk areas: Damage formula edge cases, progression curve preservation, combat pacing for idle gameplay, state management during async combat*
