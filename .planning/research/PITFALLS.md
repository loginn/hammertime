# Pitfalls Research

**Domain:** Adding Item Rarity Tiers and Crafting Currencies to Existing ARPG
**Researched:** 2026-02-14
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Rarity State Without Affix Count Enforcement

**What goes wrong:**
The Item class has no `rarity` field, but `add_prefix()` and `add_suffix()` already enforce a hardcoded limit of 3 prefixes and 3 suffixes. When you add rarity tiers (Normal=0+0, Magic=1+1, Rare=3+3), items can violate rarity rules because the existing code allows any item to reach 3+3 mods regardless of intended rarity.

Example failure: A Normal item (should be 0+0) gets `add_prefix()` called and now has 1 prefix, making it invalid for Normal rarity but without any rarity field to track this state change.

**Why it happens:**
Developers add a `rarity` enum to Item class but forget that existing item generation in `gameplay_view.gd` (line 151-155) creates items via `LightSword.new()` with no rarity assignment, and existing crafting methods don't check rarity before modifying affix counts.

**How to avoid:**
1. Add `rarity` field to Item class with explicit initialization in all item type constructors
2. Refactor `add_prefix()` and `add_suffix()` to check rarity-based limits BEFORE checking hardcoded 3-affix limit
3. Add `can_add_prefix()` and `can_add_suffix()` validation methods that return bool + reason string
4. Make item generation always assign a rarity (even if just Normal by default)

**Warning signs:**
- Items display with mod counts that don't match their rarity color
- Currency usage succeeds but item becomes "invalid" (e.g., Magic item with 3 prefixes)
- "Cannot add more prefixes" message appears on Magic item with only 1 prefix
- Items created in `gameplay_view.gd` have `null` or undefined rarity

**Phase to address:**
Phase 1 (Rarity Foundation) - This MUST be addressed during the initial rarity implementation, not deferred. Existing code assumes all items can have 3+3, breaking this assumption requires careful refactoring of Item.gd lines 81-124.

---

### Pitfall 2: Currency Validation Without State Transition Rules

**What goes wrong:**
Currencies like Runic Hammer (Normal→Magic) and Forge Hammer (Normal→Rare) change item rarity, but the current affix system has no "remove affixes" logic. When a Runic Hammer converts Normal(0+0) to Magic, the item needs to gain 1-2 mods, but when a Claw Hammer removes a mod from a Magic(1+1) item, what happens? Does it become Normal(0+0)? The code has no downgrade transition logic.

Example failure:
- Magic item has 2 prefixes, 1 suffix
- Player uses Claw Hammer to remove 1 prefix
- Item now has 1 prefix, 1 suffix - still valid Magic
- Player uses Claw Hammer again to remove the suffix
- Item now has 1 prefix, 0 suffixes - INVALID Magic (requires at least 1 suffix)
- No logic exists to demote to Normal or prevent this invalid state

**Why it happens:**
Developers implement currency effects in isolation (Runic adds mods, Claw removes mods) without defining a state machine for valid rarity transitions. The assumption "just add/remove mods" ignores that rarity is state-dependent.

**How to avoid:**
1. Define explicit state transition rules:
   - Normal→Magic: Requires adding at least 1 mod
   - Magic→Normal: Requires removing all mods
   - Normal→Rare: Requires adding at least 2 mods
   - Magic→Rare: Can only happen via Forge Hammer, not by adding mods to Magic
   - Rare→Magic: NEVER allowed (prevent downgrade)
   - Rare→Normal: NEVER allowed
2. Implement `validate_rarity_transition(from_rarity, to_rarity, current_mods) -> Result` before applying currency
3. Claw Hammer should check: "Would this removal make the item invalid for its current rarity?" and either prevent it OR auto-demote rarity
4. Make "minimum mod count for rarity" a validation rule, not just a generation rule

