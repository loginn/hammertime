# Phase 29: ForgeView Logic - Research

**Researched:** 2026-02-19
**Domain:** GDScript ForgeView bench selection and melt/equip flow (internal codebase)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use existing `is_item_better()` to determine "best" item in a slot array
- Create a `get_best_item(slot_name)` helper that iterates the slot array
- Replace all `crafting_inventory[slot][0]` reads with `get_best_item(slot)` calls
- Bench item is a reference to item IN array, not a copy (GDScript reference semantics)
- After melt: auto-select next-best item from same slot via `get_best_item(slot_name)`
- After equip: auto-select next-best item from same slot via `get_best_item(slot_name)`
- Do NOT auto-switch to different slot type after melt -- stay on same slot
- Old equipped item is deleted on equip (not returned to inventory)
- Equip confirmation resets on slot navigation (already partially implemented)

### Claude's Discretion
- Whether `get_best_item()` lives on ForgeView or as a static helper
- Whether to add `_select_best_after_removal(slot_name)` convenience method
- Edge case: current_item rarity changes mid-craft
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BENCH-01 | Clicking a slot button loads the highest-tier item onto bench | `get_best_item()` using `is_item_better()`, called from `_on_item_type_selected` and `_ready` |
| BENCH-02 | Crafting bench is a view into inventory -- item remains in array | GDScript Resource objects are reference types; `current_item` already points into array |
| INV-03 | Melt destroys bench item and removes from slot inventory | `_on_melt_pressed` already does `slot_array.remove_at(idx)`; add `get_best_item` for next selection |
| EQUIP-01 | Equipping moves bench item from inventory to hero equipment | `_on_equip_pressed` already does `slot_array.remove_at(idx)` + `hero.equip_item()`; add `get_best_item` for next |
| EQUIP-02 | Previously equipped item is deleted (not returned) | `hero.equip_item()` already overwrites; no return-to-inventory code exists |
</phase_requirements>

## Summary

Phase 29 is a focused refactor of ForgeView's item selection logic. Phase 28 already converted all inventory access to arrays using `[0]` as a placeholder. Phase 29 replaces `[0]` with intelligent "best item" selection via the existing `is_item_better()` comparison function, and adds auto-selection after melt/equip operations.

The scope is small: ~30 lines changed across 4-5 functions in a single file (`scenes/forge_view.gd`).

## Architecture Patterns

### Current State (Post-Phase 28)

All `[0]` access sites that need `get_best_item()` replacement:

| Location | Current Code | Phase 29 Target |
|----------|-------------|-----------------|
| `_ready()` line 147 | `crafting_inventory[selected_type][0]` | `get_best_item(selected_type)` |
| `_ready()` line 154 | `crafting_inventory[type_name][0]` | `get_best_item(type_name)` |
| `update_current_item()` line 301 | `crafting_inventory[selected_type][0]` | `get_best_item(selected_type)` |
| `update_inventory_display()` line 492 | `slot_array[0]` | `get_best_item(item_type)` or keep `[0]` (display only shows first, not best) |

### get_best_item() Implementation

```gdscript
func get_best_item(slot_name: String) -> Item:
    var slot_array: Array = GameState.crafting_inventory[slot_name]
    if slot_array.is_empty():
        return null
    var best: Item = slot_array[0]
    for i in range(1, slot_array.size()):
        if is_item_better(slot_array[i], best):
            best = slot_array[i]
    return best
```

### Melt Flow (Target)

```gdscript
func _on_melt_pressed() -> void:
    if current_item == null:
        return
    var slot_name: String = get_item_type(current_item)
    print("Melted: ", current_item.item_name)

    # Remove from slot array
    if slot_name != "None":
        var slot_array: Array = GameState.crafting_inventory[slot_name]
        var idx: int = slot_array.find(current_item)
        if idx >= 0:
            slot_array.remove_at(idx)

    # Auto-select next-best item from same slot
    current_item = get_best_item(slot_name) if slot_name != "None" else null

    # Reset equip confirm state
    equip_confirm_pending = false
    equip_timer.stop()
    equip_button.text = "Equip"

    update_item_stats_display()
    update_melt_equip_states()
    update_inventory_display()
```

### Equip Flow (Target)

```gdscript
# After equipping and removing from array:
current_item = get_best_item(slot_name) if slot_name != "None" else null
```

## Common Pitfalls

### Pitfall 1: update_inventory_display Shows Best vs First
**What goes wrong:** `update_inventory_display()` currently reads `slot_array[0]` for the display label. If we change this to `get_best_item()`, the display shows the best item's name, not the first. This is actually correct behavior (show best), but worth noting.
**How to avoid:** Use `get_best_item()` in display too, for consistency.

### Pitfall 2: Bench Item Identity After Crafting
**What goes wrong:** After applying a hammer, `current_item` may no longer be the "best" item in the slot (e.g., if Claw Hammer removes mods, reducing tier). But the user is actively crafting it -- switching away would be jarring.
**How to avoid:** Don't re-evaluate best item after hammer application. The bench always shows the item the user is working on. Re-evaluation only happens on explicit slot switch, melt, or equip.

### Pitfall 3: Equip Confirmation State
**What goes wrong:** If equip confirmation is pending and user switches slot, the confirmation should reset. This is already implemented in `_on_item_type_selected()` (line 262).
**How to avoid:** Verify existing reset code still works after `update_current_item()` now calls `get_best_item()`. No issue expected.

## File Modification Map

| File | Changes | Lines Affected |
|------|---------|---------------|
| `scenes/forge_view.gd` | Add `get_best_item()`, update 4 `[0]` sites, update melt/equip auto-selection | ~25 lines |

**Total estimated scope:** ~25 lines modified in 1 file.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `scenes/forge_view.gd` (post-Phase 28)
- Phase 28 SUMMARY for array access patterns
- Phase 29 CONTEXT.md for locked decisions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- pure GDScript, no new dependencies
- Architecture: HIGH -- single file, all patterns visible
- Pitfalls: HIGH -- exhaustive review of all consumer sites

**Research date:** 2026-02-19
**Valid until:** N/A (internal codebase patterns)
