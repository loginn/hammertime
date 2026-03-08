---
phase: 43
plan: 01
status: complete
started: 2026-03-06
completed: 2026-03-06
---

# Plan 43-01 Summary: Single-bench-per-slot inventory rework

## What Was Built
Replaced the 10-item-per-slot array inventory model with a single nullable Item per crafting bench slot. Each of the 5 equipment slots (weapon, helmet, armor, boots, ring) now holds at most 1 item. Drops are silently discarded when the target bench is occupied. Save format was bumped to v5 with single item dicts instead of arrays. Melt gained a two-click confirmation matching the existing equip confirmation pattern.

## Tasks Completed
| # | Task | Status |
|---|------|--------|
| 1 | Convert GameState crafting_inventory from arrays to nullable Items | complete |
| 2 | Bump save version to 5 and update serialization for single-item slots | complete |
| 3 | Add melt two-click confirmation state and timer to ForgeView | complete |
| 4 | Rewrite _on_melt_pressed for single-item bench with two-click confirmation | complete |
| 5 | Rewrite _on_equip_pressed to use nullable item instead of array | complete |
| 6 | Rewrite add_item_to_inventory for single-bench model with silent discard | complete |
| 7 | Simplify get_best_item to return single bench item | complete |
| 8 | Update _ready inventory loading for nullable items | complete |
| 9 | Update _on_item_type_selected for nullable items | complete |
| 10 | Update update_current_item for nullable items | complete |
| 11 | Update update_slot_button_labels for single-item display | complete |
| 12 | Update update_inventory_display for single-item bench | complete |
| 13 | Update update_item_stats_display empty text | complete |
| 14 | Reset melt confirmation on currency selection | complete |
| 15 | Update integration test assertions for single-item inventory | complete |

## Key Files
### Modified
- autoloads/game_state.gd — crafting_inventory now stores nullable Items (not Arrays); both initialize_fresh_game() and _wipe_run_state() updated
- autoloads/save_manager.gd — SAVE_VERSION bumped to 5; serialization/deserialization uses single item dict or null per slot
- scenes/forge_view.gd — all array operations replaced with null checks; melt two-click confirmation added; slot buttons show name only; empty text says "Empty"/"No item on bench"
- tools/test/integration_test.gd — all crafting_inventory assertions use direct dictionary access (no array indexing)

## Decisions Made
- Melt confirmation resets are propagated to currency selection, equip execution, and item type switching to prevent stale confirmation state across UI interactions.

## Self-Check
- [x] GameState.crafting_inventory stores nullable Items (not Arrays) for all 5 slots
- [x] Both initialize_fresh_game() and _wipe_run_state() produce identical bench structure with LightSword on weapon bench and null for other slots
- [x] SaveManager version is 5; save format stores single item dict or null per slot (no arrays)
- [x] SaveManager._restore_state() reads single item dict or null per slot
- [x] add_item_to_inventory() silently discards drops when bench is occupied (null check, not array size check)
- [x] Melt uses two-click confirmation with 3-second timer (melt_confirm_pending + melt_timer pattern)
- [x] Slot tab buttons show just the slot name (no counts) and are disabled when bench is null
- [x] Empty bench stats panel shows "No item on bench"
- [x] All integration test assertions use direct dictionary access (no array indexing)
- [x] get_best_item() returns the single bench item directly (no array iteration)

## Self-Check: PASSED