**Warning signs:**
- Currency use succeeds but item displays wrong rarity color
- Items exist with Magic rarity but 0 mods
- Claw Hammer can remove the last mod from a Magic item
- No error message when invalid transition attempted
- Currency consumption happens even when transition fails

**Phase to address:**
Phase 2 (Currency System) - Must be designed BEFORE implementing individual currencies. The transition rules are the foundation; currencies are implementations of those rules.

---

### Pitfall 3: Hardcoded 3-Hammer System Not Fully Replaced

**What goes wrong:**
`crafting_view.gd` has deeply embedded 3-hammer logic:
- Line 19-23: `hammer_counts` dictionary with "implicit", "prefix", "suffix" keys
- Line 98-118: Button toggle logic checking these specific hammer types
- Line 134-143: Button text showing "(X remaining)" for these 3 types
- Line 141: `gameplay_view.give_hammer_rewards()` generates these 3 types

When adding 6 new currency types (Runic, Forge, Tack, Grand, Claw, Tuning), developers often:
1. Add new currencies to a separate `currency_inventory` dictionary
2. Keep old `hammer_counts` for backward compatibility
3. End up with TWO parallel systems that desync

Example failure:
- Old system awards "prefix hammers" via `give_hammer_rewards()`
- New system has "Tack Hammer" currency for adding prefix to Magic items
- Player has both "10 prefix hammers" AND "5 Tack Hammers"
- UI shows old buttons, new currencies never used
- OR: UI shows new currencies, old rewards never granted

**Why it happens:**
Fear of breaking existing functionality leads to "additive refactoring" instead of "replacement refactoring". The old system continues to function while the new system is bolted on, creating dual state management.

**How to avoid:**
1. REMOVE `hammer_counts` dictionary entirely, don't add to it
2. Replace with `currency_inventory` dictionary with 6 new currency types
3. Refactor `give_hammer_rewards()` in `gameplay_view.gd` to award new currencies based on area difficulty and rarity drop tables
4. Replace the 3 hammer buttons with 6 currency buttons (or dynamic button generation)
5. Search codebase for ALL references to "implicit", "prefix", "suffix" as dictionary keys and replace/remove
6. Add migration: On first load, convert any remaining old hammers to equivalent new currencies (1 prefix hammer = 1 Tack Hammer)

**Warning signs:**
- Both old and new hammer systems visible in UI
- `hammer_counts` and `currency_inventory` both exist
- Grep for "hammer_counts\[" returns results after migration
- Awards in gameplay still reference old hammer types
- Players report "I have hammers but can't use them" (wrong type for new system)

**Phase to address:**
Phase 2 (Currency System) - This is a breaking change that must be done atomically. Phase should include: remove old system → implement new system → migration path for existing saves (if any). Do NOT attempt gradual migration.

---

### Pitfall 4: UI State Desync Between Views via Direct Node References

**What goes wrong:**
`crafting_view.gd` and `gameplay_view.gd` communicate via direct node references:
- Line 34: `hero_view = get_node_or_null("../HeroView")`
- Line 194: `hero_view.set_last_crafted_item(finished_item)`
- `gameplay_view.gd` line 122: `crafting_view.set_new_item_base(item_base)`
- Line 141: `crafting_view.add_hammers(...)`

When adding currency UI and rarity indicators, state changes in one view don't automatically update the other:
- Player uses Runic Hammer in `crafting_view`, item rarity changes Normal→Magic
- `hero_view` still shows "Normal" because it cached the old state
- OR: Item drops in `gameplay_view` with rarity determined by area level
- `crafting_view` receives item but doesn't update rarity-dependent UI elements (available currencies)

**Why it happens:**
Direct method calls create tight coupling where each view must explicitly notify others of state changes. Godot signals exist but aren't used. When rarity introduces a new dimension of state, the notification graph explodes (rarity change must notify: hero_view for display, crafting_view for valid currencies, item_view for color, gameplay_view for drop eligibility).

