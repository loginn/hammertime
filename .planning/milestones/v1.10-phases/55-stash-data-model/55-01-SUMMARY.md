---
phase: 55-stash-data-model
plan: 01
subsystem: game-state
tags: [gdscript, game-state, stash, data-model, integration-tests]

# Dependency graph
requires:
  - phase: 54-polish-balance
    provides: hero archetype UI polish and ForgeView stat panel with null archetype support
provides:
  - GameState.stash dictionary with 5-key slot arrays (3-item cap per slot)
  - GameState.crafting_bench single universal bench field
  - GameState.add_item_to_stash() with silent overflow discard and stash_updated signal
  - GameEvents.stash_updated(slot) signal
  - v8 save_manager compat shims for crafting_inventory and crafting_bench_type
  - Integration tests group_40 (STSH-01) and group_41 (STSH-04)
affects: [56-starter-item, 57-stash-ui, 58-save-persistence, forge-view, loot-table]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Compat property shim pattern: computed property with get/set for backward compatibility with old save format"
    - "Stash slot routing via GDScript type checks (item is Weapon, item is Helmet, etc.)"

key-files:
  created: []
  modified:
    - autoloads/game_state.gd
    - autoloads/game_events.gd
    - tools/test/integration_test.gd

key-decisions:
  - "crafting_inventory and crafting_bench_type kept as property shims (computed properties) for v8 save_manager compat — real removal deferred to Phase 58"
  - "initialize_fresh_game() and _wipe_run_state() no longer create Broadsword.new(8) starter weapon — Phase 56 handles starter items"
  - "Stash overflow is silently discarded (no toast/warning) per D-03 design decision"

patterns-established:
  - "Compat shim pattern: var crafting_inventory: Dictionary with get/set allows save_manager v8 to work without modification"

requirements-completed: [STSH-01, STSH-04]

# Metrics
duration: 5min
completed: 2026-03-28
---

# Phase 55 Plan 01: Stash Data Model Summary

**GameState stash dict (5 slots, 3-item Array cap), single crafting_bench, add_item_to_stash() with silent overflow, stash_updated signal, and v8 save compat shims**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-28T11:47:00Z
- **Completed:** 2026-03-28T11:47:47Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Replaced crafting_inventory dict and crafting_bench_type string with stash dict (5 keys, Array per slot) and crafting_bench (single Item or null)
- Added add_item_to_stash() with 3-cap enforcement, silent overflow discard, and stash_updated signal emission
- Added v8 save_manager compat shims (computed properties) so save/load continues working until Phase 58
- Added 79-line integration test covering STSH-01 (structure, fresh game, prestige wipe) and STSH-04 (routing, overflow, slot isolation)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add stash data model to GameState and stash_updated signal to GameEvents** - `4f2ef83` (feat)
2. **Task 2: Add integration tests for stash data model (group_40) and drop routing (group_41)** - `3d731ab` (test)

## Files Created/Modified
- `autoloads/game_state.gd` - Replaced crafting_inventory/bench_type with stash dict + crafting_bench; added _init_stash(), add_item_to_stash(), _get_slot_for_item(); added v8 compat shims
- `autoloads/game_events.gd` - Added signal stash_updated(slot: String)
- `tools/test/integration_test.gd` - Added group_40 and group_41 test functions and _ready() calls

## Decisions Made
- Kept crafting_inventory and crafting_bench_type as computed property shims (not plain vars) — allows save_manager.gd to continue functioning for v8 saves without modification. Phase 58 removes these shims when bumping to v9.
- Removed Broadsword.new(8) starter weapon from both initialize_fresh_game() and _wipe_run_state() — per plan spec (D-05/D-06); Phase 56 handles starter item provisioning.
- Overflow discard is silent (no push_warning to player) per D-03 — push_warning to engine log is omitted as stash full is a normal game condition, not an error.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Stash data model complete; GameState ready for Phase 56 (starter item provisioning)
- Phase 57 (stash UI) can reference GameState.stash and add_item_to_stash() as defined
- Phase 58 (save v9) needs to: remove compat shims, add stash[] serialization, bump SAVE_VERSION to 9
- Integration tests are runnable in Godot editor (F6 on integration_test.gd) — no Godot automation available in this environment

---
*Phase: 55-stash-data-model*
*Completed: 2026-03-28*
