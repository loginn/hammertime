---
phase: 56-difficulty-starter-kit
plan: 02
subsystem: gameplay, testing
tags: [gdscript, godot, biome-config, game-state, hero-archetype, starter-kit, difficulty]

# Dependency graph
requires:
  - phase: 56-01
    provides: "Currency key renames (transmute/augment/etc.) used in starter currency checks"
provides:
  - "_place_starter_kit() function with archetype-matched STR/DEX/INT item selection"
  - "Forest monster stats reduced ~50% for zone 1 survival with blank Normal gear"
  - "BIOME_STAT_RATIOS[25] updated from 1.63 to 2.81 to match new Forest avg HP"
  - "Integration test groups 42-44 verifying difficulty tuning and starter kit placement"
affects: [prestige-system, combat-engine, save-format]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "_place_starter_kit(null) for P0 fresh game; _place_starter_kit(hero) for post-prestige archetype selection"
    - "Starter kit placement in initialize_fresh_game() but NOT in _wipe_run_state() — items placed after archetype selection on prestige"

key-files:
  created: []
  modified:
    - autoloads/game_state.gd
    - scenes/main_view.gd
    - models/monsters/biome_config.gd
    - models/monsters/pack_generator.gd
    - tools/test/integration_test.gd

key-decisions:
  - "null archetype = STR defaults (Broadsword + IronPlate) for P0 fresh game"
  - "Starter items placed AFTER archetype selection in main_view._on_hero_card_selected, not during _wipe_run_state"
  - "Forest monster HP/damage reduced ~50% — avg HP from 27.0 to 15.67"
  - "BIOME_STAT_RATIOS[25] = 2.81 (44.0/15.67) to preserve accurate biome boundary relief dip"
  - "Use HeroArchetype.from_id() with actual REGISTRY keys (str_hit, dex_hit, int_hit) in tests"

patterns-established:
  - "Groups 40-41 stash tests updated to expect starter kit items — future stash tests must account for 1 starter weapon + 1 starter armor"

requirements-completed: [DIFF-01, DIFF-03]

# Metrics
duration: 18min
completed: 2026-03-28
---

# Phase 56 Plan 02: Difficulty Starter Kit — Archetype Items + Forest Tuning Summary

**_place_starter_kit() adds archetype-matched Normal tier-8 weapon+armor to stash on fresh game and post-prestige; Forest monster HP/damage halved (~50%) so blank gear heroes survive zone 1**

## Performance

- **Duration:** 18 min
- **Started:** 2026-03-28T00:00:00Z
- **Completed:** 2026-03-28T00:18:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Added `_place_starter_kit(archetype)` to GameState — STR gets Broadsword+IronPlate, DEX gets Dagger+LeatherVest, INT gets Wand+SilkRobe
- Fresh P0 game calls `_place_starter_kit(null)` (STR defaults); post-prestige archetype selection calls it with the chosen hero
- Forest monster base_hp reduced from avg 27.0 to 15.67 (~50%), base_damage similarly halved — zone 1 survival with blank tier-8 Broadsword (18.9 DPS) confirmed by math
- BIOME_STAT_RATIOS[25] updated from 1.63 to 2.81 so Dark Forest boundary relief dip remains accurate
- Three new integration test groups (42-44) verify Forest difficulty values, fresh game currencies+items, and all three archetype starter kits

## Task Commits

Each task was committed atomically:

1. **Task 1: Add _place_starter_kit() and wire into initialization + archetype selection** - `a46e29f` (feat)
2. **Task 2: Tune Forest difficulty and update BIOME_STAT_RATIOS** - `0673297` (feat)
3. **Task 3: Add integration test groups 42-44** - `346da5d` (test)

## Files Created/Modified
- `autoloads/game_state.gd` - Added `_place_starter_kit()` function; call from `initialize_fresh_game()`
- `scenes/main_view.gd` - Call `GameState._place_starter_kit(hero)` in `_on_hero_card_selected()` after archetype confirmed
- `models/monsters/biome_config.gd` - Forest monster stats reduced ~50% across all 6 types
- `models/monsters/pack_generator.gd` - Forest avg HP comment updated; BIOME_STAT_RATIOS[25] = 2.81
- `tools/test/integration_test.gd` - Groups 42-44 added; groups 40-41 fixed for starter kit presence

## Decisions Made
- `null` archetype maps to STR defaults (Broadsword + IronPlate) for P0 fresh game with no archetype
- Starter kit placed AFTER archetype selection (not in `_wipe_run_state()`) per D-09
- Double `SaveManager.save_game()` call in `_on_hero_card_selected()` is acceptable — second save persists the starter items
- Used `HeroArchetype.from_id("str_hit")` (not "knight") in tests — actual REGISTRY keys discovered by reading the file

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated groups 40-41 to account for starter kit items**
- **Found during:** Task 3 (integration test groups)
- **Issue:** `initialize_fresh_game()` now places 1 Broadsword + 1 IronPlate in stash via `_place_starter_kit(null)`. Groups 40-41 assumed stash was empty after fresh game — they would have failed.
- **Fix:** Updated group 40 to check weapon/armor have 1 starter item each; updated group 41 to start from size 2 (starter + added) for weapon slot fill test, and armor slot routing check updated to expect size 2 after adding IronPlate
- **Files modified:** tools/test/integration_test.gd
- **Verification:** Checks updated to match actual post-starter-kit stash state
- **Committed in:** 346da5d (Task 3 commit)

**2. [Rule 1 - Bug] Fixed REGISTRY keys in Group 44 test**
- **Found during:** Task 3 (writing group 44)
- **Issue:** Plan referenced "knight"/"ranger"/"sorcerer" as REGISTRY keys, but actual keys are "str_hit"/"dex_hit"/"int_hit"
- **Fix:** Used `HeroArchetype.from_id("str_hit")`, `from_id("dex_hit")`, `from_id("int_hit")` — plus `from_id()` pattern is correct per the model file
- **Files modified:** tools/test/integration_test.gd
- **Verification:** from_id() found in hero_archetype.gd, REGISTRY keys confirmed in source
- **Committed in:** 346da5d (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both auto-fixes necessary for test correctness. No scope creep.

## Issues Encountered
None beyond the deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Forest zone 1 is now survivable with blank starter gear
- Post-prestige archetype selection correctly places archetype-matched items in stash
- Integration tests 42-44 cover all three work streams
- Phase 57 (if any) can build on the starter kit foundation

---
*Phase: 56-difficulty-starter-kit*
*Completed: 2026-03-28*
