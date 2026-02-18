---
phase: 27-save-format-migration
plan: 01
subsystem: save-load
tags: [json, migration, save-format, godot]

requires:
  - phase: 18-save-load-foundation
    provides: SaveManager autoload with JSON save/load, build/restore pattern
provides:
  - v2 save format with per-slot inventory arrays
  - v1-to-v2 migration function
  - Orphaned crafting_bench_item stripped from save path
affects: [phase-28-gamestate-data-model, phase-29-forgeview-logic]

tech-stack:
  added: []
  patterns:
    - "Version-gated migration chain in _migrate_save()"
    - "Bridge pattern: save format (arrays) differs from runtime format (single items) during transition"

key-files:
  created: []
  modified:
    - autoloads/save_manager.gd

key-decisions:
  - "Kept GameState.crafting_inventory as single-item Dict during Phase 27 (bridge pattern) — Phase 28 converts to arrays"
  - "Used existing crafting_inventory key name for arrays rather than introducing new key"

patterns-established:
  - "Save migration chain: _migrate_save() routes through version-gated functions (_migrate_v1_to_v2, future _migrate_v2_to_v3)"

requirements-completed: [SAVE-01]

duration: 5min
completed: 2026-02-18
---

# Phase 27: Save Format Migration Summary

**Save format bumped to v2 with per-slot inventory arrays, v1 migration, and orphaned crafting_bench_item removal**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-18
- **Completed:** 2026-02-18
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- SAVE_VERSION bumped from 1 to 2
- `_migrate_v1_to_v2()` wraps single-item slots into 1-element arrays and strips orphaned `crafting_bench_item`
- `_build_save_data()` writes per-slot arrays (item present = `[item_dict]`, empty = `[]`)
- `_restore_state()` reads arrays from save, bridges to single-item GameState (first element or null)
- `crafting_bench_item` removed from save output and restore logic entirely
- Import/export path automatically uses v2 format via shared build/migrate/restore methods

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement v1-to-v2 migration and bump save version** - `b50299d` (feat)
2. **Task 2: Update _build_save_data and _restore_state for v2 array format** - `e6a0315` (feat)

## Files Created/Modified
- `autoloads/save_manager.gd` - v2 save format with migration, array build/restore, bench item removal

## Decisions Made
- Kept `GameState.crafting_inventory` as `Dictionary` of `Item|null` (not arrays) in Phase 27 — the save file stores arrays but `_restore_state()` bridges by extracting the first element. Phase 28 will convert GameState to hold arrays.
- Reused the existing `crafting_inventory` key name in the save format rather than introducing a new key name — the array shape is sufficient to distinguish v2 from v1.

## Deviations from Plan
None - plan executed exactly as written

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Save format is v2-ready for per-slot arrays (up to 10 items per slot)
- GameState still uses single-item model — Phase 28 will convert `crafting_inventory` to hold arrays and update all consumers
- `crafting_bench_item` field still exists in `game_state.gd` (line 10) — Phase 28 removes it from GameState and all ForgeView references

---
*Phase: 27-save-format-migration*
*Completed: 2026-02-18*
