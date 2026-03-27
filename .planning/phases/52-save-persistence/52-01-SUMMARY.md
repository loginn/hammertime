---
phase: 52-save-persistence
plan: 01
subsystem: save
tags: [gdscript, godot, save-format, serialization, hero-archetype]

# Dependency graph
requires:
  - phase: 51-stat-integration
    provides: hero_archetype field on GameState, HeroArchetype.from_id() deserialization
  - phase: 36-save-format-v3
    provides: existing save pipeline (_build_save_data, _restore_state, import_save_string, version policy)
provides:
  - Save format v8 with hero_archetype_id field in build/restore pipeline
  - Strict import version rejection (outdated_version error for pre-v8 strings)
  - _wipe_run_state() nulls hero_archetype to force re-selection on prestige
  - Group 38 integration tests covering all 6 save persistence truths
affects: [53-archetype-selection-ui, 54-stat-display]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Save field pattern: GameState.field -> data[key] with .get() default (null for archetype)"
    - "Strict import versioning: reject import_version < SAVE_VERSION with outdated_version error"
    - "Prestige wipe pattern: run-scoped state nulled in _wipe_run_state(), prestige state preserved"

key-files:
  created: []
  modified:
    - autoloads/save_manager.gd
    - autoloads/game_state.gd
    - tools/test/integration_test.gd

key-decisions:
  - "SAVE_VERSION bumped 7 to 8; delete-on-old-version policy handles v7 files automatically"
  - "hero_archetype_id written as string ID or null; HeroArchetype.from_id() used for restore"
  - "Import strings with version < SAVE_VERSION now return outdated_version (no backward compat until alpha)"
  - "hero_archetype is run-scoped: wiped in _wipe_run_state() to force re-selection each prestige"

patterns-established:
  - "v8 save field: hero_archetype.id (string) or null written; from_id() restores on load"
  - "Strict import rejection replaces lenient old-version acceptance"

requirements-completed: [SAVE-01]

# Metrics
duration: 8min
completed: 2026-03-27
---

# Phase 52 Plan 01: Save Persistence Summary

**Save format bumped to v8 with hero_archetype_id round-trip, strict import version rejection, and prestige wipe nulling hero_archetype**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-27T08:44:22Z
- **Completed:** 2026-03-27T08:52:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Bumped SAVE_VERSION from 7 to 8; added hero_archetype_id to build/restore pipeline
- Replaced lenient old-version import handling with strict outdated_version rejection
- Added `hero_archetype = null` to _wipe_run_state() so prestige forces re-selection
- Added Group 38 with 12 integration tests covering all 6 must-have save persistence truths

## Task Commits

Each task was committed atomically:

1. **Task 1: Save format v8** - `9eb5473` (feat)
2. **Task 2: Group 38 integration tests** - `6a9efa8` (test)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `autoloads/save_manager.gd` - SAVE_VERSION=8, hero_archetype_id in build/restore, strict import rejection
- `autoloads/game_state.gd` - hero_archetype = null in _wipe_run_state()
- `tools/test/integration_test.gd` - Group 38 save persistence tests (12 assertions)

## Decisions Made
- Import strings with version < 8 now return `{success: false, error: "outdated_version"}` — no backward compatibility until first alpha release (replaces old lenient behavior that accepted old versions silently)
- hero_archetype_id written as the string ID (e.g., `"str_hit"`) or `null` for classless Adventurer — matches existing GameState null-means-classless convention
- hero_archetype is run-scoped (wiped on prestige) per D-07; prestige_level and max_item_tier_unlocked remain preserved

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Save persistence complete: hero_archetype survives save/load cycles, old saves reset cleanly, prestige forces re-selection
- Phase 53 (archetype selection UI) can detect null hero_archetype post-prestige and show selection overlay
- Phase 53 may want to add a hero_selected auto-save trigger when wiring the UI

---
*Phase: 52-save-persistence*
*Completed: 2026-03-27*

## Self-Check: PASSED

- autoloads/save_manager.gd: FOUND
- autoloads/game_state.gd: FOUND
- tools/test/integration_test.gd: FOUND
- .planning/phases/52-save-persistence/52-01-SUMMARY.md: FOUND
- Commit 9eb5473 (Task 1): FOUND
- Commit 6a9efa8 (Task 2): FOUND
