# Pitfalls Research

**Domain:** Godot 4.5 Idle ARPG - Save/Load, UI Restructure, Crafting UX, Balance Tuning
**Researched:** 2026-02-17
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Resource.duplicate() Doesn't Deep Copy Arrays of Resources

**What goes wrong:**
Save/load corruption occurs when Items are serialized because `Resource.duplicate(true)` does not duplicate subresources stored in Array properties. Item has `prefixes: Array[Affix]` and `suffixes: Array[Affix]`. When GameState saves Hero with equipped items, the Affix arrays are shallow-copied, creating reference-sharing between save data and runtime state. Modifying a loaded item corrupts the save.

**Why it happens:**
Godot's documentation states "Subresources inside Array and Dictionary properties are never duplicated" but this is only mentioned in Array.duplicate() docs, not Resource.duplicate() or Dictionary docs. Developers assume `duplicate(true)` handles nested Resources.

**How to avoid:**
1. Implement custom `deep_duplicate()` method on Item class
2. Manually iterate `prefixes` and `suffixes` arrays
3. Call `Affixes.from_affix()` to create new instances (already exists in codebase at item.gd:159, 186)
4. Do NOT rely on `Resource.duplicate(true)` for save serialization

**Warning signs:**
- Item modifications persist after loading a save (affix changes appear in fresh loads)
- Save file size doesn't grow when adding items (references instead of copies)
- Random crashes when accessing affix properties after load
- Debug prints show same affix instances across different items

**Phase to address:**
Phase 1 (Save/Load Foundation) - Must implement before any save serialization code. Create `Item.deep_duplicate()` that handles nested arrays properly.

---

### Pitfall 2: CanvasLayer Visibility Doesn't Inherit from Parent Node2D

**What goes wrong:**
When restructuring UI from tab-switching to side-by-side layout, GameplayView's CombatUI (a CanvasLayer at line 10 of main_view.gd) doesn't inherit visibility from parent GameplayView. Currently handled with explicit sync at main_view.gd:86, but side-by-side layout will have multiple views visible simultaneously. Forgetting to sync each CanvasLayer causes invisible but active UI elements that still process input, block clicks, and trigger hover effects on hidden views.

**Why it happens:**
CanvasLayer exists outside the scene tree hierarchy for rendering purposes. It renders to viewport directly, ignoring parent Node2D visibility. Developers structure UI in scene tree assuming standard visibility propagation.

**How to avoid:**
1. When adding side-by-side layout, create explicit CanvasLayer visibility management
2. Pattern: `canvas_layer.visible = parent_view.visible and should_render()`
3. Use signal-based coordination: parent view emits `visibility_changed` signal
4. Never assume CanvasLayer inherits parent state
5. For split-screen UI: assign each CanvasLayer to different layer numbers to control render order

**Warning signs:**
- Click events don't reach visible UI (hidden CanvasLayer blocking input)
- Performance degradation (invisible CanvasLayers still processing)
- UI elements appear in wrong view after visibility toggle
- Mouse hover highlights on views that should be hidden

**Phase to address:**
Phase 2 (UI Layout Restructure) - Before converting main_view.gd from visibility toggling to concurrent rendering. Add CanvasLayer management abstraction.

---

### Pitfall 3: Control Node Anchor Positioning Breaks When Switching from Fixed to Container Layout

**What goes wrong:**
Current UI uses manual anchor positioning (main.tscn lines 20-47: buttons positioned with `anchor_left`, `anchor_right`, `offset_left`, `offset_right`). Converting to Container-based layout (HBoxContainer, VBoxContainer, MarginContainer for side-by-side views) while keeping anchor properties causes Containers to compute size as 0x0. Buttons disappear or overlap at viewport origin. On mobile renderer (1200x700), this manifests as entire UI panels stacking at (0,0).

**Why it happens:**
Control nodes have two mutually exclusive sizing modes: anchor-based (manual) and container-based (automatic). Anchors set explicit positions that override Container min_size calculations. Containers use `rect_min_size` and children's minimum size to auto-layout. Mixing the two creates undefined behavior.

