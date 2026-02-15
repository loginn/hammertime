# Pitfalls Research

**Domain:** ARPG Crafting System Expansion - Defensive Prefixes, Expanded Affixes, Currency Area Gating
**Researched:** 2026-02-15
**Confidence:** HIGH (code analysis) / MEDIUM (WebSearch-verified patterns)

## Critical Pitfalls

### Pitfall 1: Tag Filter Explosion Creates Empty Affix Pools

**What goes wrong:**
Adding defensive prefixes with ARMOR/HELMET/BOOTS tags causes weapons to get empty affix pools when rolling prefixes, because all 9 existing prefixes have the WEAPON tag. Items fail to craft, currency is wasted, and players encounter "No valid prefixes available" errors on weapons even though the global prefix pool contains 15+ affixes.

**Why it happens:**
The current system uses intersection-based tag filtering: `has_valid_tag()` checks if ANY item tag matches ANY affix tag. When you add defensive prefixes tagged [ARMOR] to a pool currently containing only [WEAPON]-tagged prefixes, weapons (tagged [WEAPON]) can no longer roll the new defensive prefixes, and armor (tagged [ARMOR, DEFENSE]) can no longer roll weapon prefixes. The pool appears expanded globally, but contracted per-item-type.

**How to avoid:**
- Define mutually exclusive tag groups BEFORE adding affixes: WEAPON_ONLY, ARMOR_ONLY, HELMET_ONLY, BOOTS_ONLY, ANY_ITEM
- Test affix pool filtering for EACH item type after adding new affixes
- Use union tags for cross-item affixes (e.g., "Life" suffix should have [DEFENSE, ANY_ITEM] not just [DEFENSE])
- Verify pool size: `print("Valid prefixes for %s: %d" % [item.item_name, valid_prefixes.size()])` in `add_prefix()`

**Warning signs:**
- "No valid prefixes available" console spam
- Items that could previously craft now failing silently
- Drastically different affix pool sizes between item types (weapon has 3 options, armor has 12)
- Reduced mod count on rare drops (expecting 4-6 mods, getting 2-3)

**Phase to address:**
Phase 1 (Defensive Prefix Foundation) - Tag taxonomy MUST be established before first defensive affix is added

---

### Pitfall 2: StatType Enum Expansion Breaks StatCalculator Switch Statements

**What goes wrong:**
Adding PERCENTAGE_ARMOR, INCREASED_ARMOR, FLAT_PHYSICAL_REDUCTION to Tag.StatType enum causes defensive items to display incorrect stat values or crash with "unhandled enum" errors. Existing `calculate_flat_stat()` works, but any future percentage-based defensive calculations fail because the calculator doesn't handle the new enum values.

**Why it happens:**
GDScript enums are integer-based and backwards compatible for existing values, but code that switches/matches on enum values or uses `in` checks must explicitly handle new values. Current `StatCalculator.calculate_flat_stat()` uses generic array membership (`if stat_type in affix.stat_types`), which works. But if you add percentage defensive stats later and create `calculate_percentage_armor()` using a match statement, forgetting cases causes runtime errors.

**How to avoid:**
- Add enum values at the END of the enum (preserves integer mapping: FLAT_DAMAGE=0, INCREASED_DAMAGE=1, etc.)
- Use pattern matching with wildcard fallback: `match stat_type: ... _: push_warning("Unhandled StatType: %s" % stat_type)`
- Extend StatCalculator with new functions BEFORE adding stat types to affixes (function exists → enum added → affixes use it)
- Grep for existing enum usage: `rg "StatType\." --type gd` to find all switch/match locations

**Warning signs:**
- "Invalid get index 'X' on base 'Array'" errors when calculating stats
- Items showing 0 for new defensive stats despite having affixes
- Console warnings "Unhandled enum value" during `update_value()`
- Defensive stats not updating when rerolling affixes

**Phase to address:**
Phase 1 (Defensive Prefix Foundation) - Add StatType enum values + StatCalculator functions TOGETHER in same task

---

### Pitfall 3: Area-Gated Currency Drops Break Independent Probability Model

**What goes wrong:**
Implementing area-gating by modifying `roll_currency_drops()` to return empty dictionaries for locked currencies (e.g., `if area_level < 2: drops.pop("forge")`) destroys the area bonus distribution logic. The line `var dropped_currencies = drops.keys()` now has fewer currencies, concentrating all bonus drops into unlocked currencies and creating an exponential reward curve instead of linear.

