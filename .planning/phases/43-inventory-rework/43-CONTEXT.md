# Phase 43: Inventory Rework - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace 10-item-per-slot inventory arrays with single-bench-per-slot model. Each of the 5 equipment slots (weapon, helmet, armor, boots, ring) holds max 1 item on its crafting bench. Drops are silently discarded when bench is occupied. Save format simplified accordingly.

</domain>

<decisions>
## Implementation Decisions

### Drop Discard Behavior
- Silent discard when bench for that slot is occupied (no toast, no feedback)
- Only the matching slot's bench is checked (weapon drops check weapon bench only)
- Multi-item drops (1-3 per map clear) are independent per-item: each checks its own slot
- No gameplay view indicator for full benches -- player sees bench status in Forge tab

### Bench Empty State
- Item stats panel shows "No item on bench" when slot is empty
- Slot tab buttons show just the slot name ("Weapon", "Helmet", etc.) -- no counts since max is 1
- Empty bench slots are disabled (greyed out, unclickable)
- Starter weapon (LightSword) remains on weapon bench for fresh games

### Melt Button
- Melt destroys the item and clears the bench, opening the slot for new drops
- Button label stays "Melt" (no rename to Discard)
- Two-click confirmation with 3-second timer reset (matches equip confirmation pattern)
- Equip also clears bench after moving item to hero (existing behavior preserved)

### Save Format
- Bump save version to v5 (breaking change in this phase, not deferred to Phase 49)
- Old v4 saves are wiped on load (fresh game starts) -- matches project policy
- Save stores null explicitly for empty bench slots: `crafting_inventory: {weapon: {...}, helmet: null, ...}`
- Single item dict per slot replaces arrays

### Claude's Discretion
- Internal refactoring approach (whether to change GameState.crafting_inventory type from Dictionary of Arrays to Dictionary of nullable Items, or keep Arrays with size-1 cap)
- `get_best_item()` removal or simplification (with only 1 item per slot, "best item" selection is trivial)
- Cleanup of inventory display code (update_inventory_display, update_slot_button_labels)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ForgeView.add_item_to_inventory()` (forge_view.gd:532): Single entry point for all drops. Change cap from 10 to 1.
- `ForgeView.update_slot_button_labels()` (forge_view.gd:383): Currently shows "Slot (N/10)". Simplify to just slot name.
- `ForgeView._on_equip_pressed()` (forge_view.gd:474): Already clears bench after equip. Keep this behavior.
- Equip two-click confirmation pattern (equip_timer, equip_confirm_pending): Reuse for melt confirmation.

### Established Patterns
- `GameState.crafting_inventory` is Dictionary with slot keys mapping to Arrays (game_state.gd:9,69-75)
- `SaveManager` serializes inventory as dict of arrays (save_manager.gd:92-104)
- `ForgeView.get_best_item()` selects highest-tier item from array (forge_view.gd:581)
- Drop flow: gameplay_view emits `item_base_found` -> main_view routes to forge_view.set_new_item_base -> add_item_to_inventory

### Integration Points
- `GameState.crafting_inventory` structure change affects: SaveManager, ForgeView, PrestigeManager (_wipe_run_state)
- `GameState.initialize_fresh_game()` and `_wipe_run_state()` both initialize inventory (game_state.gd:68-77, 108-117)
- `main_view.gd:40` connects item drop signal to forge_view
- Save version constant in save_manager.gd needs bump from 4 to 5

</code_context>

<specifics>
## Specific Ideas

No specific requirements -- straightforward simplification of existing inventory system from arrays to single items.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 43-inventory-rework*
*Context gathered: 2026-03-06*