**How to avoid:**
1. When converting navigation panel to Container: set all anchors to 0, all offsets to 0
2. Use Container properties instead: `size_flags_horizontal`, `size_flags_vertical`, `custom_minimum_size`
3. For button spacing: use `separation` in BoxContainers, not offsets
4. For centering: use `alignment` property in BoxContainers, not `anchor = 0.5`
5. Test at exact viewport size (1200x700) before testing responsive behavior
6. Add `minimum_size` override on root Container to prevent collapse

**Warning signs:**
- Container shows size (0, 0) in remote inspector while running
- UI elements appear at top-left (0, 0) instead of intended position
- Buttons overlap each other vertically or horizontally
- Resizing viewport doesn't update layout (Container not recalculating)
- Different behavior in editor vs. runtime

**Phase to address:**
Phase 2 (UI Layout Restructure) - During conversion from manual positioning to Container hierarchy. Create clean Container structure THEN migrate children, not simultaneously.

---

### Pitfall 4: Integer Division Truncation in Combat Math Pipeline

**What goes wrong:**
DefenseCalculator uses int armor/evasion with float damage. At defense_calculator.gd:18, `float(armor) / (float(armor) + 5.0 * raw_physical_damage)` is safe, but if balance tuning introduces intermediate integer calculations (e.g., "armor = base_armor * strength / 10"), GDScript performs integer division, truncating decimals. A hero with 25 strength and 8 base_armor computes `8 * 25 / 10 = 200 / 10 = 20` correctly, but `8 / 10 * 25 = 0 * 25 = 0` (order matters). This silently breaks DefenseCalculator's diminishing returns formula.

**Why it happens:**
GDScript performs integer division when both operands are integers, automatically truncating decimals. In stat calculations with multiple terms, division order determines whether truncation occurs. Armor formula works because explicit `float()` casts happen first, but new balance formulas may not.

**How to avoid:**
1. Always cast first operand to float in any division: `float(base_armor) / 10 * strength`
2. Use float literals for constants: `8.0` not `8` in formulas
3. For level 1 balance tuning: create formula validation test that prints intermediate values
4. Document stat type expectations: which stats are int (armor, evasion) vs float (dps, damage reduction)
5. In StatCalculator, standardize: all intermediate calculations use float, final display values cast to int if needed

**Warning signs:**
- Stat values are always round numbers (45, 60, 90) never decimals
- Defense effectiveness plateaus unexpectedly (0.0 reduction at low armor)
- Incrementing stat by 1 has no effect (9/10 = 0, 10/10 = 1, jump from 0 to 1)
- Tooltip displays "X armor grants Y% reduction" but actual reduction is 0%
- Balance spreadsheet predicts different values than game shows

**Phase to address:**
Phase 4 (Level 1 Balance) - Before implementing new stat formulas. Add stat calculation test suite that validates intermediate float precision.

---

### Pitfall 5: Save Data Schema Changes Break Existing Saves Without Migration

**What goes wrong:**
Adding new properties to Hero, Item, or Affix (e.g., adding `item_level: int` or `affix_tier_range: Vector2i`) breaks existing save files. Godot's resource loader sets missing properties to default values (0, null, empty array). Loaded items have `tier_range = Vector2i(0, 0)` instead of `Vector2i(1, 8)`. Affix._init() at affix.gd:32 calls `randi_range(0, 0)` resulting in tier 0. Item formulas divide by tier, causing division by zero crash or infinite stat values.

**Why it happens:**
Resource serialization stores property names and values. When loading a .tres/.res file missing a property, Godot initializes it with GDScript's default value (0 for int, null for Object), NOT the value set in _init(). Affix._init() sets tier_range but loaded Resources skip _init() entirely - they call _init() with no arguments then populate properties from file.