**How to avoid:**
1. Implement centralized event bus pattern via autoload singleton:
   ```gdscript
   # EventBus.gd (autoload)
   signal item_rarity_changed(item: Item, old_rarity: String, new_rarity: String)
   signal currency_used(currency_type: String, item: Item)
   signal item_dropped(item: Item, area_level: int)
   ```
2. Views subscribe to events, not direct calls:
   ```gdscript
   # crafting_view.gd
   func _ready():
       EventBus.item_rarity_changed.connect(_on_item_rarity_changed)
   ```
3. State changes emit events instead of calling methods:
   ```gdscript
   # When using Runic Hammer
   EventBus.item_rarity_changed.emit(item, "Normal", "Magic")
   ```
4. Each view updates itself based on events it cares about

**Warning signs:**
- Item rarity shown differently in different UI panels
- Crafting an item doesn't update hero stats until scene reload
- Currency count updates in one view but not others
- `get_node_or_null()` failures when adding new view panels
- Print debugging shows correct state in one view, wrong state in another
- Race conditions where order of method calls matters

**Phase to address:**
Phase 1 (Rarity Foundation) - Introduce event bus BEFORE adding rarity, as adding rarity will require ALL views to react to rarity changes. Retrofitting event bus after rarity causes massive refactoring. Better to migrate existing hero/crafting communication to event bus first, THEN add rarity events.

---

### Pitfall 5: Affix Pool Exhaustion for Rarity Constraints

**What goes wrong:**
`item_affixes.gd` defines 9 prefixes and 21 suffixes, but they're filtered by `valid_tags` (item.gd line 74-78). Magic items can have max 1 prefix + 1 suffix. If an item type (e.g., Ring) has `valid_tags = [Tag.DEFENSE]` and only 2 prefixes match, then:

1. First Magic ring rolls 1 prefix → "Life" prefix added
2. Second Magic ring tries to roll 1 prefix → "Life" already added, only other valid prefix is "Armor"
3. Third Magic ring tries to roll 1 prefix → All 2 valid prefixes exhausted, `is_affix_on_item()` returns true for both
4. `valid_prefixes.is_empty()` returns true (line 94)
5. Magic item generates with 0 prefixes, violating Magic rarity rules

Current code (item.gd line 94-96) just prints "No valid prefixes available" and returns, leaving the item in an invalid state.

**Why it happens:**
The affix pool is global and shared, but filtering by tags + uniqueness constraint creates local scarcity. With Normal items (0 mods) and Rare items (3+3 mods), this rarely happens. With Magic items requiring exactly 1+1 or 2+2, the "one affix type per item" rule (line 62-72) makes it easy to hit "no valid affixes" even with a large global pool.

**How to avoid:**
1. Calculate minimum affix pool size needed per item type:
   - Count affixes matching each item's `valid_tags`
   - Ensure: `matching_prefixes >= max_prefixes_for_rarest_tier` (for Rare = 3)
   - Ensure: `matching_suffixes >= max_suffixes_for_rarest_tier` (for Rare = 3)
2. Add validation at game initialization:
   ```gdscript
   func validate_affix_pools():
       for item_type in [LightSword, BasicHelmet, ...]:
           var item = item_type.new()
           var valid_prefixes = count_valid_affixes(ItemAffixes.prefixes, item.valid_tags)
           assert(valid_prefixes >= 3, "Item type has insufficient prefix pool")
   ```
