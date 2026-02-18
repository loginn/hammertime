# Phase 28: GameState Data Model and Drop Flow - Research

**Researched:** 2026-02-18
**Domain:** GDScript data model migration (internal codebase)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- `GameState.crafting_inventory` changes from `Dictionary` of `Item|null` to `Dictionary` of `Array`
- Every slot always has an array key -- even empty slots are `[]`, never null
- Five canonical slots: `weapon`, `helmet`, `armor`, `boots`, `ring`
- `add_item_to_inventory()` in `forge_view.gd` appends to the slot array instead of replacing
- If the array already has 10 items, the new item is silently discarded
- The `is_item_better()` guard is removed from the drop path entirely
- `is_item_better()` function itself may remain if used by stat comparison display
- `initialize_fresh_game()` initializes all slots as empty arrays `[]`; weapon slot gets `[starter_weapon]`
- Delete `var crafting_bench_item: Item = null` from `game_state.gd`
- Delete `crafting_bench_item = null` from `initialize_fresh_game()`
- Update all ForgeView references that read/write `GameState.crafting_bench_item`
- `SaveManager._restore_state()` populates the full arrays into GameState (no more single-item extraction)
- `SaveManager._build_save_data()` reads from actual arrays in GameState
- ForgeView reads `crafting_inventory[slot][0]` or checks `.is_empty()` where it previously checked `!= null`
- Full bench selection logic (picking highest-tier) belongs to Phase 29

### Claude's Discretion
- Whether to create a helper function like `get_best_item(slot)` on GameState or keep it in ForgeView
- Exact implementation of the starter weapon creation (inline or via `add_item_to_inventory`)
- Whether `add_item_to_inventory` returns a bool (added/discarded) or void
- Internal structure of ForgeView compatibility updates

### Deferred Ideas (OUT OF SCOPE)
None -- phase scope is well-defined by roadmap success criteria
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INV-01 | Items drop into per-slot inventory arrays | Reshape crafting_inventory to Array per slot, update add_item_to_inventory to append |
| INV-02 | Each slot holds up to 10 items; drops to full slot silently discarded | add_item_to_inventory checks array size before append |
</phase_requirements>

## Summary

Phase 28 is a purely internal codebase migration with zero external dependencies. The work reshapes `GameState.crafting_inventory` from `{slot: Item|null}` to `{slot: Array}`, updates the single add point (`add_item_to_inventory`) to enforce a 10-item cap, removes `crafting_bench_item` from GameState, completes the SaveManager bridge from Phase 27, and updates all ForgeView consumers to handle arrays instead of single items.