**How to avoid:**
1. Implement save version tracking: add `const SAVE_VERSION = 1` to GameState
2. Store version in save file header: `{ "version": 1, "hero": {...}, "currencies": {...} }`
3. Create migration functions: `migrate_v1_to_v2(save_data: Dictionary) -> Dictionary`
4. Before deserializing: check version, run migrations sequentially (v1→v2→v3→current)
5. For property additions: use `get("property", default_value)` when reading saves
6. For property renames: migration copies old name to new name, deletes old
7. For property removals: migration deletes the key (safe since Godot ignores unknown properties)

**Warning signs:**
- Loading save shows "Invalid resource format" errors
- Loaded hero has 0 stats but save file shows correct values in text editor
- Items from loaded save have empty affix arrays
- Crashes on load with "Attempt to call function on null instance"
- Fresh saves work but old saves from yesterday fail

**Phase to address:**
Phase 1 (Save/Load Foundation) - Implement versioning and empty migration pipeline BEFORE first playable save system. Easier to add migrations incrementally than retrofit later.

---

### Pitfall 6: Crafting Inventory Dictionary Uses Strings, Equipment Uses null Checks

**What goes wrong:**
GameState.hero.equipped_items uses slot strings as keys with null values for empty slots (game_state.gd:12-16). CraftingView.crafting_inventory uses same pattern (crafting_view.gd:247-248). But Item type checking uses `if item is Weapon` (item.gd:58, 88, crafting_view.gd:273-282). Adding new item types requires updating 6+ match/if chains across codebase. When adding Save/Load, inconsistent null handling causes saves to serialize `{"weapon": null}` but loads expect `{"weapon": <Item>}`, throwing "Cannot access property on null" errors.

**Why it happens:**
Two mental models mixed: Dictionary-with-nulls (empty slots are present keys with null values) vs. Dictionary-without-keys (empty slots are absent keys). Code sometimes checks `if slot in dict` (key presence), sometimes `if dict[slot] != null` (value presence), sometimes `if dict.get(slot)` (implicit null check). All work until serialization converts between formats.

**How to avoid:**
1. Standardize on Dictionary-with-nulls: always initialize all slots with null
2. Always check value presence: `if equipped_items.get("weapon")` not `if "weapon" in equipped_items`
3. Create helper: `GameState.has_equipped(slot: String) -> bool` that encapsulates null check
4. For save serialization: filter out null values before writing, restore on load: `equipped_items.get("weapon", null)`
5. For new item types: extend ItemType enum instead of string literals, use enum for type safety

**Warning signs:**
- "Invalid access of property on null" after loading save
- Some items show as equipped in one view but not in another
- Finishing item in crafting doesn't clear from hero view
- Save file shows `"weapon": null` in JSON but load expects missing key
- Dictionary.size() counts empty slots (should it?)

**Phase to address:**
Phase 1 (Save/Load Foundation) - Before serializing equipped_items. Add helper methods and standardize null checks.

---

### Pitfall 7: UI Restructure from Sequential Tabs to Side-by-Side Breaks Signal Flow

**What goes wrong:**
Current architecture uses main_view as signal hub: crafting_view → hero_view, hero_view → gameplay_view (main_view.gd:20-23). When views are hidden via visibility toggle, signals still fire but recipients process stale data. Converting to side-by-side layout where multiple views are visible means ALL views process every signal. Example: equipping item in hero_view triggers `equipment_changed` → gameplay_view.refresh_clearing_speed() → recalculates DPS. But if crafting_view is also visible and responds to equipment_changed (to update UI preview), it reads hero.equipped_items while hero_view is mid-update, seeing partially-applied state.

**Why it happens:**
Signal-based architecture assumes sequential single-view processing. Signals fire synchronously in connection order. If multiple views connect to same signal and first view modifies shared state (GameState.hero), second view sees intermediate state. Side-by-side layout makes this race condition visible.

