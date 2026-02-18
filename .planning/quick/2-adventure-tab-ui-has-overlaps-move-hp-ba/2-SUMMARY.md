---
phase: quick-2
plan: 01
subsystem: ui
tags: [godot, canvaslayer, combat-ui, layout]

requires: []
provides:
  - CombatUI elements repositioned below buttons in Adventure tab
affects: []

tech-stack:
  added: []
  patterns:
    - "CanvasLayer absolute offsets must account for parent Node2D position when co-existing with non-CanvasLayer siblings"

key-files:
  created: []
  modified:
    - scenes/gameplay_view.tscn
    - scenes/gameplay_view.gd

key-decisions:
  - "Shift all CombatUI CanvasLayer children down 40px (220/250/270/295/315/345) to provide 20px clearance below buttons ending at absolute y=200"
  - "Floating text spawn positions updated from y=160 to y=200 to stay above shifted HP bars"

patterns-established:
  - "CombatUI CanvasLayer uses absolute screen coords — offsets must account for ContentArea y=50 + button height when stacking below buttons"

requirements-completed: [QUICK-2]

duration: 5min
completed: 2026-02-18
---

# Quick Task 2: Adventure Tab UI Overlap Fix Summary

**HP bars, pack progress, and combat state label shifted 40px down in CanvasLayer absolute space to clear buttons ending at y=200, with floating text positions updated to match**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-02-18T~01:20:00Z
- **Completed:** 2026-02-18T~01:25:00Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Identified root cause: CombatUI is a CanvasLayer (absolute coords) while GameplayView sits inside ContentArea at y=50; buttons end at absolute y=200, HP bars were starting at y=180 — a 20px overlap
- Shifted all four CombatUI element groups down by 40px: HeroHealthContainer, PackHealthContainer, PackProgressContainer, CombatStateLabel
- Updated floating text spawn y-coordinates from 160 to 200 so damage numbers appear above the shifted HP bars, not over buttons

## Task Commits

1. **Task 1: Reposition CombatUI elements and update floating text positions** - `29b12e2` (fix)

## Files Created/Modified

- `scenes/gameplay_view.tscn` - Shifted HeroHealthContainer (180→220/210→250), PackHealthContainer (180→220/210→250), PackProgressContainer (230→270/255→295), CombatStateLabel (275→315/305→345)
- `scenes/gameplay_view.gd` - Updated hero_damage_pos and pack_damage_pos y from 160 to 200

## Decisions Made

- 40px shift chosen to give 20px clearance below the buttons' absolute bottom edge (y=200): HP bars start at y=220
- Floating text updated to y=200 (same as button bottom) so numbers rise upward from just at the button line, clear of button labels

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Adventure tab layout is clean; HP bars and combat elements are clearly separated from navigation buttons
- No concerns for Phase 21 (Save Import/Export)

---
*Phase: quick-2*
*Completed: 2026-02-18*
