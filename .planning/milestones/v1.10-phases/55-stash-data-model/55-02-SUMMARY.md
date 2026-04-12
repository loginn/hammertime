---
phase: 55-stash-data-model
plan: 02
subsystem: ui
tags: [gdscript, forge-view, main-view, stash, crafting-bench, signal-wiring]

# Dependency graph
requires:
  - phase: 55-stash-data-model/55-01
    provides: GameState.stash dict, GameState.crafting_bench, GameState.add_item_to_stash(), v8 compat shims
provides:
  - MainView wires item_base_found to GameState.add_item_to_stash (drops go to stash)
  - ForgeView reads/writes GameState.crafting_bench (single universal bench)
  - ItemTypeButtons hidden and disabled (Phase 57 repurpose)
  - Dead code stubs for add_item_to_inventory and set_new_item_base
affects: [56-starter-item, 57-stash-ui, 58-save-persistence]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "No-op stub pattern: dead code methods kept as stubs with push_warning for traceability"
    - "Single universal bench: ForgeView reads GameState.crafting_bench directly, no slot selection"

key-files:
  created: []
  modified:
    - scenes/main_view.gd
    - scenes/forge_view.gd

key-decisions:
  - "ItemTypeButtons hidden (visible=false) not removed — Phase 57 will repurpose them as stash navigation"
  - "add_item_to_inventory and set_new_item_base kept as stubs with push_warning — dead code, but retained for Phase 57 potential reuse"
  - "update_inventory_display simplified to 'Bench: ItemName (Rarity)' or 'Bench: Empty' — full stash display is Phase 57 scope"

patterns-established:
  - "Dead code stub pattern: keep function signature, replace body with push_warning explaining correct path"

requirements-completed: [STSH-01, STSH-04]

# Metrics
duration: 8min
completed: 2026-03-28
---

# Phase 55 Plan 02: ForgeView and MainView Consumer Migration Summary

**ForgeView migrated to single universal bench (GameState.crafting_bench), MainView drops re-wired to GameState.add_item_to_stash, ItemTypeButtons hidden**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-28T12:50:00Z
- **Completed:** 2026-03-28T12:58:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Re-wired MainView `item_base_found` signal from `forge_view.set_new_item_base` to `GameState.add_item_to_stash` — drops now route directly to stash
- Replaced all `GameState.crafting_inventory` and `GameState.crafting_bench_type` references in forge_view.gd with `GameState.crafting_bench`
- Hidden and disabled all five ItemTypeButtons (weapon/helmet/armor/boots/ring) in ForgeView — bench no longer requires type selection
- Stubbed dead code methods (`add_item_to_inventory`, `set_new_item_base`) with `push_warning` for traceability
- Simplified `update_inventory_display` to show single bench item: "Bench: ItemName (Rarity)" or "Bench: Empty"
- Made `_on_item_type_selected`, `update_item_type_button_states`, `update_slot_button_labels` no-op stubs

## Task Commits

Each task was committed atomically:

1. **Task 1: Re-wire MainView drop signal to GameState.add_item_to_stash** - `db762c7` (feat)
2. **Task 2: Adapt ForgeView to single universal bench model** - `3926666` (feat)

## Files Created/Modified
- `scenes/main_view.gd` - Re-wired gameplay_view.item_base_found from forge_view.set_new_item_base to GameState.add_item_to_stash
- `scenes/forge_view.gd` - Replaced all crafting_inventory/crafting_bench_type refs with crafting_bench; hidden ItemTypeButtons; stubbed dead code; simplified inventory display

## Decisions Made
- ItemTypeButtons hidden (visible=false + disabled=true) but not removed — Phase 57 will repurpose them as stash slot navigation
- Dead code functions kept as push_warning stubs rather than deleted — easier to trace if called unexpectedly, and Phase 57 may reuse the pattern
- inventory_label display simplified to single bench item only — full stash display (all 5 slots with 3-item arrays) is Phase 57 scope per plan spec

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

This worktree was behind master and missing the Plan 01 changes (game_state.gd API). A `git merge master` was performed before execution to bring in commits `4f2ef83`, `3d731ab`, `325128a` from Plan 01. This is expected parallel agent behavior — not a plan deviation.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 55 complete: stash data model (Plan 01) and consumer migration (Plan 02) both done
- Phase 56 (starter item): GameState.crafting_bench starts null — Phase 56 provisions starter item onto bench
- Phase 57 (stash UI): Can now build stash slot navigation using ItemTypeButtons (already hidden, ready for repurpose) and GameState.stash
- Phase 58 (save v9): Compat shims in game_state.gd can be removed when bumping to v9; stash[] serialization needed

## Self-Check: PASSED
- 55-02-SUMMARY.md: FOUND
- scenes/main_view.gd: FOUND
- scenes/forge_view.gd: FOUND
- Commit db762c7: FOUND
- Commit 3926666: FOUND

---
*Phase: 55-stash-data-model*
*Completed: 2026-03-28*