**How to avoid:**
1. Audit all signals: document which signals modify state vs. notify of changes
2. State-modifying signals should be one-way: `hero_view.equipment_changed` means "I modified hero, please refresh"
3. Never read GameState in signal handlers - use signal parameters: `equipment_changed(slot: String, item: Item)`
4. For UI updates triggered by multiple views visible: use deferred calls: `refresh_ui.call_deferred()`
5. Create signal ordering contract: state changes → UI updates → layout recalculations
6. Consider replacing some signals with direct method calls when order matters

**Warning signs:**
- Item appears equipped in one view but not another until view switch
- Currency counts desync between views (one shows old count)
- Clicking item in crafting updates hero_view but not currency display
- Random "index out of range" errors when signals fire during state mutation
- Race conditions that only occur when specific views are visible together

**Phase to address:**
Phase 2 (UI Layout Restructure) - Before enabling concurrent view visibility. Refactor signal handlers to be state-query-free.

---

### Pitfall 8: Balance Tuning Cascades Across DefenseCalculator, StatCalculator, CombatEngine Without Visibility

**What goes wrong:**
Tweaking level 1 monster damage (from 10 → 15) seems safe, but triggers cascade: CombatEngine calculates raw damage → DefenseCalculator.calculate_armor_reduction() uses `armor / (armor + 5 * raw_damage)` → 5x multiplier in denominator amplifies damage change → at 100 armor, reduction changes from 66.7% (vs 10 damage) to 57.1% (vs 15 damage) → hero dies 2x faster. Without spreadsheet tracking, this is invisible until UAT. Worse: increasing starting armor (50 → 100) to compensate makes high armor even stronger due to diminishing returns curve shape, creating balance divergence between early/late game.

**Why it happens:**
DefenseCalculator uses non-linear formulas (hyperbolic for armor, hyperbolic for evasion, capped linear for resistances). StatCalculator aggregates affixes linearly. CombatEngine applies in pipeline (evasion → resistance → armor → ES split). Changing any input value propagates through pipeline with different scaling at each stage. The 5x multiplier in armor formula and 200 constant in evasion formula are magic numbers with no design documentation - tuning without understanding their derivation breaks intended curve.

**How to avoid:**
1. Create balance spreadsheet with columns: Raw Damage | Armor | Armor Reduction % | Effective HP Multiplier | Time to Die
2. Formula: `effective_hp = base_hp / (1 - armor_reduction)`, `time_to_die = effective_hp / dps`
3. When tuning damage: fill rows with armor values [0, 50, 100, 200, 500] to see curve shape
4. When tuning armor: fill rows with damage values [10, 50, 100, 200] to see diminishing returns
5. Establish invariant: level 1 hero (assume 50 armor) should survive 20 seconds against level 1 monster
6. Red flag: if tuning one stat requires tuning 3+ other stats to compensate, formula needs redesign
7. Document magic numbers: why 5x? why 200? Reference ARPG balance theory or PoE formulas

**Warning signs:**
- Small stat changes have huge gameplay impact (1 point armor = 20% tankier)
- High-stat builds become exponentially stronger (diminishing returns should prevent this)
- Balance feels good at level 1, breaks at level 5
- Spreadsheet calculations don't match in-game results (formula transcription error?)
- Tuning becomes whack-a-mole: fix early game, break late game, repeat

