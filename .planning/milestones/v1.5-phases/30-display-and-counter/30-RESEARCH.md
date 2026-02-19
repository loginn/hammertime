# Phase 30: Display and Counter - Research

**Researched:** 2026-02-19
**Domain:** GDScript ForgeView slot button labels and disabled state (internal codebase)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Button label format: "SlotName (N/10)" where N is array size
- Slot button with 0 items is disabled; 1+ items is enabled
- Counter updates on drop, melt, equip (already covered by existing update_inventory_display calls)
- Create `update_slot_button_labels()` function
- Call from `update_inventory_display()` and `_ready()`

### Claude's Discretion
- Whether to combine label + disabled state in one function or separate
- Whether to create button_map as class variable or rebuild each call
- Exact positioning of new function in file
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DISP-01 | Each slot shows an x/10 counter in the crafting view indicating fill level | `update_slot_button_labels()` sets text to "SlotName (N/10)" format |
</phase_requirements>

## Summary

Phase 30 adds x/10 fill counters to slot buttons and disables empty-slot buttons. The implementation is straightforward: one new function that iterates 5 buttons, sets their text and disabled state based on array sizes. The function is called from existing update points.

## Architecture Patterns

### Current Slot Button State

The 5 slot buttons are referenced as:
- `weapon_type_btn`, `helmet_type_btn`, `armor_type_btn`, `boots_type_btn`, `ring_type_btn`

Current text (from .tscn): "Weapon", "Helmet", "Armor", "Boots", "Ring"

`update_item_type_button_states()` at line 284 already iterates a button_map dictionary:
```gdscript
func update_item_type_button_states() -> void:
    var button_map: Dictionary = {
        "weapon": weapon_type_btn,
        "helmet": helmet_type_btn,
        "armor": armor_type_btn,
        "boots": boots_type_btn,
        "ring": ring_type_btn
    }
    for item_type in button_map.keys():
        button_map[item_type].button_pressed = (item_type == GameState.crafting_bench_type)
```

### Target Implementation

```gdscript
func update_slot_button_labels() -> void:
    var button_map: Dictionary = {
        "weapon": weapon_type_btn,
        "helmet": helmet_type_btn,
        "armor": armor_type_btn,
        "boots": boots_type_btn,
        "ring": ring_type_btn
    }
    for slot_name in button_map.keys():
        var btn: Button = button_map[slot_name]
        var count: int = GameState.crafting_inventory[slot_name].size()
        btn.text = slot_name.capitalize() + " (" + str(count) + "/10)"
        btn.disabled = (count == 0)
```

### Call Sites

All three mutation sites already call `update_inventory_display()`:
- `add_item_to_inventory()` line 444
- `_on_melt_pressed()` line 369
- `_on_equip_pressed()` line 412

Adding `update_slot_button_labels()` call inside `update_inventory_display()` ensures all mutations trigger counter updates.

`on_currencies_found()` at line 452 also calls `update_inventory_display()` but since it doesn't mutate arrays, the counters will just re-read existing values (harmless).

### _ready() initialization

`_ready()` already calls `update_inventory_display()` at line 159. If `update_slot_button_labels()` is called from within `update_inventory_display()`, the initial state is also handled.

### Edge Case: Disabled Button While Selected

If the user is on the weapon slot and melts the last weapon, the weapon button becomes disabled. The bench will show "No item" (current_item is null from get_best_item returning null). The button text changes to "Weapon (0/10)". The user can't re-click it (disabled). They must click a slot with items.

This is correct behavior per success criteria #4.

## Common Pitfalls

### Pitfall 1: Button pressed state vs disabled state
**What goes wrong:** A disabled button may not visually show as "pressed" in Godot. If the selected slot becomes empty, the button is disabled AND pressed -- this may look odd.
**How to avoid:** This is acceptable UX for now. The bench shows "No item" which is clear. The disabled state prevents re-clicking.

### Pitfall 2: on_currencies_found triggers counter update
**What goes wrong:** Currency-only kills call `update_inventory_display()` which would call `update_slot_button_labels()`. Per success criteria #3, "counter does not update during currency-only pack kills."
**How to avoid:** The counter DOES get called but the values don't change (no array mutation happened). The criteria says "does not update" meaning the displayed number shouldn't change -- it won't, because the arrays haven't changed. The function runs but produces the same output. This is fine.

## File Modification Map

| File | Changes | Lines Affected |
|------|---------|---------------|
| `scenes/forge_view.gd` | Add `update_slot_button_labels()`, call from `update_inventory_display()` | ~10 lines |

**Total estimated scope:** ~10 lines added in 1 file.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `scenes/forge_view.gd` (post-Phase 29)
- Phase 30 CONTEXT.md for locked decisions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- pure GDScript, no new dependencies
- Architecture: HIGH -- single file, all patterns visible
- Pitfalls: HIGH -- exhaustive review of all consumer sites

**Research date:** 2026-02-19
**Valid until:** N/A (internal codebase patterns)
