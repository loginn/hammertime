# Codebase Concerns

**Analysis Date:** 2026-02-19

## Tech Debt

**Debug Code in Production:**
- Issue: `debug_hammers` flag and print statement left in active code path
- Files: `autoloads/game_state.gd` lines 3, 34-37
- Impact: Debug output pollutes console on every game launch; test flag requires code modification to enable/disable
- Fix approach: Move to dedicated debug/test scene or remove entirely; use environment variable or configuration file instead

**Stub Implementation in Item Base Class:**
- Issue: `Item.update_value()` is an empty `pass` statement meant to be overridden
- Files: `models/items/item.gd` lines 128-129
- Impact: Creates false sense of implementation; calling `update_value()` on base Item does nothing
- Fix approach: Make abstract if GDScript supports it; add warning/assertion if called on base class; document override requirement

**Temporary Scene Files in Repository:**
- Issue: Six `.tscn*.tmp` files left in root directory from Godot editor crashes or unsafe shutdowns
- Files: Multiple `*.tscn14021954782.tmp` through `*.tscn3150287910.tmp` in root
- Impact: Pollutes repository; unclear if safe to delete or if they contain unsaved work; confusion on version control
- Fix approach: Add `*.tmp` to `.gitignore`; determine if any contain valuable work and restore if needed; clean up

**Unused Custom Max Prefix/Suffix Variables:**
- Issue: `custom_max_prefixes` and `custom_max_suffixes` are nullable fields designed for override but no code sets them
- Files: `models/items/item.gd` lines 18-19, 23-25, 28-30
- Impact: Dead code path; increased complexity in affix count logic with no benefit
- Fix approach: Remove unless an upcoming feature uses them; if future intent exists, add comment explaining use case

## Known Bugs

**Save Corruption Handling Silent Failure:**
- Symptoms: Save file exists but is corrupted; game starts fresh but no user notification unless looking for toast message
- Files: `autoloads/save_manager.gd` lines 31-37, `autoloads/game_state.gd` lines 30
- Trigger: Save file becomes corrupted (truncated write, disk error, manual JSON edit with invalid syntax)
- Current mitigation: `save_was_corrupted` flag and `push_warning()` called; toast on main view should display
- Recommendation: Add recovery option to main menu (export current save as string before fresh start); add persistent visual indicator if load fails; test toast reliability

**Unknown Item Type Deserialization Returns Null:**
- Symptoms: Loading a save with unrecognized item type silently drops the item; inventory slot appears with fewer items than expected
- Files: `models/items/item.gd` lines 80-97 (especially lines 96-97)
- Trigger: Save file contains item type not in `ITEM_TYPE_STRINGS` (may happen if item class was removed, renamed, or corrupted)
- Workaround: None; item is lost silently
- Recommendation: Log which item type failed; add fallback to create a "ghost" item or default item so save is not corrupted; add migration path for renamed item types

**Float Precision in Damage Range Display:**
- Symptoms: Damage ranges show high decimal precision (e.g., "12.456 to 34.789 damage") while base stats show integers
- Files: `scenes/forge_view.gd` lines 853-854 (`%d` format for base, `%.1f` for ranges)
- Trigger: Percentage modifiers applied to base damage create fractional values
- Current approach: Ranges use `%.1f` format (one decimal)
- Recommendation: Decide on display precision (round to integer or document as "with affixes"); ensure consistency between all damage displays

## Security Considerations

**Save File Stored in User Directory Without Encryption:**
- Risk: Save file is plain JSON, readable by any process with file access; player progress, equipped items, currency all visible
- Files: `autoloads/save_manager.gd` line 3 (`SAVE_PATH = "user://hammertime_save.json"`)
- Current mitigation: None; relies on OS file permissions
- Recommendations: Consider obfuscation or simple XOR encoding for future versions; document data sensitivity; warn players not to share save files if they contain progress they care about

**Export String Format Not Authenticated:**
- Risk: Import feature accepts any string starting with `HT1:` and base64 decodes it; malicious string could contain arbitrary JSON
- Files: `autoloads/save_manager.gd` lines 221-226 (import path)
- Current mitigation: Schema validation on import (version check, item type check)
- Recommendations: Add cryptographic signature or HMAC to export string; validate checksum before decode; sanitize all dictionary keys/values after deserialize

**No Input Validation on Save Import:**
- Risk: Arbitrary JSON imported without bounds checking; malformed crafting_inventory arrays or negative currency counts could cause crashes
- Files: `autoloads/save_manager.gd` line 51-60 (JSON parse)
- Current mitigation: Type casting and `.get()` with defaults
- Recommendations: Add explicit validation function; check array sizes (crafting_inventory slots < 10 items); validate currency counts >= 0; validate area_level in reasonable range (1-1000)

