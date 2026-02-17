---
phase: 17-ui-and-combat-feedback
plan: 01
subsystem: ui
tags: [godot, progressbar, stylebox, combat-ui, energy-shield]

requires:
  - phase: 15-pack-based-combat-loop
    provides: CombatEngine with state machine, GameEvents combat signals
  - phase: 16-drop-system-split
    provides: Currency/item drop signals wired into gameplay_view
provides:
  - ProgressBar-based combat UI with hero HP, ES overlay, pack HP, pack progress
  - StyleBoxFlat-styled bars (red HP, blue ES, orange pack, green progress)
  - Combat state label with colored text feedback
  - Pack transition delay (0.5s) and death retry delay (2.5s)
  - FloatingTextContainer reserved for Plan 17-02
affects: [17-02-floating-damage-numbers]

tech-stack:
  added: []
  patterns: [stacked-progressbar-es-overlay, stylebox-flat-per-bar, signal-driven-bar-updates]

key-files:
  created: []
  modified:
    - scenes/gameplay_view.gd
    - scenes/gameplay_view.tscn
    - models/combat/combat_engine.gd

key-decisions:
  - "ES bar stacked on top of HP bar at same position (PoE blue-over-red pattern)"
  - "Pack transition delay 0.5s and death retry delay 2.5s with state guards"
  - "MaterialsLabel completely removed — all info now in bars and labels"

patterns-established:
  - "Stacked ProgressBar overlay: two bars at same position for layered display"
  - "StyleBoxFlat.new() per bar for unique styling without shared mutation"
  - "State guards after await: check state hasn't changed during timer delays"

duration: 8min
completed: 2026-02-17
---

# Plan 17-01: Combat UI Bars Summary

**ProgressBar-based combat UI with hero HP/ES overlay, pack HP, pack progress, and state transition delays**

## Performance

- **Duration:** 8 min
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Hero HP bar (red) with ES overlay (blue, PoE style) and overlaid text labels
- Pack HP bar (orange-red) visible during fighting with current/max display
- Pack progress bar (green) with instant jumps on pack kills showing X/Y count
- Combat state label with colored text: Fighting, Pack cleared, Hero died, Map Clear
- 0.5s pack-to-pack transition pause and 2.5s death retry delay in CombatEngine

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ProgressBar-based combat UI to gameplay_view scene and script** - `1ec4a31` (feat)
2. **Task 2: Implement state transition visual feedback with delays** - `6f4e3be` (feat)

## Files Created/Modified
- `scenes/gameplay_view.tscn` - CanvasLayer with ProgressBar nodes, labels, and FloatingTextContainer
- `scenes/gameplay_view.gd` - Rewritten with bar references, StyleBoxFlat styling, signal-driven updates
- `models/combat/combat_engine.gd` - Added pack_transition_delay_sec and death_retry_delay_sec with await + state guards

## Decisions Made
- ES bar uses same position/size as HP bar with transparent background for stacked overlay effect
- State guards added after both create_timer awaits to prevent stale transitions
- Area label format changed to "Biome -- Level N" for cleaner display
- combat_started_once flag tracks whether to show hero health container

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- FloatingTextContainer node ready for Plan 17-02 floating damage numbers
- All signal handlers in place; 17-02 will add _spawn_floating_text calls

---
*Phase: 17-ui-and-combat-feedback*
*Completed: 2026-02-17*
