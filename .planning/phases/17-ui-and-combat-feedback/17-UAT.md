---
status: diagnosed
phase: 17-ui-and-combat-feedback
source: [17-01-SUMMARY.md, 17-02-SUMMARY.md]
started: 2026-02-17T12:00:00Z
updated: 2026-02-17T12:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Combat UI replaces timer-based display
expected: Press Start. ProgressBar-based combat UI appears — hero HP (red), pack HP (orange), pack progress (green). No old timer bar or text dump.
result: issue
reported: "The UI buttons that swap the different tabs dont work (but the shortcuts do). I cant see any red bar, pack bar or progress bar anywhere"
severity: blocker

### 2. Hero HP and ES bars update during combat
expected: Red hero HP bar decreases when packs attack you. Text overlay shows "current/max" (e.g., "150/200"). If you have ES gear equipped, a blue bar overlays the red bar and drains first. HP label shows ES info too (e.g., "150/200 ES: 50/100").
result: issue
reported: "Buttons are not working, I can't see anything that would match"
severity: blocker

### 3. Pack HP bar drains as hero attacks
expected: Orange-red pack HP bar is visible during combat showing the current pack's health. It decreases as the hero auto-attacks. When pack HP reaches 0, the bar resets for the next pack.
result: skipped
reason: Blocked by same issue as test 1 — no bars visible

### 4. Pack progress tracking
expected: Green progress bar fills as packs are cleared. A label shows pack count like "3/7". Bar jumps instantly on each pack kill (no smooth animation).
result: skipped
reason: Blocked by same issue as test 1 — no bars visible

### 5. Combat state labels with colors
expected: During combat you see "Fighting..." (white). When a pack dies: "Pack cleared!" (white). If hero dies: "Hero died! Retrying..." (red text). On map clear: "Map Clear!" (green text).
result: issue
reported: "Same issue as above, I cant see anything, the UI isnt working"
severity: blocker

### 6. Transition delays between states
expected: After killing a pack, there's a brief ~0.5 second pause before the next fight starts. If the hero dies, there's a ~2.5 second pause showing the death message before auto-retrying the same level.
result: skipped
reason: Blocked — entire UI not rendering

### 7. Floating damage numbers on hero attacks
expected: When the hero hits a pack, white damage numbers drift upward near the pack HP bar and fade out. Critical hits appear in gold at a larger size. Numbers have slight random horizontal offset for variety.
result: skipped
reason: Blocked — entire UI not rendering

### 8. Floating damage numbers on pack attacks and dodges
expected: When a pack hits the hero, white damage numbers appear near the hero HP bar drifting up and fading. When the hero dodges (evasion), "DODGE" text appears instead of a number.
result: skipped
reason: Blocked — entire UI not rendering

## Summary

total: 8
passed: 0
issues: 3
pending: 0
skipped: 4

## Gaps

- truth: "ProgressBar-based combat UI appears with hero HP (red), pack HP (orange), pack progress (green)"
  status: failed
  reason: "User reported: The UI buttons that swap the different tabs dont work (but the shortcuts do). I cant see any red bar, pack bar or progress bar anywhere"
  severity: blocker
  test: 1
  root_cause: "Two issues: (1) CombatUI CanvasLayer's UIRoot has default mouse_filter=STOP, blocking all mouse input globally on layer 1. CanvasLayer also doesn't hide when parent gameplay_view.visible=false. (2) Background ColorRect uses anchors under Node2D parent which has no size, so anchors resolve to 0."
  artifacts:
    - path: "scenes/gameplay_view.tscn"
      issue: "UIRoot missing mouse_filter=2 (IGNORE), Background using anchors under Node2D"
    - path: "scenes/main_view.gd"
      issue: "show_view() sets .visible=false which does not propagate to CanvasLayer children"
  missing:
    - "Set mouse_filter=2 on UIRoot and all non-interactive containers"
    - "Handle CanvasLayer visibility explicitly in show_view()"
    - "Fix Background sizing to use explicit offsets instead of anchors"
  debug_session: ""

- truth: "Combat state labels, HP bars, and all UI elements visible during combat"
  status: failed
  reason: "User reported: entire UI not rendering — no bars, no labels, buttons don't work (keyboard shortcuts do)"
  severity: blocker
  test: 2,5
  root_cause: "Same as test 1 — UIRoot on CanvasLayer blocks input and CanvasLayer doesn't respect parent visibility"
  artifacts:
    - path: "scenes/gameplay_view.tscn"
      issue: "UIRoot missing mouse_filter=2"
  missing:
    - "Same fixes as test 1"
  debug_session: ""