**Phase to address:**
Phase 4 (Level 1 Balance) - Before any numeric changes. Build spreadsheet first, then tune with data.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip save versioning, assume save schema never changes | Faster initial implementation | Every schema change breaks all existing saves, player frustration, support burden | Never - versioning is 10 lines of code |
| Use string literals for item types instead of enum | Less boilerplate, faster typing | No type safety, typos cause runtime errors, refactoring requires grep | Prototype only |
| Manual visibility sync for CanvasLayers | Works with current single-view design | Breaks silently when adding concurrent views, input blocking bugs | Single-view UI only |
| Hard-code balance values in GDScript constants | Quick iteration during testing | Cannot tune without code changes, recompile required, no A/B testing | Pre-alpha only |
| Shallow copy Resources for save/load | Assume Godot handles it | Silent data corruption, save files share references with runtime | Never - corruption is unfixable |
| Mix anchor positioning with Container layout | Reuse existing positioned nodes in new Containers | 0x0 size bugs, viewport-dependent behavior, mobile breaks | Never - clean one or the other |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Save/Load with Resources | Use `Resource.duplicate(true)` assuming deep copy | Implement custom `deep_duplicate()` that manually copies typed arrays |
| CanvasLayer in multi-view UI | Assume visibility inherits from parent Node2D | Explicitly sync `canvas_layer.visible = parent.visible` |
| Container migration | Convert parent to Container but leave children with anchors | Reset all child anchors/offsets to 0, use Container properties |
| Balance spreadsheet → GDScript | Copy formula from spreadsheet with integer division | Cast first operand to float or use `.0` literals |
| Signal-based view communication | Connect all views to all signals | Use signal parameters, avoid state reads in handlers |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Deep copying Resources on every save | Save takes 1-2 seconds on item-heavy builds | Only deep copy when necessary, cache serialization | 100+ items in inventory |
| CanvasLayers rendering when hidden | 30 FPS with 3 views despite only 1 visible | Explicitly set `canvas_layer.visible = false` | 3+ concurrent CanvasLayers |
| Signal cascade during view switch | Frame spike when changing tabs | Use `call_deferred()` for non-critical UI updates | 5+ connected signals |
| Recalculating stats on every frame | FPS drops when equipment window open | Cache stat totals, recalculate only on `equipment_changed` signal | 10+ affixes per item |
| Container layout with deeply nested hierarchy | UI update lag (100ms+) on viewport resize | Flatten Container hierarchy, max 3 levels deep | 5+ nested Containers |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No feedback when hammer click does nothing | Click item with no hammer selected - nothing happens, no message | Show toast message "Select a hammer first" |
| Side-by-side layout doesn't fit 1200x700 viewport | UI elements overlap or scroll off screen | Design for 1200x600 usable space (100px for nav) |
| Crafting inventory auto-replaces lower tier items | Find rare helmet, auto-deletes magic helmet user was crafting | Show "Replace?" confirmation or use separate stash |
| Save/load has no error messages on corruption | Load fails silently, player at main menu with no feedback | Show error popup: "Save file corrupted (version mismatch)" |
| Balance changes between sessions break progression | Player balanced for old damage values, suddenly dies | Display patch notes on load, offer stat respec |

## "Looks Done But Isn't" Checklist