## Performance Bottlenecks

**ForgeView UI Rebuild on Every Pack Kill:**
- Problem: `on_currencies_found()` calls `update_inventory_display()` on every pack currency drop, rebuilding 5 slot displays (50 potential labels) even when no items dropped
- Files: `scenes/forge_view.gd` lines 443-447
- Cause: Function refreshes item display for a currency event that never changes item display
- Impact: During heavy combat (8-15 packs per map), display rebuilds fire 8-15 times per map for no visual change; CPU hot spot in combat loop
- Improvement path: Split currency refresh from inventory refresh; only call `update_inventory_display()` when array mutations occur (drop/melt/equip)

**Pack Generation Element Weights Not Normalized Before Roll:**
- Problem: `PackGenerator.roll_element()` recalculates total weight every call without caching
- Files: `models/monsters/pack_generator.gd` lines 33-49
- Cause: Function is static and called per-pack; biome weights are properties, not cached
- Impact: For 8-15 packs per map, element weights are normalized 8-15 times; minor but accumulates
- Improvement path: Cache biome weights on level load; pass normalized weights to roll function

**DefenseCalculator Inline Calculations Without Caching:**
- Problem: Defense stats and resistances recalculated every time a pack attacks (potentially 8-15x per map)
- Files: `models/stats/defense_calculator.gd`, called from `models/combat/combat_engine.gd` line 113-124
- Cause: `DefenseCalculator.calculate_damage_taken()` runs full calculation per attack without caching hero stats
- Impact: In long maps, same hero stats are calculated 8-15+ times; cumulative work is small but repeated
- Improvement path: Cache hero defensive stats at combat start; recompute only on equipment change during combat (rare)

## Fragile Areas

**SaveManager with Two Save Paths (File + Export String):**
- Files: `autoloads/save_manager.gd` (file save) + undefined export string path
- Why fragile: File save and export string use different serialization; if one is updated without the other, they diverge
- Safe modification: Always update `_build_save_data()` and import/export path together; test both save types after each change
- Test coverage: File save-load covered; export string path not visible in codebase (may be in scenes or tools)

**CombatEngine State Machine with Async Transitions:**
- Files: `models/combat/combat_engine.gd` lines 159, 196 (async awaits)
- Why fragile: State transitions depend on timers completing; if state is changed externally during transition, guards may fail silently
- Safe modification: Always check `state` guard after await; never change state from external code during combat
- Test coverage: Manual testing only; no unit tests for race conditions between state changes

**Item Array Deserialization Without Type Safety:**
- Files: `models/items/item.gd` lines 80-122 (from_dict creates items by string type matching)
- Why fragile: Adding a new item class requires updating ITEM_TYPE_STRINGS array; forgetting to add causes silent null return
- Safe modification: Add assertion or error log if unknown type; consider factory pattern with centralized registration
- Test coverage: No automated test for each item type's serialize/deserialize round-trip

**Hero Stats Calculated from Equipment Without Caching:**
- Files: `models/hero.gd` lines 91-97 (update_stats calls multiple calculator functions)
- Why fragile: Equipment change calls `update_stats()` which recalculates everything; if called multiple times rapidly, recalculation is wasted
- Safe modification: Cache `total_dps`, `total_defense`, etc. as derived fields; only recalculate on equipment change
- Test coverage: No performance test to catch unnecessary recalculations

## Scaling Limits

**Crafting Inventory Hard Capped at 10 Items Per Slot:**
- Current capacity: 10 items × 5 slots = 50 items max
- Limit: Hardcoded in UI display (x/10 counter); once reached, drops are silently discarded
- Scaling path: If inventory expansion is needed, add UI pagination or scroll view to crafting slots; update capacity constant; add migration for old saves with > 10 items per slot

**Area Level Exponential Growth at 6% Per Level:**
- Current scaling: Level 100 = 321x multiplier, Level 300 = 42,012x multiplier
- Limit: At level 300+, monster damage/HP reach extreme values; float precision may introduce rounding errors; UI numbers become hard to read
- Scaling path: Add damage/HP number abbreviation (1.2M, 45B); consider capping or slowing growth at high levels; add difficulty cap beyond which progression is cosmetic

**Monster Pack Size 8-15 Per Map:**
- Current capacity: 15 packs maximum
- Limit: Combat loop runs 15 attack cycles per pack kill; 225 hero attacks per map; rendering bottleneck not yet hit
- Scaling path: If packs grow beyond 15, combat tick rate becomes measurable; monitor frame time in endgame

## Dependencies at Risk

