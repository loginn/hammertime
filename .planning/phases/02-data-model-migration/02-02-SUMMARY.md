---
phase: 02-data-model-migration
plan: 02
subsystem: data-model
tags: [godot, gdscript, resource, autoload, singleton, state-management]

# Dependency graph
requires:
  - phase: 02-data-model-migration
    plan: 01
    provides: Resource-based data model for all items and affixes
provides:
  - GameState autoload holding single Hero instance
  - GameEvents event bus with equipment_changed, item_crafted, area_cleared signals
  - Hero as Resource (pure data, no Node overhead)
  - Views wired to GameState.hero for single source of truth
affects: [02-data-model-migration, 04-signal-wiring]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Autoloads provide singleton access to shared game state"
    - "Event bus pattern via GameEvents for decoupled cross-scene signals"
    - "Views reference GameState.hero instead of creating local Hero instances"
    - "Equipment slot initialization moved from views to GameState._ready()"

key-files:
  created:
    - autoloads/game_events.gd
    - autoloads/game_state.gd
  modified:
    - models/hero.gd
    - scenes/hero_view.gd
    - scenes/gameplay_view.gd
    - project.godot

key-decisions:
  - "GameEvents registered before GameState in autoload order to ensure signals available during GameState._ready()"
  - "Equipment slot initialization (null for all 5 slots) moved to GameState._ready() as single source of truth"
  - "hero_view and gameplay_view no longer create their own Hero instances - all access via GameState.hero"
  - "Unused signal warnings expected for GameEvents until Phase 4 wires signal connections"

patterns-established:
  - "Pattern 1: Autoload singletons for shared state (GameState) and event bus (GameEvents)"
  - "Pattern 2: Data models extend Resource, autoloads extend Node"
  - "Pattern 3: Views access shared state via autoload references, not local instances or sibling node references"

# Metrics
duration: 15min
completed: 2026-02-15
---

# Phase 02 Plan 02: GameState and GameEvents Autoloads Summary

**Created GameState autoload holding single Hero instance and GameEvents event bus, converted Hero to Resource, wired views to use GameState.hero as single source of truth**

## Performance

- **Duration:** 15 minutes (estimated based on plan start and completion time)
- **Started:** 2026-02-15 (continuation from checkpoint)
- **Completed:** 2026-02-15
- **Tasks:** 3 (2 auto, 1 checkpoint:human-verify)
- **Files created:** 2
- **Files modified:** 4

## Accomplishments
- Created GameEvents autoload with 3 core signals (equipment_changed, item_crafted, area_cleared) for Phase 4 event wiring
- Created GameState autoload holding single Hero instance, initialized with null equipment slots
- Converted Hero from extending Node to extending Resource (pure data, no scene tree behavior)
- Registered both autoloads in project.godot with GameEvents before GameState
- Removed local Hero instance creation from hero_view.gd and gameplay_view.gd
- Wired all Hero data access in both views to GameState.hero
- Verified game launches and all three views (Crafting, Hero, Gameplay) function identically to pre-migration state

## Task Commits

Each task was committed atomically:

1. **Task 1: Create GameEvents and GameState autoloads, convert Hero to Resource** - `c4bcda9` (feat)
2. **Task 2: Wire views to use GameState.hero instead of local hero instances** - `14ff59b` (refactor)
3. **Task 3: Verify game launches and all functionality works** - APPROVED by user (checkpoint:human-verify)

## Files Created/Modified
- `/var/home/travelboi/Programming/hammertime/autoloads/game_events.gd` - CREATED - GameEvents event bus with equipment_changed, item_crafted, area_cleared signals
- `/var/home/travelboi/Programming/hammertime/autoloads/game_state.gd` - CREATED - GameState singleton holding Hero instance, initialized in _ready() with null equipment slots
- `/var/home/travelboi/Programming/hammertime/models/hero.gd` - Changed base class from Node to Resource (pure data model)
- `/var/home/travelboi/Programming/hammertime/scenes/hero_view.gd` - Removed local hero variable, removed Hero.new() and equipment init, all hero references replaced with GameState.hero
- `/var/home/travelboi/Programming/hammertime/scenes/gameplay_view.gd` - Removed local hero variable, removed hero_view.hero assignment, all hero references replaced with GameState.hero
- `/var/home/travelboi/Programming/hammertime/project.godot` - Added GameEvents and GameState to [autoload] section (GameEvents before GameState)

## Decisions Made
- Registered GameEvents before GameState in project.godot's autoload order to ensure event signals are available when GameState's _ready() runs
- Moved equipment slot initialization from hero_view.gd's _ready() to GameState._ready() as the single source of truth for initial Hero state
- Removed hero_view.hero indirection from gameplay_view.gd - both views now reference GameState.hero directly
- Kept hero_view node reference in gameplay_view.gd for now (Phase 4 will decouple views via signals)
- Expected "signals declared but not used" warnings for GameEvents until Phase 4 connects signal handlers

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The Hero to Resource conversion and autoload wiring completed without issues. User verified game launches successfully with all three views functioning identically to the pre-migration state. The only warnings present are expected "signals declared but not used" for GameEvents signals, which will be connected in Phase 4.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The data model migration is progressing well. GameState now provides a single source of truth for the Hero instance, eliminating duplicate Hero creation and sibling view dependencies. GameEvents provides the infrastructure for Phase 4 signal-based communication. All views successfully reference shared state via autoloads.

Ready for subsequent data model refactoring plans in Phase 02.

---
*Phase: 02-data-model-migration*
*Completed: 2026-02-15*

## Self-Check: PASSED

All files and commits verified:
- FOUND: autoloads/game_events.gd
- FOUND: autoloads/game_state.gd
- FOUND: models/hero.gd
- FOUND: scenes/hero_view.gd
- FOUND: scenes/gameplay_view.gd
- FOUND: c4bcda9 (Task 1 commit)
- FOUND: 14ff59b (Task 2 commit)