Area 1: 100% of bonus drops go to runic (only unlocked currency)
Area 2: 50% bonus split between runic + forge
Area 4: bonus evenly distributed across all 6 currencies

This makes early-game hammers drop at 3-4x intended rate, trivializing progression.

**Why it happens:**
The current bonus system `for i in range(area_level - 1): drops[random_currency] += 1` assumes all currencies are eligible. Area-gating reduces the eligible pool, but the bonus drop COUNT stays the same (`area_level - 1`), concentrating drops. Independent probability checks (`if randf() < rule["chance"]`) work correctly, but the post-roll bonus distribution creates the explosion.

**How to avoid:**
- Gate currency visibility SEPARATE from drop logic: currency always rolls, UI shows "???" for locked types
- OR: Adjust bonus drops by unlocked currency count: `bonus_drops = (area_level - 1) * unlocked_currencies.size() / 6.0`
- OR: Gate at crafting consumption (currency drops, but can't be used until area X unlocked)
- Verify drop rates with simulation: "After 100 clears of area 1, expected X runic, got Y" test

**Warning signs:**
- Player inventory has 200 runic hammers at area 1 (expected: ~30-40)
- Later areas feel LESS rewarding than earlier areas (bonus dilution)
- Exponential currency growth in early game, then plateau
- Crafting progression too fast (skip entire area tiers)

**Phase to address:**
Phase 2 (Currency Area Gating) - Design gating mechanism BEFORE modifying roll logic; requires simulation testing

---

### Pitfall 4: Display-Only Defensive Stats Create Player Confusion About Item Value

**What goes wrong:**
Adding armor/ES/health stats to items that display prominently (`output += "armor: %d\n" % self.base_armor`) but don't affect combat creates cognitive dissonance. Players optimize for high armor values, equip defensive items over offensive items, then die in combat because armor does nothing. Items show "total_defense: 500" but character defensiveness is identical to total_defense: 0.

**Why it happens:**
The milestone deliberately separates stat display (Phase 1) from combat integration (later milestone). This is technically sound for incremental development, but psychologically misleading. Players assume displayed stats matter. The UI provides no indication that armor is "cosmetic until v2.0."

**How to avoid:**
- Add visual indicator: `output += "armor: %d (not yet functional)\n"` during display-only phase
- OR: Hide defensive stats from UI until combat integration milestone begins
- OR: Add tooltip on hover: "Defensive stats will affect combat in the next major update"
- Gray out defensive stat text (Color.GRAY for non-functional stats)
- Playtest with external users (internal testers know stats are fake, real players don't)

**Warning signs:**
- Playtesters equip low-DPS items with high armor, then complain combat is too hard
- Forum posts: "Why doesn't armor do anything?"
- Players selling high-DPS weapons to buy high-armor gear
- Confusion in UAT: "I have 300 armor, why am I taking full damage?"

**Phase to address:**
Phase 1 (Defensive Prefix Foundation) - Add UI disclaimer when displaying non-functional stats; remove in combat integration milestone

---

### Pitfall 5: Affix Pool Dilution Makes Target Mods Uncraftable

**What goes wrong:**
Adding 12 defensive prefixes to the existing 9 weapon prefixes creates a 21-affix prefix pool. Probability of rolling a specific weapon prefix drops from 1/9 (11%) to 1/9 (still 11% for weapons due to tag filtering), BUT probability of rolling a specific defensive armor prefix on armor drops from "guaranteed one of 3 options" to 1/12 (8.3%) because 9 weapon prefixes are filtered out. This isn't dilution for weapons (tag filtering protects them), but massive dilution for defensive items if they previously had implicit-only stats or very few prefix options.

More critically: if you add hybrid prefixes that apply to BOTH weapons and armor (e.g., "%Physical Damage and Armor"), the pool dilutes for BOTH item types.

**Why it happens:**
Tag-filtered affix pools protect against cross-category dilution (weapons can't roll armor mods), but NOT against within-category dilution (more armor mods = harder to hit specific armor mod) or hybrid-category dilution (shared mods increase pool size for both). Path of Exile 2 currently suffers from this (PoE1 had duplicate protection, PoE2 does not), where crafting can overwrite good mods with duplicates or undesired mods from a bloated pool.

**How to avoid:**
- Count affixes per tag category BEFORE adding new affixes: "Armor currently has 4 prefix options, adding 8 more = 3x harder to target craft"
- Design targeted crafting currencies for later (e.g., "Armorer's Hammer" that only rolls armor-tagged prefixes)
- Avoid hybrid affixes in early milestones (complexity explosion)
- Implement duplicate affix blocking: `is_affix_on_item()` already exists, extend it to pool filtering

**Warning signs:**
- Player feedback: "I've used 50 runic hammers and still haven't hit the mod I want"
- Crafting feels like pure RNG gambling instead of deterministic progression
- Rare items frequently have 6 mods but none are useful for the build
- Currency consumption rate skyrockets after affix expansion

**Phase to address:**
Phase 1 (Defensive Prefix Foundation) - Document affix pool sizes per item type; flag if pool >15 affixes per category
Phase 3 (Expanded Suffix Types) - Audit combined prefix+suffix pools before adding utility suffixes

---

### Pitfall 6: Rebalancing Drop Rates Without Anchored Reference Points

**What goes wrong:**
Tweaking `RARITY_WEIGHTS` or currency drop chances to "feel better" without recording baseline metrics causes directionless iteration. You change area 1 from `{NORMAL: 80, MAGIC: 18, RARE: 2}` to `{NORMAL: 70, MAGIC: 25, RARE: 5}`, playtest, "feels too rewarding," revert to `{NORMAL: 75, MAGIC: 20, RARE: 5}`, playtest again, forget what original ratios were, end up with `{NORMAL: 82, MAGIC: 15, RARE: 3}` which is worse than baseline but you can't remember why you changed it.

**Why it happens:**
Drop rate tuning is perceptual, not analytical. "Too grindy" and "too easy" are subjective feelings that change based on playtime, mood, and comparison to other games. Without quantitative anchors (items per hour, crafts per area clear, time to first rare), you're tuning blindly.

**How to avoid:**
- Document CURRENT drop rates before any changes: "Area 1 baseline: 1.2 items/clear, 0.18 magic, 0.02 rare"
- Define target metrics: "Goal: 1 rare item per 30 clears in area 1" (not "more rare items")
- Use simulation for large-scale testing: run 1000 clears, record distribution, compare to target
- A/B test with version control: commit before changes, tag as `v1.0-drop-baseline`, branch for experiments
- Playtest logs: record timestamp, area, items dropped, currency gained (data > feelings)

**Warning signs:**
- Multiple revisions to same drop table in short timespan (3+ commits in one day)
- Commit messages: "adjust drop rates again" "try different weights" "revert drop changes"
- No numerical justification in change descriptions
- Playtester feedback contradicts your perception ("I think it's balanced" vs "way too grindy")

**Phase to address:**
Phase 4 (Drop Rate Rebalancing) - Create simulation script FIRST, establish baseline metrics, THEN adjust

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Adding defensive stats to items without combat integration | Ship visible feature early, defer complex combat math | Player confusion, balancing stats twice (display values vs combat values may diverge) | ACCEPTABLE if UI clearly indicates non-functional state |
| Using string-based currency names in `roll_currency_drops()` instead of enum | Faster implementation, readable dictionaries | Typo bugs ("runnic" vs "runic"), harder refactoring if currency system changes | ACCEPTABLE for single milestone, MUST refactor to enum before currency expansion |
| Hardcoding area unlock thresholds (`if area_level < 2`) instead of configuration | Simpler code, no data files needed | Requires code changes to adjust progression, can't A/B test thresholds | Never acceptable - use const Dictionary or JSON config |
| Skipping affix pool size validation on item types | Saves test writing time | Silent crafting failures when pools empty, hard-to-diagnose bugs | Never acceptable - validation is 5 lines of code |
| Copy-pasting `update_value()` logic across Armor/Helmet/Boots instead of shared base class method | Faster initial implementation | Divergent stat calculation logic, 3x maintenance burden for fixes | ACCEPTABLE in prototype, MUST refactor to inheritance before adding percentage-based defensive stats |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| StatCalculator + new StatType enums | Adding enum value, forgetting to extend calculator, affixes silently ignored | Add StatType enum + calculator function + test in single commit; grep for existing enum usage first |
| Tag filtering + new affix types | Assuming global pool expansion = per-item pool expansion | Test `valid_prefixes.size()` for EACH item type after adding affixes; use ANY_ITEM tag for universal affixes |
| LootTable area scaling + currency gating | Assuming independent probability checks remain independent after gating | Separate gating mechanism from probability checks; simulate drop distribution before committing |
| Item.update_value() + UI display | Calling `update_value()` but forgetting to call `get_display_text()`, stats updated in memory but not shown | Wire `update_value()` → signal emission → UI refresh; never rely on manual refresh |
| Affix.stat_types array + multiple StatType values | Single affix trying to affect multiple stat types, only first value processed | Use array correctly: `for stat_type in affix.stat_types` already works, but calculator must handle all types |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| O(n²) affix pool filtering on EVERY craft | Lag spike when using currencies, framerate drops in crafting view | Cache `valid_prefixes` array per item type on item creation, not on every `add_prefix()` call | Affix pool >50 total affixes, crafting >10 items/second |
| Recalculating DPS on every affix reroll in tight loop | Tuning Hammer (reroll all affixes) causes 6x DPS recalc, each recalc iterates all affixes | Batch `update_value()` calls: reroll all affixes THEN recalc once, not recalc after each reroll | Items with >6 affixes, Tuning Hammer spam |
| `LootTable.roll_currency_drops()` allocating new Dictionary on every area clear | Garbage collection spikes every 10 seconds (area clear rate) | Reuse currency drop dictionary, clear and repopulate instead of `var drops = {}` | Area clear rate >5/second (idle game automation) |
| String concatenation in `get_display_text()` for items with many affixes | Long tooltip delays, UI stuttering when hovering items | Use `PackedStringArray` + `"".join()` for multi-line strings instead of `+=` | Items with >8 affixes, rapid tooltip updates |

Note: Current project scale (4 areas, 6 currencies, 24 affixes) unlikely to hit performance traps. Include prevention now to avoid refactoring later.

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No visual distinction between functional and cosmetic stats | Players optimize for non-functional stats, frustration when build doesn't work | Color-code stats: white=functional, gray=coming soon; tooltip explains |
| Area-locked currencies shown as "0" instead of hidden/locked | Players don't know locked currencies exist, miss progression goals | Show "???" for locked currencies with "Unlocks at Area X" tooltip |
| Drop rate changes feel arbitrary | Player progression expectations violated, "game got nerfed" perception | Communicate in UI: "Area 2 unlocked: better drop rates!" (not silent buff) |
| Defensive item value unclear without combat integration | Players don't know if 100 armor is good or bad, can't evaluate items | Provide reference: "100 armor = reduces damage by ~15% (coming soon)" |
| Too many affix types too fast | Analysis paralysis, can't decide which affixes to target | Introduce 3-5 affixes per milestone, not 12 at once; tutorial highlights new affixes |
| Currency area gating feels like artificial restriction | "Why can't I use forge hammers in area 1?" frustration | Narrative justification: "Forge Hammers found in Volcanic Wastes (Area 2+)" |

## "Looks Done But Isn't" Checklist

- [ ] **Defensive Prefixes:** All 3 defensive item types (Armor, Helmet, Boots) tested with new prefixes — verify pool not empty
- [ ] **Defensive Prefixes:** Weapons still craftable after adding armor-tagged prefixes — verify tag filtering didn't break existing items
- [ ] **StatType Expansion:** Every new enum value has corresponding StatCalculator function — verify no "unhandled type" warnings
- [ ] **StatType Expansion:** Affixes using new stat types display correct values — verify not showing 0 or NaN
- [ ] **Currency Area Gating:** Drop rates tested at ALL area levels, not just unlocked/locked boundary — verify exponential bonus explosion doesn't occur
- [ ] **Currency Area Gating:** UI shows locked currencies as unavailable, not hidden — verify player knows progression exists
- [ ] **Drop Rate Rebalancing:** Baseline metrics recorded before changes — verify you can revert to known-good state
- [ ] **Drop Rate Rebalancing:** Target metrics defined (items/hour, crafts/rare) — verify changes measured against goals, not feelings
- [ ] **Affix Pool Expansion:** Affix pool sizes documented per item type — verify no category has >20 affixes without targeted crafting
- [ ] **UI Display:** Non-functional stats marked as "(coming soon)" or grayed out — verify players don't mistake for active mechanics
- [ ] **Integration:** `update_value()` called after EVERY affix modification (add, reroll, remove) — verify stats refresh correctly
- [ ] **Integration:** Tag taxonomy defined BEFORE affixes added — verify no "any item" vs "specific item" ambiguity

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Empty affix pool for item type | LOW | Add union tags (WEAPON, ANY_ITEM) to universal affixes; verify with `valid_prefixes.size()` print |
| StatType enum expanded but calculator not updated | LOW | Add calculator function, grep for enum usage, add match cases with wildcard fallback |
| Area bonus drops concentrated in early currencies | MEDIUM | Revert currency gating commit, redesign gating as UI-only or consumption-gating, re-test with simulation |
| Players optimized for non-functional stats | MEDIUM | Add UI disclaimer immediately, publish dev update explaining, offer free respec when combat integration ships |
| Affix pool dilution makes target crafting impossible | HIGH | Introduce targeted currency types (Armorer's Hammer, Weaponsmith's Hammer), OR reduce affix pool size by removing underused affixes |
| Drop rates rebalanced into unrecoverable state | MEDIUM | Git revert to tagged baseline, re-tune with simulation data, use A/B testing branch instead of main |
| Defensive item stat calculation diverged across Armor/Helmet/Boots | MEDIUM | Refactor to shared base class `DefensiveItem`, move `update_value()` to base, test all 3 item types, fix discrepancies |
| Duplicate defensive affixes on same item (no duplicate protection) | LOW | Extend `is_affix_on_item()` check to pool filtering in `add_prefix()`/`add_suffix()`, already 80% implemented |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Tag Filter Explosion | Phase 1: Defensive Prefix Foundation | Print `valid_prefixes.size()` for weapon/armor/helmet/boots; all >0 |
| StatType Enum Breaking Calculator | Phase 1: Defensive Prefix Foundation | Grep `StatType\.` usage; add test cases for new enums |
| Area Bonus Drop Concentration | Phase 2: Currency Area Gating | Simulate 100 clears each area level; verify linear not exponential |
| Display-Only Stat Confusion | Phase 1: Defensive Prefix Foundation | Add "(not yet functional)" to stat display; UAT with external testers |
| Affix Pool Dilution | Phase 3: Expanded Suffix Types | Document affix counts per tag; warn if >15 affixes per category |
| Drop Rate Baseline Loss | Phase 4: Drop Rate Rebalancing | Git tag current rates before changes; record metrics in spreadsheet |
| Duplicate Affixes | Phase 1: Defensive Prefix Foundation | Test ForgeHammer on rare items; verify no duplicate names |
| Non-Linear Progression Curve | Phase 4: Drop Rate Rebalancing | Plot "time to rare item" across all 4 areas; verify smooth curve |

## Sources

**Code Analysis:**
- /var/home/travelboi/Programming/hammertime/models/affixes/affix.gd (affix structure, stat_types array)
- /var/home/travelboi/Programming/hammertime/autoloads/item_affixes.gd (current prefix/suffix pools, tag filtering)
- /var/home/travelboi/Programming/hammertime/models/stats/stat_calculator.gd (stat calculation patterns, enum usage)
- /var/home/travelboi/Programming/hammertime/models/loot/loot_table.gd (area scaling, currency drop logic, bonus distribution)
- /var/home/travelboi/Programming/hammertime/models/items/item.gd (tag filtering via `has_valid_tag()`, affix pool filtering)

**ARPG Design Patterns (MEDIUM confidence - WebSearch verified):**
- [Path of Exile 2 affix pool dilution discussion](https://www.pathofexile.com/forum/view-thread/3659293) - Hybrid mod affix pool mess
- [PoE2 duplicate affix issue](https://mobalytics.gg/poe-2/guides/item-modifiers) - Affix overwriting without duplicate protection
- [Borderlands 4 drop rate player response](https://gamerant.com/borderlands-4-loot-drop-rates-changes-holiday-why/) - Rebalancing without communication
- [Loot drop best practices](https://www.gamedeveloper.com/design/loot-drop-best-practices) - Quantitative anchor points for tuning
- [GDScript enum backwards compatibility](https://github.com/godotengine/godot/pull/69590) - Enum expansion patterns

**Game Design Principles (LOW confidence - general WebSearch, not domain-specific):**
- [Combat Design for stats](https://gamedesignskills.com/game-design/combat-design/) - Display vs functional stats
- [PoE Wiki drop rates](https://www.poewiki.net/wiki/Drop_rate) - Area-gated currency examples

---

*Pitfalls research for: Hammertime ARPG Crafting System Expansion*
*Researched: 2026-02-15*