- [ ] **Save/Load:** Saves load successfully but have you tested loading v1 save after adding new Hero property? (Schema migration)
- [ ] **Save/Load:** Deep copied Items but did you deep copy the Affix arrays inside? (Nested Resources)
- [ ] **UI Layout:** Side-by-side views render but did you test CanvasLayer visibility sync? (Invisible input blocking)
- [ ] **UI Layout:** Containers position correctly in editor but did you test at runtime 1200x700? (Anchor conflict)
- [ ] **Crafting UX:** Item selection works but did you test clicking with no hammer selected? (Missing feedback)
- [ ] **Crafting UX:** Currency buttons update counts but did you test when count hits 0 mid-click? (Race condition)
- [ ] **Balance Tuning:** Damage values feel right but did you test with 0 armor? 500 armor? (Edge cases)
- [ ] **Balance Tuning:** Formulas work in spreadsheet but did you verify no integer division in GDScript? (Type coercion)
- [ ] **Signal Flow:** Signals fire correctly but did you test with all 3 views visible simultaneously? (State race)

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Resource arrays not deep copied | HIGH | 1. Add `Item.deep_duplicate()` method 2. Replace all `item.duplicate(true)` calls 3. Wipe existing saves (no migration possible from corrupted references) 4. Apologize to alpha testers |
| CanvasLayer visibility not synced | LOW | 1. Add `_sync_canvas_layers()` method to main_view 2. Call on `show_view()` 3. Test with all view combinations |
| Anchor/Container conflict | MEDIUM | 1. Create new Container hierarchy in separate scene 2. Migrate children one-by-one, resetting anchors 3. Test layout at 1200x700 4. Replace old scene with new |
| Integer division in stat formula | LOW | 1. Add `.0` to all division literals 2. Cast variables to float 3. Add unit test 4. Compare before/after in spreadsheet |
| Save schema changed without versioning | HIGH | 1. Add versioning system NOW 2. Bump to v2 with migration v1→v2 3. Cannot recover v1 saves (wipe required) 4. Document lesson learned |
| Balance cascade not modeled | MEDIUM | 1. Build spreadsheet from scratch with all formulas 2. Input current values, verify matches game 3. Tune in spreadsheet 4. Copy tuned values to GDScript 5. Playtest to verify |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Resource.duplicate() doesn't deep copy arrays | Phase 1 (Save/Load Foundation) | Unit test: modify loaded item's affix, reload save, verify affix unchanged |
| CanvasLayer visibility doesn't inherit | Phase 2 (UI Layout Restructure) | Manual test: show gameplay view, verify combat UI visible; hide gameplay, verify combat UI hidden |
| Anchor/Container conflict causes 0x0 size | Phase 2 (UI Layout Restructure) | Launch at 1200x700, verify all UI visible; resize to 800x600, verify no overlap |
| Integer division truncates stats | Phase 4 (Level 1 Balance) | Unit test: calculate armor reduction with float vs int, assert equal |
| Save schema changes break old saves | Phase 1 (Save/Load Foundation) | Integration test: save as v1, add property, load as v2, verify migration ran |
| Crafting inventory null handling inconsistent | Phase 1 (Save/Load Foundation) | Unit test: serialize empty slot, deserialize, verify null |
| Signal flow breaks with concurrent views | Phase 2 (UI Layout Restructure) | Manual test: show all 3 views, equip item, verify all views update correctly |
| Balance cascades not modeled | Phase 4 (Level 1 Balance) | Spreadsheet test: change damage by 50%, verify effective HP multiplier within 20% |

## Godot 4.5 Specific Gotchas

### Resource Serialization Quirks

1. **Tres File External Resource Stripping**: When moving scene files with external resource references (`.tres` files for Items, Affixes), the scene writer may strip out external resources and parser has trouble reading the new files. **Mitigation**: Use internal resources for save data (JSON or binary), not external `.tres` files.

2. **Resource Cache Prevents Reloading**: Godot's resource cache prevents reloading already-loaded resources like savegames. Loading `user://save_slot_1.res` multiple times returns the cached version, not disk version. **Mitigation**: Use `ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)` for save files.

3. **Custom Resources Break on Upgrade**: Custom resource types that worked in Godot 4.3 may break in 4.4+, with Godot ignoring the custom script and treating as plain Resource. **Mitigation**: Avoid relying on Resource script inheritance for save data; use plain Dictionary serialization.

### CanvasLayer Layering Issues

1. **Dynamic UI on Layer 1024**: Dynamically generated UI elements (popups, menus) inherit from Window class and render on layer 1024, while static UI renders on layer 0. **Mitigation**: Set explicit `layer` property on all CanvasLayers to control render order. For side-by-side layout: Crafting UI layer 0, Hero UI layer 1, Gameplay UI layer 2.

2. **First Control Node Detaches**: First Control node under CanvasLayer follows viewport instead of CanvasLayer, detaching from scene and becoming part of parent scene. **Mitigation**: Wrap first Control in a Container or add dummy Control as first child.

### Container Sizing on Mobile Renderer

1. **SubViewportContainer Stretch Undoes Itself**: Resizing SubViewportContainer with stretch enabled changes child SubViewport size to match, undoing the stretch effect. **Mitigation**: Don't use SubViewportContainer for side-by-side layout; use regular Containers with Control nodes.

