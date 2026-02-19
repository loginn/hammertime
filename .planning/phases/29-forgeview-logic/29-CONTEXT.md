# Phase 29: ForgeView Logic - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement bench selection logic in ForgeView that picks the highest-tier item from the selected slot array (highest DPS for weapon/ring, highest tier for armor slots). Update melt to remove the bench item from the slot array and auto-load the next-best item. Update equip to move the bench item to the hero's equipment slot (old equipped item deleted, not returned). Ensure the bench item remains in the slot array while being crafted (hammers modify in-place). Reset equip confirmation state when navigating to a different slot.

Phase 28 already converted ForgeView to array access (`[0]` for first item). Phase 29 replaces `[0]` with "best item" selection using the existing `is_item_better()` comparison. Display changes (x/10 counter) belong to Phase 30.

</domain>

<decisions>
## Implementation Decisions

### Bench selection logic
- Use existing `is_item_better()` function to determine "best" item in a slot array
- Weapon/ring: highest DPS is best (already implemented in `is_item_better`)
- Armor/helmet/boots: highest tier is best (already implemented in `is_item_better`)
- Create a `get_best_item(slot_name)` helper that iterates the slot array and returns the item that beats all others via `is_item_better()`
- Replace all `crafting_inventory[slot][0]` reads with `get_best_item(slot)` calls
- Tie-breaking: if two items are equal, keep the first one found (stable selection)

### Bench item persistence during crafting
- The bench item (`current_item`) is a reference to an item IN the slot array, not a copy
- When a hammer is applied to `current_item`, it modifies the item in-place -- the array slot updates automatically because GDScript objects are reference types
- No special persistence logic needed -- this is how GDScript already works with Resource objects
- The bench item is NOT removed from the array during crafting; only melt and equip remove it

### Melt flow
- Melting removes the bench item from the slot array (Phase 28 already does `slot_array.remove_at(idx)`)
- After removal, auto-select the next-best item from the same slot using `get_best_item(slot_name)`
- If the slot is now empty after melt, set `current_item = null` and update displays (bench shows "No item")
- Do NOT auto-switch to a different slot type after melting -- stay on the same slot type

### Equip flow
- Equipping removes the bench item from the slot array (Phase 28 already does this)
- The old equipped item in the hero's equipment slot is deleted (not returned to inventory) -- `hero.equip_item()` already handles this
- After equipping, auto-select the next-best item from the same slot using `get_best_item(slot_name)`
- If the slot is now empty after equip, set `current_item = null` and update displays
- Equip confirmation state (`equip_confirm_pending`) resets when navigating to a different slot type (already partially implemented via `_on_item_type_selected`)

### Equip confirmation reset on slot navigation
- `_on_item_type_selected()` already resets `equip_confirm_pending = false` and stops the timer
- Verify this works correctly with the new bench selection logic -- no additional work expected

### Claude's Discretion
- Whether `get_best_item()` lives on ForgeView or as a static helper
- How to handle the edge case where `current_item` is being crafted (rarity upgraded) and is no longer the "best" -- likely irrelevant since bench always shows the item you're working on
- Whether to add a `_select_best_after_removal(slot_name)` convenience method or inline the logic in melt/equip

</decisions>

<specifics>
## Specific Ideas

- From Phase 28 SUMMARY: "is_item_better() function available for Phase 29 to use in bench selection"
- The `is_item_better(new, existing)` function at forge_view.gd:468 already implements DPS comparison for weapon/ring and tier comparison for armor slots -- reuse directly
- Phase 28 left `[0]` (first item) as the bench selection; Phase 29 replaces this with best-item selection
- The signal chain for item drops (combat -> forge_view.add_item_to_inventory) doesn't need changes -- items accumulate in arrays, bench selection just picks the best one to display
- `_ready()` bench initialization (lines 144-156) and `update_current_item()` (lines 300-310) are the primary sites to update for best-item selection

</specifics>

<deferred>
## Deferred Ideas

None -- phase scope is well-defined by roadmap success criteria

</deferred>

---

*Phase: 29-forgeview-logic*
*Context gathered: 2026-02-19*
