# Phase 30: Display and Counter - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Add x/10 fill counter to each slot button label (Weapon, Helmet, Armor, Boots, Ring) showing the current array size. Update the counter on every inventory mutation (drop, melt, equip). Disable slot buttons with zero items; enable buttons with items. Currency-only pack kills must not trigger counter updates (they don't mutate arrays).

Phase 29 completed bench selection and melt/equip auto-select. Phase 30 is the final display polish phase for v1.5. Scope is limited to button label format and disabled state -- no new features, no inventory browsing, no notifications.

</domain>

<decisions>
## Implementation Decisions

### Button label format
- Format: "SlotName (N/10)" where N is `GameState.crafting_inventory[slot_name].size()`
- Examples: "Weapon (3/10)", "Helmet (0/10)", "Ring (10/10)"
- The label updates use the existing `update_inventory_display()` function (or a new dedicated function)

### Button disabled state
- A slot button with 0 items is `disabled = true` (grayed out, not clickable)
- A slot button with 1+ items is `disabled = false`
- The currently selected slot button should still show as selected (pressed state) even if it becomes empty after melt
- If all slots are empty, all buttons are disabled and bench shows "No item"

### Counter update triggers
- `add_item_to_inventory()` already calls `update_inventory_display()` -- counter updates on drop
- `_on_melt_pressed()` already calls `update_inventory_display()` -- counter updates on melt
- `_on_equip_pressed()` already calls `update_inventory_display()` -- counter updates on equip
- `on_currencies_found()` calls `update_inventory_display()` but does NOT mutate arrays -- this is fine, the counter will just re-read the same values
- No additional signal wiring needed -- existing call sites already cover all mutations

### Where to put the update logic
- Create a new `update_slot_button_labels()` function that iterates all 5 slot buttons and sets text + disabled state
- Call it from `update_inventory_display()` so it stays in sync with the inventory label
- Also call it from `_ready()` to set initial state

### Claude's Discretion
- Whether to combine slot button label + disabled state in one function or separate them
- Whether to create a button_map dictionary as a class variable or rebuild it each call
- Exact positioning of the new function in the file

</decisions>

<specifics>
## Specific Ideas

- From STATE.md: "x/10 counter display uses existing `inventory_label` Label node (not ItemList) -- minimal scope"
- The slot buttons are: weapon_type_btn, helmet_type_btn, armor_type_btn, boots_type_btn, ring_type_btn
- Current button text is just "Weapon", "Helmet", etc. (set in .tscn scene file)
- `update_item_type_button_states()` already iterates the button_map and sets `button_pressed` state -- can use same pattern
- `_on_item_type_selected()` already guards against empty slots with `.is_empty()` check at line 268

</specifics>

<deferred>
## Deferred Ideas

None -- phase scope is well-defined by roadmap success criteria

</deferred>

---

*Phase: 30-display-and-counter*
*Context gathered: 2026-02-19*
