---
phase: 17-ui-and-combat-feedback
plan: 02
subsystem: ui
tags: [godot, tween, floating-text, combat-feedback, label]

requires:
  - phase: 17-ui-and-combat-feedback
    plan: 01
    provides: FloatingTextContainer node in CanvasLayer, combat signal handlers
provides:
  - FloatingLabel scene with self-animating tween drift-up and fade-out
  - Floating damage numbers on hero and pack attacks
  - Crit styling (gold, 1.5x scale) and DODGE text on evasion
affects: []

tech-stack:
  added: []
  patterns: [tween-animated-label, preload-instantiate-spawn, auto-cleanup-queue-free]

key-files:
  created:
    - scenes/floating_label.gd
    - scenes/floating_label.tscn
  modified:
    - scenes/gameplay_view.gd

key-decisions:
  - "Uniform white damage numbers regardless of element type (user decision)"
  - "Crit gold Color(1.0, 0.8, 0.0) at 1.5x scale"
  - "Random X offset randf_range(-20, 20) for visual variety"
  - "No object pooling — instantiate/queue_free per label (sufficient at current attack rates)"

patterns-established:
  - "Preload + instantiate + add_child for dynamic scene spawning"
  - "await tween.finished + queue_free for self-cleaning animated nodes"

duration: 5min
completed: 2026-02-17
---

# Plan 17-02: Floating Damage Numbers Summary

**Self-animating FloatingLabel scene with tween drift/fade, crit gold styling, and DODGE text on evasion**

## Performance

- **Duration:** 5 min
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 modified)

## Accomplishments
- FloatingLabel scene: self-contained Label with tween drift-up + fade-out, auto queue_free
- Hero attacks spawn white/gold numbers near pack HP bar
- Pack attacks spawn white numbers near hero HP bar; dodges show "DODGE" text
- Crits display in gold at 1.5x scale for visual distinction

## Task Commits

Each task was committed atomically:

1. **Task 1: Create FloatingLabel scene with tween-animated drift and fade** - `100c849` (feat)
2. **Task 2: Wire floating text spawning into gameplay_view signal handlers** - `1f60b51` (feat)

## Files Created/Modified
- `scenes/floating_label.gd` - Self-animating Label with show_damage and show_dodge methods
- `scenes/floating_label.tscn` - Minimal scene with Label root, 20px font, centered alignment
- `scenes/gameplay_view.gd` - Added FLOATING_LABEL preload, _spawn_floating_text, updated signal handlers

## Decisions Made
- Damage numbers uniform white regardless of element type (per user decision)
- Crit color gold, DODGE text white — simple visual language
- No object pooling needed at current attack rate (~2-4 labels/second)
- Spawn position computed as constants above HP bars with random X jitter

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 17 UI complete: all combat state visible through bars + floating numbers
- Ready for phase verification

---
*Phase: 17-ui-and-combat-feedback*
*Completed: 2026-02-17*