**GDScript Resource Serialization Without Schema Versioning:**
- Risk: Item/Hero classes change field names or types; old saves fail to deserialize with no clear error path
- Impact: Major feature updates require migration code; missing migration silently corrupts old saves
- Migration plan: Implement comprehensive `_migrate_save()` function; bump SAVE_VERSION on every data structure change; test with old save fixtures before deploying

**Godot 4 Float Imprecision in Damage Calculations:**
- Risk: Damage ranges use float; comparing min/max or detecting changes may have rounding issues
- Impact: Displayed DPS may differ from calculated DPS by 0.1-1.0 due to float precision
- Migration plan: Document precision limits; use integer math where possible; add epsilon comparison for float equality checks

## Missing Critical Features

**No Validation for Affix Compatibility:**
- Problem: Code allows affixes with any tags on any item; no check ensures affixes are valid for item type
- Blocks: Quality assurance; broken item combinations can be crafted
- Recommendation: Add `is_valid_affix()` check before adding prefix/suffix; maintain compatibility matrix per item type

**No Undo/Redo for Crafting Actions:**
- Problem: Player applies hammer, gets bad roll; must melt and restart; no way to revert last action
- Blocks: Quality of life; frustrating for players doing many rolls
- Recommendation: Implement undo stack for crafting actions; "Undo Last Reroll" button in forge; cache pre-roll item state

**No Persistent Combat Log or Session History:**
- Problem: Combat events are emitted but not stored; player cannot review what happened in a fight
- Blocks: Debugging balance issues; players cannot explain unfair deaths
- Recommendation: Implement combat log (append event history to GameState); save log with game on completion; add log viewer scene

**No A/B Testing or Experiment Framework:**
- Problem: Balance changes require code modification and redeployment; no way to test changes without affecting all players
- Blocks: Live balance iteration; all players experience same difficulty
- Recommendation: Add feature flags system; store experiment config in JSON; client-side flag checking for gated features

## Test Coverage Gaps

**Untested: Save Migration Path (v1 to v2):**
- What's not tested: Loading a v1 save, running migration, verifying all data survives
- Files: `autoloads/save_manager.gd` lines 159-170 (migration stub currently empty); `autoloads/game_state.gd` lines 23-31
- Risk: v1 saves could silently lose data when loaded in v2 (especially if inventory rework proceeds without migration)
- Priority: HIGH - Must test before releasing any version with breaking save format change
- Recommendation: Create v1 save fixture JSON manually; add test that loads fixture and asserts correct migration

**Untested: Affix Application and DPS Recalculation:**
- What's not tested: Apply affix to item, verify DPS recalculates correctly, verify stat updates are accurate
- Files: `models/stats/stat_calculator.gd` (calculation logic); `scenes/forge_view.gd` (affix application UI)
- Risk: DPS formula could be wrong and players would not notice until comparing gear
- Priority: HIGH - Core mechanic; affects all balance
- Recommendation: Add unit tests for stat_calculator with known input/output pairs (e.g., "10 flat damage + 50% should be X DPS")

**Untested: Combat Damage Roll Distribution:**
- What's not tested: Hero and pack attacks roll damage correctly; crit chance/damage applied correctly; elemental damage routing works
- Files: `models/combat/combat_engine.gd` lines 72-96, 103-124 (attack logic)
- Risk: Crit formula could be inverted (150% damage treated as 1.5 multiplier instead of 2.5x); element resistances could be applied backward
- Priority: HIGH - Core combat; affects difficulty curve
- Recommendation: Add integration tests; mock random rolls; verify damage output matches expected formula

**Untested: UI Display Precision and Rounding:**
- What's not tested: Damage range display rounds correctly; hero stats label shows accurate values; no off-by-one errors in counter
- Files: `scenes/forge_view.gd` lines 850-966 (all display functions)
- Risk: Display shows 12.5 DPS but actual is 12.3; player sees inconsistent numbers; undermines trust in calculations
- Priority: MEDIUM - User-facing; not critical but frustrating
- Recommendation: Add visual regression tests or snapshot tests; verify displayed values match calculated values

**Untested: Error Recovery (Corrupted Save, Missing Item Type, File I/O Failure):**
- What's not tested: Game handles corrupted save without crashing; missing item type causes graceful error; file write failure is caught
- Files: `autoloads/save_manager.gd` (all error paths); `models/items/item.gd` lines 96-97
- Risk: Rare edge cases cause silent failures or crashes; no diagnostic info for players or developers
- Priority: MEDIUM - Edge case but affects user retention
- Recommendation: Add error scenario tests; corrupt a save file intentionally; test deserialization of unknown item type

---

*Concerns audit: 2026-02-19*