3. When affix pool exhausted, handle gracefully:
   - Option A: Allow duplicate affixes for Magic tier (remove uniqueness constraint)
   - Option B: Reduce mod count requirement (Magic can be 1+0 or 0+1 instead of requiring both)
   - Option C: Generate item at lower rarity (Magic → Normal if can't satisfy 1+1)
4. Add more affixes to pools that have low counts for specific tags

**Warning signs:**
- "No valid prefixes available" message appears frequently
- Magic items generated with 0 mods
- Specific item types (Rings, Boots) always fail to generate Magic+ rarity
- Grep for `valid_tags` shows item types with only 1-2 matching affixes
- Drop rates show Normal items far exceed expected rate (failed Magic generations falling back)

**Phase to address:**
Phase 3 (Drop System) - This must be validated BEFORE implementing rarity-based drops. If affix pools are insufficient, fixing it after players have items requires database migration. Run validation during Phase 1 to catch this early, but actual pool expansion can happen in Phase 3.

---

### Pitfall 6: No Rollback on Failed Currency Application

**What goes wrong:**
Current hammer system (crafting_view.gd lines 98-118) follows this pattern:
1. Check hammer count > 0
2. Apply effect (`add_prefix()`, `reroll_affix()`)
3. Decrement hammer count
4. Update display

But `add_prefix()` can fail (lines 94-96: "No valid prefixes available"). When adding currencies with complex rules:
- Runic Hammer (Normal→Magic): Needs to add 1-2 mods. What if first mod succeeds but second fails?
- Grand Hammer (add mod to Rare): What if Rare already has 3+3 mods? Or affix pool exhausted?
- Tuning Hammer (reroll values): What if reroll generates value outside valid range due to tier change?

Current code consumes the hammer (line 110, 117) BEFORE validating success. If `add_prefix()` fails, player loses the hammer but item is unchanged.

**Why it happens:**
The existing hammer system has simple, always-valid operations (reroll always works, add_prefix only fails in edge cases). New currencies have complex validation. Developers copy the existing pattern without adding validation or rollback.

**How to avoid:**
1. Implement validate-apply-commit pattern:
   ```gdscript
   func use_currency(currency_type: String, item: Item) -> Result:
       # Validate
       var validation = validate_currency_use(currency_type, item)
       if not validation.success:
           return Result.error(validation.reason)

       # Apply (with ability to rollback)
       var previous_state = item.serialize()
       var result = apply_currency_effect(currency_type, item)

       if not result.success:
           item.deserialize(previous_state)  # Rollback
           return Result.error(result.reason)

       # Commit
       consume_currency(currency_type)
       return Result.ok()
   ```
2. Make all currency effects return Result type with success/failure + reason
3. Only consume currency after successful effect application
4. Add UI feedback: "Cannot use X on this item: reason"

**Warning signs:**
- Players report "I used a currency but nothing happened and I lost it"
- Currency count decrements but item state unchanged
- No error message when currency use fails
- `add_prefix()` failure (line 94-96) has no return value checked by caller
- Currency use code doesn't check return values

**Phase to address:**
Phase 2 (Currency System) - This is a fundamental architecture requirement. All 6 currencies must implement validate-apply-commit from the start. Retrofitting this after currencies are implemented requires rewriting all currency handlers.

---

### Pitfall 7: Drop Table Rarity Probabilities Not Tested at Scale

**What goes wrong:**
`gameplay_view.gd` implements area scaling (line 233-251) where difficulty increases 1.5x per level. When adding rarity to drops, developers typically add:
```gdscript
func get_random_item_base() -> Item:
    var rarity = roll_rarity_based_on_area_level()  # e.g., Area 1: 80% Normal, 15% Magic, 5% Rare
    var item = generate_item_with_rarity(rarity)
```

But without simulation, common issues emerge:
- Area 1: Players get mostly Normal items (intended)
- Area 5: Players expect more Magic/Rare, but affix pool exhaustion causes most to downgrade to Normal
- Area 10: Rare items drop frequently, but Rare items require 6 affixes total - if item type only has 4 valid affixes, can never generate valid Rare
- Rarity curve doesn't match progression: Area 3 feels same as Area 1 because actual rarity distribution (after failed generations) is identical

**Why it happens:**
Drop table probabilities are designed based on intent ("Area 5 should have 50% Magic drops") without simulating actual generation success rates. The gap between "attempted rarity" and "achieved rarity" is invisible until players experience it.

**How to avoid:**
1. Build drop simulation tool:
   ```gdscript
   func simulate_drops(area_level: int, num_drops: int) -> DropStats:
       var stats = DropStats.new()
       for i in range(num_drops):
           var item = generate_item_for_area(area_level)
           stats.record(item.rarity, item.prefix_count, item.suffix_count)
       return stats
   ```
2. Run simulation for each area level with 10,000 drops
3. Compare attempted vs. achieved rarity distributions
4. Adjust drop probabilities to account for generation failure rate
5. Validate affix pool coverage: "Can this item type generate valid Rare items?"

**Warning signs:**
- Playtest feedback: "I never see Magic items even in high-level areas"
- Actual rarity distribution doesn't match configured probabilities
- Specific item types never drop as Rare
- Drop table shows "5% Rare" but simulation shows "0.1% Rare achieved"
- No testing framework for probabilistic systems

**Phase to address:**
Phase 3 (Drop System) - Simulation should be built AS PART OF drop implementation, not after. Make it a CI check: "All area levels must achieve minimum rarity distribution thresholds". If simulation fails, CI fails, forcing drop table or affix pool fixes before merge.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep old `hammer_counts` alongside new `currency_inventory` | No breaking changes, gradual migration | Dual state management, desync bugs, doubled currency awards | Never - creates permanent tech debt |
| Add `rarity` field but don't enforce in existing methods | Rarity displays work, old code unchanged | Items violate rarity rules, invalid states proliferate | Never - core invariant must be enforced everywhere |
| Use string literals for currency types ("runic", "forge") | Easy to implement, no enum needed | Typo bugs, no autocomplete, refactoring breaks silently | Only in prototype phase, must refactor before Phase 2 |
| Emit signals for some state changes but use direct calls for others | Incrementally adopt event bus | Inconsistent patterns, half the bugs of direct coupling remain | Acceptable during Phase 1 transition, not beyond |
| Allow Magic items to have 0 mods when generation fails | Prevents crashes, player still gets item | Meaningless items, confuses rarity system | Never - better to downgrade rarity or retry generation |
| Hard-code rarity thresholds (if mod_count >= 2: rarity = "Rare") | Simple to implement | Changing rarity rules requires hunting down thresholds | Never - use centralized `get_rarity_for_mod_count()` function |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Godot Signals for State Sync | Connect signals in `_ready()` but emit in `_init()` → listeners not registered yet | Emit state changes only after scene tree ready, or use deferred emit |
| ItemAffixes Singleton | Mutate global affix instances when rolling values → all items share same affix instance | Always use `Affixes.from_affix()` to create copies (line 32-34) |
| Hero Equipment Updates | Call `update_stats()` immediately after equipping → computed before item affixes applied | Use call_deferred or next frame update to ensure affixes processed first |
| Rarity Color Coding | Hard-code colors in UI ("Magic" → blue) → changing rarity names breaks UI | Use centralized `get_rarity_color(rarity: String) -> Color` function |
| Currency Effects on Equipped Items | Allow currency use on equipped items → hero stats out of sync | Either block currency use on equipped items OR trigger hero stat recalc on change |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Validating Entire Affix Pool on Every Add | `has_valid_tag()` iterates ALL affixes every time (potentially 30+ affixes × 6 mods per item) | Cache filtered affix pools per item type at init time | >100 items generated per second (idle game with fast progression) |
| Recomputing DPS on Every Affix Change | `update_value()` calls `compute_dps()` which iterates all affixes + complex math (lines 18-64) | Only recompute when item equipped or displayed, not during generation | >1000 items in inventory, sorting by DPS |
| Signal Emission Loops | Item rarity change → emits signal → hero updates → emits signal → item updates → infinite loop | Use signal guards: `if _updating: return` before emit, or defer emissions | First rarity change implementation |
| Deepcopying Items for Rollback | Serializing entire item state for every currency use validation | Only store changed fields (rarity, affixes array) not entire item | >50 currencies used per second (auto-crafter) |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No Visual Feedback on Invalid Currency Use | Player clicks currency, nothing happens, no explanation why | Show red tooltip: "Cannot use Runic Hammer: Item is already Magic" |
| Rarity Changes Without Indication | Item transitions Normal→Magic but looks the same until mouse hover | Add brief animation/particle effect on rarity change, color flash |
| Currency Icons All Look Similar | Player has 6 currency types, can't distinguish at a glance | Distinct shapes/colors: Runic=blue hammer, Forge=red anvil, Claw=grey pliers |
| Affix Pool Exhaustion Silent Failure | Magic item generates with 0 mods, player confused why | Downgrade rarity if generation fails: "Generated as Normal (insufficient affixes for Magic)" |
| No Undo for Expensive Currency | Player uses rare Tuning Hammer, rerolls from 80% to 30%, can't revert | Show value ranges before use: "Reroll: 20-100 (current: 80)" with confirmation |
| Rarity Color-Blind Unfriendly | Standard white/blue/yellow colors indistinguishable for 8% of players | Add text labels: "MAGIC" or pattern fills alongside colors |

## "Looks Done But Isn't" Checklist

- [ ] **Rarity Display:** Rarity color shown in UI — verify state changes update ALL views (crafting, hero, inventory)
- [ ] **Currency Validation:** Currency buttons exist — verify disable state when currency unusable on current item
- [ ] **Affix Count Enforcement:** add_prefix() respects rarity — verify works for ALL rarity transitions (Normal→Magic, Magic→Rare, not just initial generation)
- [ ] **Drop Rarity Scaling:** Higher areas drop higher rarity — verify ACTUAL drops (post-generation-failure) match expected rates, not just attempted rates
- [ ] **State Rollback:** Currency use can fail — verify currency NOT consumed on failure, item state unchanged
- [ ] **Signal Propagation:** Item rarity changes — verify hero stats recalculate, UI updates, drop eligibility updates
- [ ] **Affix Pool Coverage:** All item types can reach Rare — verify each type has 3+ valid prefixes AND 3+ valid suffixes
- [ ] **Migration Path:** Old hammer system removed — verify NO references to hammer_counts["implicit"|"prefix"|"suffix"] remain

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Dual currency systems (old hammers + new) | MEDIUM | 1. Add migration script: convert hammer_counts to currency_inventory. 2. Remove hammer_counts references. 3. Test old saves still load. No data loss if migration tested. |
| Items with invalid rarity state (Magic 0+0) | HIGH | 1. Scan all items in saves. 2. For invalid items: recalculate rarity from mod count OR add mods to meet rarity OR destroy item. 3. Player-visible item loss requires compensation. |
| UI desync from missing signals | LOW | 1. Identify state changes not emitting signals. 2. Add event emissions. 3. Connect listeners. No data corruption, only display bugs. |
| Affix pool exhaustion at runtime | MEDIUM | 1. Add emergency handler: if generation fails, downgrade rarity. 2. Log failures for analytics. 3. Expand affix pools in next patch. Temporary UX degradation, no crashes. |
| Currency consumed but effect failed | HIGH | 1. Requires save file edit or player compensation. 2. Add validation-before-consumption for future. 3. If widespread, grant affected players currency refunds. Player trust impact high. |
| Drop tables not tested at scale | LOW | 1. Run simulation. 2. Adjust probabilities. 3. Redeploy config. No code changes needed if generation logic sound. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Rarity state without enforcement | Phase 1: Rarity Foundation | Unit test: Create Normal item, call add_prefix(), assert fails or rarity becomes Magic |
| Currency validation without transitions | Phase 2: Currency System | Integration test: Use each currency on each rarity, verify state transitions or rejections correct |
| Hardcoded 3-hammer system not replaced | Phase 2: Currency System | Grep codebase for "hammer_counts", "implicit", "prefix", "suffix" dictionary keys - expect 0 results |
| UI state desync via direct references | Phase 1: Rarity Foundation | Integration test: Change rarity in one view, verify other views update within 1 frame |
| Affix pool exhaustion | Phase 1: Rarity Foundation (validation), Phase 3: Drop System (fixing) | Unit test: For each item type, attempt to generate 100 Rare items, assert 0 failures |
| No rollback on failed currency use | Phase 2: Currency System | Unit test: Use currency with mocked failure, verify currency count unchanged, item state unchanged |
| Drop table probabilities not tested | Phase 3: Drop System | Simulation test: 10k drops per area level, assert actual rarity distribution within 5% of target |

## Sources

**ARPG Rarity System Design:**
- [Path of Exile Rarity (PoE Wiki)](https://www.poewiki.net/wiki/Rarity)
- [Path of Exile 2 Item Rarity Explained (PoE Currency)](https://www.poecurrency.com/news/poe-2-why-can-item-rarity-make-you-rich)
- [Loot Tables in ARPG Game Design (Game Wisdom)](https://game-wisdom.com/critical/loot-tables-game-design)
- [Item/Equipment/Monster Rarity Discussion (GameDev.net)](https://www.gamedev.net/forums/topic/610743-itemequipmentmonster-rarity/)

**Crafting Currency Systems:**
- [Study of Path of Exile Currency Building (MMOJUGG)](https://www.mmojugg.com/news/study-of-path-of-exile-currency-building.html)
- [Currency System in Path of Exile 2 (Odealo)](https://odealo.com/articles/currency-system-in-path-of-exile-2)
- [Avoiding Pitfalls in Your Crafting System (DeepFriedGamer)](https://deepfriedgamer.com/blog/avoiding-pitfalls-in-your-crafting-system)
- [5 Approaches to Crafting Systems in Games (Envato Tuts+)](https://code.tutsplus.com/5-approaches-to-crafting-systems-in-games-and-where-to-use-them--cms-22628a)

**State Management & Refactoring:**
- [State Pattern in Game Programming (Game Programming Patterns)](https://gameprogrammingpatterns.com/state.html)
- [State Machines: Game Development Essentials (NumberAnalytics)](https://www.numberanalytics.com/blog/state-machines-game-development-essentials)
- [Breaking Free from Hardcoded Values (IN-COM DATA SYSTEMS)](https://www.in-com.com/blog/breaking-free-from-hardcoded-values-smarter-strategies-for-modern-software/)
- [Mastering Refactoring in Game Development (NumberAnalytics)](https://www.numberanalytics.com/blog/ultimate-guide-to-refactoring-in-game-programming)

**Godot Signal Patterns:**
- [Using Signals (Godot Documentation)](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- [Godot Signals Complete Guide (Generalist Programmer)](https://generalistprogrammer.com/tutorials/godot-signals-complete-guide-scene-communication)
- [Signals in Godot (Medium - Partly Functional)](https://medium.com/partly-functional/signals-in-godot-c042db56d0ac)

**Edge Cases & Validation:**
- [Understanding Edge Cases (TestDevLab)](https://www.testdevlab.com/blog/what-are-edge-cases)
- [Software Testing Lessons from Edge Cases (Qase)](https://qase.io/blog/edge-cases-lessons-learned/)

**Affix System Issues:**
- [Apotheosis: Insufficient Number of Affixes Bug (GitHub)](https://github.com/Shadows-of-Fire/Apotheosis/issues/1450)
- [Mythic Loot Affixes Not Generating (GitHub)](https://github.com/Shadows-of-Fire/Apotheosis/issues/1051)

---
*Pitfalls research for: Adding item rarity tiers and crafting currencies to existing ARPG codebase*
*Researched: 2026-02-14*
