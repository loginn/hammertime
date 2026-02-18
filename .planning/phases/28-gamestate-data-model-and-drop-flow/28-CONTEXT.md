# Phase 28: GameState Data Model and Drop Flow - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Reshape `GameState.crafting_inventory` from single-item-per-slot (`{slot: Item|null}`) to per-slot arrays (`{slot: Array[Item]}`). Enforce a 10-item cap at the single add point (`add_item_to_inventory`). Remove the `is_item_better()` gate from the drop path so all items are kept until the slot is full. Remove the orphaned `crafting_bench_item` field from GameState and all call sites. Update `initialize_fresh_game()` to create the starter weapon in the weapon slot array. Update `SaveManager._restore_state()` to populate arrays into GameState (completing the Phase 27 bridge).

ForgeView UI changes (bench selection, melt from arrays, equip from arrays) belong to Phase 29. Display changes (x/10 counter) belong to Phase 30.

</domain>

<decisions>
## Implementation Decisions

### Inventory data model
- `GameState.crafting_inventory` changes from `Dictionary` of `Item|null` to `Dictionary` of `Array` (typed `Array[Item]` if GDScript supports it, plain `Array` otherwise)
- Every slot always has an array key — even empty slots are `[]`, never null
- Five canonical slots: `weapon`, `helmet`, `armor`, `boots`, `ring`

### Drop flow and capacity
- `add_item_to_inventory()` in `forge_view.gd` appends to the slot array instead of replacing
- If the array already has 10 items, the new item is silently discarded (not added, not logged to player)
- The `is_item_better()` guard is removed from the drop path entirely — all items are kept until slot is full
- `is_item_better()` function itself may remain in the file if used by stat comparison display; only the drop-path call is deleted

### Single add point
- All item additions to crafting_inventory go through `add_item_to_inventory()` — this is the single enforcement point for the 10-item cap
- The starter weapon in `initialize_fresh_game()` also uses this pattern (or directly initializes the array with the weapon)

### Starter weapon
- `initialize_fresh_game()` initializes all slots as empty arrays `[]`
- The weapon slot gets the starter weapon in the array: `crafting_inventory["weapon"] = [starter_weapon]`
- All other slots start as empty arrays

### crafting_bench_item removal
- Delete `var crafting_bench_item: Item = null` from `game_state.gd`
- Delete `crafting_bench_item = null` from `initialize_fresh_game()`
- Update all ForgeView references that read/write `GameState.crafting_bench_item` — replace with local variable or remove
- The bench item is now a ForgeView-local concept, not persisted in GameState

### SaveManager bridge completion
- `SaveManager._restore_state()` currently reads arrays from save and extracts first item (Phase 27 bridge)
- Phase 28 updates it to populate the full arrays into `GameState.crafting_inventory` (no more single-item extraction)
- `SaveManager._build_save_data()` already writes arrays — but now reads from actual arrays in GameState instead of wrapping single items

### ForgeView compatibility
- ForgeView reads `GameState.crafting_inventory[slot]` expecting `Item|null` in many places
- Phase 28 MUST update ForgeView to handle arrays: read `crafting_inventory[slot]` as `Array`, take first/best item for display
- The minimal compatibility approach: ForgeView reads `crafting_inventory[slot][0]` or checks `.is_empty()` where it previously checked `!= null`
- Full bench selection logic (picking highest-tier) belongs to Phase 29, but basic "show something" must work in Phase 28

### Claude's Discretion
- Whether to create a helper function like `get_best_item(slot)` on GameState or keep it in ForgeView
- Exact implementation of the starter weapon creation (inline in `initialize_fresh_game` or via `add_item_to_inventory`)
- Whether `add_item_to_inventory` returns a bool (added/discarded) or void
- Internal structure of ForgeView compatibility updates (minimal changes vs clean refactor)

</decisions>

<specifics>
## Specific Ideas

- From STATE.md: "`is_item_better()` guard must be deleted from the drop path (Phase 28); keep in stat comparison display"
- From STATE.md: "`crafting_bench_item` confirmed orphaned in GameState — remove entirely in Phase 28"
- Phase 27 already writes arrays to save and reads them back — Phase 28 completes the bridge by making GameState actually hold arrays
- The `item_base_found` signal chain (combat_engine -> gameplay_view -> forge_view.set_new_item_base -> add_item_to_inventory) is the drop path to modify

</specifics>

<deferred>
## Deferred Ideas

None — phase scope is well-defined by roadmap success criteria

</deferred>

---

*Phase: 28-gamestate-data-model-and-drop-flow*
*Context gathered: 2026-02-18*