2. **CenterContainer Squishes Children**: If Control children have no minimum size, CenterContainer squishes them to 0x0. **Mitigation**: Set `custom_minimum_size` on all Controls or use `size_flags_expand` + `size_flags_fill`.

3. **Viewport Rect_Scale Causes Distortion**: Changing ViewportContainer's `rect_scale` distorts contents. **Mitigation**: Adjust margins, not scale, to resize ViewportContainers.

### GDScript Type System

1. **Float is 64-bit in Godot 4**: Unlike Godot 3 (32-bit float), Godot 4 uses 64-bit double precision float. **Implication**: More precision for stat calculations, but ConfigFile saves large floats incorrectly (1234567.0 → 1234570.0). **Mitigation**: Use int for currencies and large numbers, float only for percentages and ratios.

2. **Integer Division Auto-Truncates**: `5 / 2 = 2` not `2.5`. **Mitigation**: Cast first operand: `float(5) / 2 = 2.5` or use literal: `5.0 / 2 = 2.5`.

## Sources

**Godot Resource Serialization:**
- [Saving and Loading Games in Godot 4 (with resources) | GDQuest Library](https://www.gdquest.com/library/save_game_godot4/)
- [How to load and save things with Godot: a complete tutorial about serialization](https://forum.godotengine.org/t/how-to-load-and-save-things-with-godot-a-complete-tutorial-about-serialization/44515)
- [Failed to create instances when loading nested resources · Issue #66973](https://github.com/godotengine/godot/issues/66973)
- [Resource.duplicate(true) doesn't duplicate subresources stored in Array or Dictionary properties · Issue #74918](https://github.com/godotengine/godot/issues/74918)
- [Duplicate Godot custom resources deeply, for real](https://simondalvai.org/blog/godot-duplicate-resources/)

**CanvasLayer UI Issues:**
- [Canvas layers — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/2d/canvas_layers.html)
- [CanvasLayer not matching with first child control · Issue #81514](https://github.com/godotengine/godot/issues/81514)
- [Bite-Sized Godot: The fix for UI and post-processing shaders in Godot 4](https://shaggydev.com/2025/04/09/godot-ui-postprocessing-shaders/)

**Container Layout:**
- [UI Layout using Containers in Godot](https://gdscript.com/solutions/ui-layout-using-containers-in-godot/)
- [Resizing SubViewportContainer with stretch enabled · Issue #62041](https://github.com/godotengine/godot/issues/62041)
- [Overview of Godot UI containers | GDQuest](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/start_a_dialogue/all_the_containers)

**Crafting/Inventory UX:**
- [How To Build An Inventory System In Godot 4](https://gamedevacademy.org/godot-inventory-system-tutorial/)
- [Inventory System Design Fundamentals: Item Management with Resources and Signals](https://uhiyama-lab.com/en/notes/godot/inventory-system/)

**Balance Tuning:**
- [Balancing Tips: How We Managed Math on Idle Idol](https://www.gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol)
- [How do you use spreadsheets to manage your game's data and balance?](https://www.linkedin.com/advice/0/how-do-you-use-spreadsheets-manage-your-games-data)
- [Balance & Tuning | Understanding Games](https://medium.com/understanding-games/balance-tuning-8e0871ad0a0b)

**Godot 4 Type System:**
- [Godot Integer Division: Stop Losing Decimals! (Quick Fix)](https://the-scientist.blog/45208-godot-integer-division-stop-losing-decimals)
- [float — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/classes/class_float.html)

**Save Schema Migration:**
- ["Godot 4" save system version migration data schema changes](https://www.gdquest.com/library/save_game_godot4/)
- [Saving games — Godot Engine (stable) documentation](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html)

---
*Pitfalls research for: Hammertime v1.3 Milestone - Save/Load, UI Restructure, Crafting UX, Balance Tuning*
*Researched: 2026-02-17*
*Confidence: HIGH - Based on official Godot documentation, GitHub issues, community patterns, and codebase analysis*
