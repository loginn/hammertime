---
phase: 56-difficulty-starter-kit
plan: 01
subsystem: ui
tags: [currency, naming, game_state, loot, prestige]

# Dependency graph
requires:
  - phase: 55-stash-data-model
    provides: GameState stash, crafting_bench, currency_counts
provides:
  - "All 6 currency dictionary keys renamed to PoE conventions (transmute/augment/alteration/regal/chaos/exalt)"
  - "Fresh game and prestige wipe give 2 transmute + 2 augment hammers"
affects: [57, 58, save-format, forge-view, prestige-view, loot-table]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Currency keys use PoE orb names (transmute/augment/alteration/regal/chaos/exalt) across all files"]

key-files:
  created: []
  modified:
    - autoloads/game_state.gd
    - autoloads/prestige_manager.gd
    - models/loot/loot_table.gd
    - scenes/forge_view.gd
    - scenes/prestige_view.gd
    - tools/test/integration_test.gd

key-decisions:
  - "Currency keys renamed to PoE conventions: runic->transmute, forge->augment, tack->alteration, grand->regal, claw->chaos, tuning->exalt (D-05)"
  - "Starter counts updated to 2 transmute + 2 augment replacing old 1 runic (D-04)"
  - "GDScript class names (RunicHammer, ForgeHammer, etc.) and asset filenames (runic_hammer.png) kept unchanged"
  - "main_view.gd forge view name strings are view identifiers, not currency keys — left untouched"

patterns-established:
  - "Currency key rename pattern: only dict string keys change, class names and asset paths are independent"

requirements-completed: [DIFF-03]

# Metrics
duration: 15min
completed: 2026-03-28
---

# Phase 56 Plan 01: Difficulty Starter Kit - Currency Key Rename Summary

**Renamed all 6 currency dictionary keys to PoE orb conventions and updated starter counts to 2 Transmute + 2 Augment across game_state, prestige_manager, loot_table, forge_view, prestige_view, and integration tests**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-28T00:00:00Z
- **Completed:** 2026-03-28T00:15:00Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments
- Renamed all 6 currency keys (runic→transmute, forge→augment, tack→alteration, grand→regal, claw→chaos, tuning→exalt) across all 6 affected files
- Updated starter currency counts from 1 runic to 2 transmute + 2 augment in both `initialize_fresh_game()` and `_wipe_run_state()`
- Prestige cost references updated from "forge" to "augment" in prestige_manager.gd and prestige_view.gd
- All asset preload paths kept pointing to original filenames (runic_hammer.png etc.) — icons unchanged
- GDScript class names (RunicHammer, ForgeHammer, TackHammer, GrandHammer, ClawHammer, TuningHammer) left unchanged
- main_view.gd "forge" view name strings left untouched (those are view identifiers, not currency keys)
- Integration test assertions updated to match new key names and new default counts

## Task Commits

Each task was committed atomically:

1. **Task 1: Rename currency keys across all 6 files and update starter counts** - `b058d8d` (feat)

## Files Created/Modified
- `autoloads/game_state.gd` - Renamed keys in currency_counts initialization in both initialize_fresh_game() and _wipe_run_state(), updated counts to 2 transmute + 2 augment
- `autoloads/prestige_manager.gd` - Renamed "forge" to "augment" in PRESTIGE_COSTS dict (all 7 levels)
- `models/loot/loot_table.gd` - Renamed keys in CURRENCY_AREA_GATES and DROP_RATES (pack_currency_rules) dicts
- `scenes/forge_view.gd` - Renamed keys in currencies, hammer_descriptions, hammer_icons, currency_buttons dicts and bind() calls and standard_types array
- `scenes/prestige_view.gd` - Updated cost_string and cost_label.text to reference "augment" instead of "forge"
- `tools/test/integration_test.gd` - Updated all test assertions, spend_currency calls, and currency_counts references to new key names

## Decisions Made
- GDScript class names (RunicHammer etc.) and asset paths (runic_hammer.png etc.) were intentionally left unchanged per plan instructions — only dictionary key strings were renamed
- Integration test assertion for augment count after prestige: `augment == 2` is correct because `_wipe_run_state()` resets currency_counts to fresh-game defaults (2 transmute + 2 augment)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Currency rename complete — all downstream code that reads currency_counts by string key now uses PoE names
- Phase 56-02 (starter kit items / Forest difficulty tuning) can proceed
- Save format v8 still uses old key names in serialized data; save migration is Phase 58 scope (noted in CONTEXT.md)

---
*Phase: 56-difficulty-starter-kit*
*Completed: 2026-03-28*
