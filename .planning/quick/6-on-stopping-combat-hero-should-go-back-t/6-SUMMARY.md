---
phase: quick-6
plan: 01
subsystem: combat
tags: [combat-engine, hp-restore, es-restore, tab-switching]

requires:
  - phase: combat-engine
    provides: "stop_combat() method and combat state machine"
provides:
  - "Hero HP/ES restoration on player-initiated combat stop"
  - "Auto-stop combat when leaving combat tab"
affects: [combat, gameplay-view]

tech-stack:
  added: []
  patterns:
    - "NOTIFICATION_VISIBILITY_CHANGED for tab-leave detection in Node2D"

key-files:
  created: []
  modified:
    - models/combat/combat_engine.gd
    - scenes/gameplay_view.gd

key-decisions:
  - "Used _notification(NOTIFICATION_VISIBILITY_CHANGED) instead of visibility_changed signal for Node2D compatibility"
  - "Restore HP/ES in stop_combat() so all callers get the behavior automatically"

patterns-established:
  - "Tab-leave detection: _notification(NOTIFICATION_VISIBILITY_CHANGED) pattern for stopping active systems"

requirements-completed: [QUICK-6]

duration: 1min
completed: 2026-02-18
---

# Quick Task 6: Stop Combat Restores Hero HP/ES Summary

**Hero HP and ES restore to max on combat stop via button or tab switch, using _notification visibility pattern**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-18T14:09:18Z
- **Completed:** 2026-02-18T14:10:06Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- Hero HP restores to max_health when player clicks Stop Combat
- Hero ES restores to total_energy_shield when player clicks Stop Combat
- Switching tabs away from combat (keyboard 1/2/Tab or button) auto-stops combat and restores HP/ES
- Existing map completion and death/retry paths remain unchanged

## Task Commits

Each task was committed atomically:

1. **Task 1: Restore HP/ES on combat stop and tab leave** - `a198535` (fix)

## Files Created/Modified
- `models/combat/combat_engine.gd` - Added HP/ES restoration lines in stop_combat() before signal emit
- `scenes/gameplay_view.gd` - Added _notification handler to detect tab leave and stop combat

## Decisions Made
- Placed HP/ES restoration in `stop_combat()` itself rather than in each caller, so the button press path and tab-leave path both get the restore behavior through a single code change
- Used `_notification(NOTIFICATION_VISIBILITY_CHANGED)` rather than connecting the `visibility_changed` signal, since gameplay_view extends Node2D and the notification approach is more reliable

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

---
*Quick Task: 6*
*Completed: 2026-02-18*
