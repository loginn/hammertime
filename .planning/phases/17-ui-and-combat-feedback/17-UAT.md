---
status: complete
phase: 17-ui-and-combat-feedback
source: [17-01-SUMMARY.md, 17-02-SUMMARY.md, 17-03-SUMMARY.md]
started: 2026-02-17T14:00:00Z
updated: 2026-02-17T14:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Tab navigation with mouse clicks
expected: Clicking the Crafting, Hero, and Adventure tab buttons switches views. All three buttons respond to mouse clicks from any view. Keyboard shortcuts (1/2/3) also still work.
result: pass

### 2. Combat UI visible on gameplay tab
expected: When on the Adventure/gameplay tab, a green background fills the gameplay area. Combat UI elements (HP bars, labels) are visible. Press Start if needed to begin combat.
result: pass

### 3. CombatUI hidden when switching tabs
expected: While combat is running, switch to Crafting or Hero tab. The combat UI bars and labels disappear completely — no phantom bars overlaying other views. Switch back to Adventure and they reappear.
result: pass

### 4. Hero HP and ES bars update during combat
expected: Red hero HP bar decreases when packs attack. Text shows "current/max" (e.g., "150/200"). If you have ES gear equipped, a blue bar overlays the red bar and drains first. HP label shows ES info too.
result: issue
reported: "ES should be slightly transparent"
severity: cosmetic

### 5. Pack HP bar drains as hero attacks
expected: Orange-red pack HP bar visible during combat showing the current pack's health. It decreases as the hero auto-attacks. When pack HP reaches 0, the bar resets for the next pack.
result: pass

### 6. Pack progress tracking
expected: Green progress bar fills as packs are cleared. A label shows pack count like "3/7". Bar jumps instantly on each pack kill (no smooth animation).
result: pass

### 7. Combat state labels with colors
expected: During combat: "Fighting..." (white). When a pack dies: "Pack cleared!" (white). If hero dies: "Hero died! Retrying..." (red). On map clear: "Map Clear!" (green).
result: issue
reported: "I've not been able to clear a map yet. Difficulty is too high at level 1"
severity: minor

### 8. Transition delays between states
expected: After killing a pack, brief ~0.5s pause before the next fight starts. If the hero dies, ~2.5s pause showing the death message before auto-retrying the same level.
result: pass

### 9. Floating damage numbers on hero attacks
expected: When hero hits a pack, white damage numbers drift upward near the pack HP bar and fade out. Critical hits appear in gold at a larger size. Numbers have slight random horizontal offset.
result: pass

### 10. Floating damage on pack attacks and dodges
expected: When a pack hits the hero, white damage numbers appear near the hero HP bar drifting up and fading. When the hero dodges (evasion), "DODGE" text appears instead of a number.
result: pass

## Summary

total: 10
passed: 8
issues: 2
pending: 0
skipped: 0

## Gaps

- truth: "ES bar overlays the red HP bar with visual distinction"
  status: failed
  reason: "User reported: ES should be slightly transparent"
  severity: cosmetic
  test: 4
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Map Clear state label visible in green after clearing all packs"
  status: failed
  reason: "User reported: I've not been able to clear a map yet. Difficulty is too high at level 1"
  severity: minor
  test: 7
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