The codebase has clear boundaries: `GameState.crafting_inventory` is read in 12 locations across 3 files (`game_state.gd`, `save_manager.gd`, `forge_view.gd`). The `crafting_bench_item` field has only 2 references in `game_state.gd` (declaration + initialization) and 2 in `save_manager.gd` (already handled by Phase 27's migration code).

**Primary recommendation:** Execute as a single plan with 2-3 tasks: (1) GameState model + SaveManager bridge, (2) ForgeView drop flow + compatibility updates.

## Architecture Patterns

### Current Data Flow (Pre-Phase 28)

```
combat_engine._on_map_completed()
  -> GameEvents.items_dropped.emit(level, count)
    -> gameplay_view._on_items_dropped()
      -> item_base_found.emit(item_base)
        -> forge_view.set_new_item_base(item_base)
          -> forge_view.add_item_to_inventory(item_base)
            -> is_item_better() gate
            -> GameState.crafting_inventory[type] = item  (single item replace)
```

### Target Data Flow (Post-Phase 28)

```
Same signal chain, but:
  -> forge_view.add_item_to_inventory(item_base)
    -> NO is_item_better() gate
    -> GameState.crafting_inventory[type].append(item)  (array append)
    -> 10-item cap check (discard if full)
```

### ForgeView Consumer Patterns

Every place ForgeView reads `GameState.crafting_inventory[slot]` currently expects `Item|null`. After Phase 28, it gets `Array`. The minimal compatibility approach:

| Current Pattern | New Pattern |
|----------------|-------------|
| `crafting_inventory.get(type) != null` | `not crafting_inventory[type].is_empty()` |
| `crafting_inventory[type]` (as Item) | `crafting_inventory[type][0]` (first item) |
| `crafting_inventory[type] = item` | `crafting_inventory[type].append(item)` |
| `crafting_inventory[type] = null` | `crafting_inventory[type].erase(item)` or `.remove_at(idx)` |

## Common Pitfalls

### Pitfall 1: Melt/Equip Setting Slot to Null
**What goes wrong:** `_on_melt_pressed()` and `_on_equip_pressed()` currently set `GameState.crafting_inventory[slot_name] = null`. After migration, slots must never be null (always arrays).
**How to avoid:** Replace `= null` with array removal. For Phase 28 minimal compatibility, melt/equip should remove the item from the array. Note: Phase 29 will refactor melt/equip more thoroughly, but Phase 28 must not break these paths.

### Pitfall 2: _ready() Starting Item Logic
**What goes wrong:** ForgeView `_ready()` checks `GameState.crafting_inventory.get(type_name) != null` to detect fresh game. With arrays, this check always returns non-null (returns the array itself).
**How to avoid:** Change to `.is_empty()` check. The logic "no items in any slot" means all arrays are empty.

### Pitfall 3: update_inventory_display Expects Item
**What goes wrong:** `update_inventory_display()` reads `GameState.crafting_inventory.get(item_type)` as an Item and accesses `.item_name`, `.rarity`. With arrays, this crashes.
**How to avoid:** Read `crafting_inventory[type][0]` for display, or check `.is_empty()` first. Phase 28 shows first item; Phase 29 adds highest-tier selection.

### Pitfall 4: SaveManager Bridge Must Change Both Directions
**What goes wrong:** Phase 27's `_build_save_data()` wraps single items in arrays for save format. Phase 28 changes GameState to hold arrays, so build must iterate the actual arrays. Phase 27's `_restore_state()` extracts first item from array. Phase 28 must populate full arrays instead.
**How to avoid:** Update both `_build_save_data()` and `_restore_state()` in the same task.

### Pitfall 5: is_item_better Used by Stat Comparison
**What goes wrong:** Deleting `is_item_better()` entirely breaks stat comparison display.
**How to avoid:** Only remove the call in `add_item_to_inventory()`. Keep the function definition -- it is used by stat comparison display (ForgeView `get_stat_comparison_text()` doesn't call it, but it may be used in Phase 29 for bench selection). The function body references single items, which is fine since stat comparison always compares two specific items.

## Code Examples

### GameState crafting_inventory initialization (target)
```gdscript
crafting_inventory = {
    "weapon": [],
    "helmet": [],
    "armor": [],
    "boots": [],
    "ring": [],
}
```

### add_item_to_inventory (target)
```gdscript
func add_item_to_inventory(item: Item) -> void:
    var item_type: String = get_item_type(item)
    if item_type == "None":
        print("Unknown item type for: ", item.item_name)
        return
    var slot_array: Array = GameState.crafting_inventory[item_type]
    if slot_array.size() >= 10:
        print("Slot ", item_type, " is full (10/10), discarding ", item.item_name)
        return
    slot_array.append(item)
    print("Added ", item.item_name, " to ", item_type, " slot (", slot_array.size(), "/10)")
    update_inventory_display()
```

### SaveManager._restore_state (target)
```gdscript
# Restore crafting inventory (v2: arrays in save, arrays in GameState)
var saved_crafting: Dictionary = data.get("crafting_inventory", {})
for slot_name in ["weapon", "helmet", "armor", "boots", "ring"]:
    var slot_data = saved_crafting.get(slot_name, [])
    var items_array: Array = []
    if slot_data is Array:
        for item_data in slot_data:
            if item_data is Dictionary:
                var item = Item.create_from_dict(item_data)
                if item != null:
                    items_array.append(item)
    GameState.crafting_inventory[slot_name] = items_array
```

### SaveManager._build_save_data (target)
```gdscript
var crafting_inv := {}
for type_name in GameState.crafting_inventory:
    var slot_array: Array = GameState.crafting_inventory[type_name]
    var items_data: Array = []
    for item in slot_array:
        items_data.append(item.to_dict())
    crafting_inv[type_name] = items_data
```

## File Modification Map

| File | Changes | Lines Affected |
|------|---------|---------------|
| `autoloads/game_state.gd` | Remove `crafting_bench_item`, change inventory init to arrays | ~5 lines |
| `autoloads/save_manager.gd` | Update `_build_save_data` and `_restore_state` for array model | ~20 lines |
| `scenes/forge_view.gd` | Update `add_item_to_inventory`, remove `is_item_better` call, update 12 consumer sites | ~40 lines |

**Total estimated scope:** ~65 lines modified across 3 files.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `autoloads/game_state.gd`, `autoloads/save_manager.gd`, `scenes/forge_view.gd`
- Phase 27 SUMMARY and VERIFICATION for bridge pattern details
- Phase 28 CONTEXT.md for locked implementation decisions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- pure GDScript, no new dependencies
- Architecture: HIGH -- direct codebase inspection, all patterns visible
- Pitfalls: HIGH -- exhaustive grep of all call sites, every consumer identified

**Research date:** 2026-02-18
**Valid until:** N/A (internal codebase patterns, not external libraries)
