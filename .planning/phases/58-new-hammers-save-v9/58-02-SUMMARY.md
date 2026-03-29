---
phase: 58-new-hammers-save-v9
plan: 02
subsystem: save
tags: [gdscript, save-format, serialization, integration-testing]

# Dependency graph
requires:
  - phase: 58-new-hammers-save-v9/58-01
    provides: New hammer types (TackHammer/GrandHammer rewrite) and stash/bench GameState model
  - phase: 57-stash-ui
    provides: stash Dictionary and crafting_bench Item fields on GameState
provides:
  - Save format v9 serializing stash item arrays and crafting bench item directly
  - _serialize_stash() helper preserving null gaps
  - v8 compat shims removed from game_state.gd
  - Integration test group 50 verifying full v9 round-trip
affects:
  - save-manager
  - game-state
  - integration-testing

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Null-gap preserving array serialization — stash arrays serialize null slots explicitly to maintain bench-removal gaps"
    - "Version-strict rejection — saves below SAVE_VERSION are deleted and game starts fresh, no migration"

key-files:
  created: []
  modified:
    - autoloads/save_manager.gd
    - autoloads/game_state.gd
    - tools/test/integration_test.gd

key-decisions:
  - "v8 saves strictly rejected on load (delete + fresh start) — consistent with existing no-migration policy"
  - "v8 import strings return outdated_version error — same as existing import rejection path"
  - "Test group uses _build_save_data()/_restore_state() directly to avoid file I/O in integration tests"

patterns-established:
  - "Null-gap serialization: stash slots serialize null entries as JSON null to preserve tap-to-bench gaps on reload"

requirements-completed:
  - CRFT-03

# Metrics
duration: 15min
completed: 2026-03-29
---

# Phase 58 Plan 02: Save v9 — Stash/Bench Serialization Summary

**Save format bumped to v9 with direct stash array and crafting bench serialization, v8 compat shims removed from game_state.gd, and integration test group 50 verifying full round-trip.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-29T00:45:00Z
- **Completed:** 2026-03-29T01:00:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- SAVE_VERSION bumped from 8 to 9; `_build_save_data()` now saves `stash` (via `_serialize_stash()`) and `crafting_bench` directly
- Removed old `crafting_inventory` and `crafting_bench_type` keys from save dict
- Added `_serialize_stash()` helper that preserves null gaps left by tap-to-bench
- `_restore_state()` restores stash arrays with null-gap preservation and the crafting bench item
- Removed v8 compat shims (`crafting_inventory` and `crafting_bench_type` computed properties) from game_state.gd
- Integration test group 50 verifies stash/bench/currencies/archetype round-trip through `_build_save_data()` + `_restore_state()`

## Task Commits

Each task was committed atomically:

1. **Task 1: Save v9 format — stash/bench serialization + shim removal** - `7e69053` (feat)
2. **Task 2: Integration test group 50 — save v9 round-trip** - `74c53dd` (test)

**Plan metadata:** (docs commit — see final_commit)

## Files Created/Modified
- `autoloads/save_manager.gd` - SAVE_VERSION=9, _build_save_data serializes stash+bench, _serialize_stash() helper, _restore_state() restores stash arrays and bench
- `autoloads/game_state.gd` - v8 compat shims (crafting_inventory, crafting_bench_type computed properties) removed
- `tools/test/integration_test.gd` - Group 50 added; group 35/38 SAVE_VERSION hardcoded checks updated

## Decisions Made
- Test group 50 uses `_build_save_data()` + `_restore_state()` directly (no file I/O in tests) — consistent with existing test style in groups 38 and earlier.
- v8 rejection tested via inline version comparison rather than file writes — keeps test hermetic.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated stale SAVE_VERSION hardcoded checks in group 35 and group 38**
- **Found during:** Task 2 (integration test group 50)
- **Issue:** Group 35 asserted `SAVE_VERSION == 7` and group 38 asserted `== 8`; both would now fail after version bump to 9
- **Fix:** Group 35 changed to `>= 7`; group 38 changed to `== 9`
- **Files modified:** tools/test/integration_test.gd
- **Verification:** Grep confirms updated assertions
- **Committed in:** 74c53dd (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** Necessary to keep existing tests passing after SAVE_VERSION bump. No scope creep.

## Issues Encountered
- Worktree was behind master (Plan 01 commits not yet in branch). Resolved via `git rebase master` before starting execution.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Save v9 is complete. All new state (stash, bench, alteration/regal currencies, hero archetype) survives save/load and export/import.
- CRFT-03 requirement satisfied.
- Phase 58 is now fully complete (Plan 01: new hammer behaviors; Plan 02: save persistence).

---
*Phase: 58-new-hammers-save-v9*
*Completed: 2026-03-29*

## Self-Check: PASSED

All files verified present, all commits verified in git history:
- FOUND: autoloads/save_manager.gd
- FOUND: autoloads/game_state.gd
- FOUND: tools/test/integration_test.gd
- FOUND: .planning/phases/58-new-hammers-save-v9/58-02-SUMMARY.md
- FOUND: commit 7e69053 (Task 1)
- FOUND: commit 74c53dd (Task 2)
