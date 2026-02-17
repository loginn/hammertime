---
phase: 19-side-by-side-layout
plan: 04
subsystem: navigation, ui-layout
tags: [gap-closure, navigation, shortcuts, viewport, theming]
dependency_graph:
  requires: [LAYOUT-02]
  provides: [UAT-02, UAT-03, UAT-10]
  affects: [scenes/main_view.gd, scenes/main.tscn, scenes/gameplay_view.tscn, project.godot]
tech_stack:
  added: []
  patterns: [keyboard-input-filtering, viewport-clear-color]
key_files:
  created: []
  modified:
    - scenes/main_view.gd
    - scenes/main.tscn
    - scenes/gameplay_view.tscn
    - project.godot
decisions:
  - TAB key now only toggles between forge and combat views (settings accessible via tab button only)
  - Combat tab renamed to "Adventure" for user-facing clarity
  - Viewport clear color set to dark gray matching theme background
metrics:
  duration_seconds: 85
  tasks_completed: 2
  files_modified: 4
  commits: 2
  completed_date: 2026-02-17
---

# Phase 19 Plan 04: Navigation and Viewport Fixes Summary

**One-liner:** Fixed keyboard shortcuts to remove KEY_3, renamed Combat tab to Adventure, removed misplaced title label, and set dark viewport background.

## What Was Built

Fixed 3 UAT gaps (tests 2, 3, 10) related to navigation shortcuts and viewport rendering:

1. **Navigation shortcuts corrected** — KEY_3 removed entirely, TAB now only toggles between forge and combat views (skipping settings)
2. **Combat tab renamed to Adventure** — Matches user-facing terminology
3. **TabBar extended to y=50** — Eliminates 10px gap between tab bar and content area
4. **Misplaced "Adventure" label removed** — Deleted Title node from gameplay_view.tscn
5. **Viewport clear color set to dark gray** — Matches theme background, eliminating color mismatch strips at viewport edges

## How It Works

**Keyboard navigation:**
- KEY_1 → Forge view
- KEY_2 → Combat (Adventure) view
- TAB → Toggles between forge and combat only
- Settings view only accessible via clicking Settings tab button

**Viewport theming:**
- `project.godot` sets `default_clear_color` to `Color(0.1, 0.1, 0.1, 1)` (dark gray)
- Matches `#1a1a1a` background used throughout the UI
- Any uncovered pixels at viewport edges now show consistent dark color instead of Godot's default gray-blue

## Deviations from Plan

None — plan executed exactly as written.

## Task Commits

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Fix keyboard shortcuts and rename Combat tab | 351ba8e | scenes/main_view.gd, scenes/main.tscn |
| 2 | Remove gameplay title label and set viewport clear color | 92dd985 | scenes/gameplay_view.tscn, project.godot |

## Verification Results

All verification checks passed:

1. ✓ main_view.gd — No KEY_3 case in match statement
2. ✓ main_view.gd — TAB only toggles between forge and combat
3. ✓ main.tscn — CombatTab text="Adventure"
4. ✓ main.tscn — TabBar offset_bottom=50 (eliminates gap)
5. ✓ gameplay_view.tscn — No Title node exists
6. ✓ project.godot — default_clear_color=Color(0.1, 0.1, 0.1, 1)

## Self-Check

Verifying all claimed artifacts exist:

**Modified files:**
- ✓ scenes/main_view.gd
- ✓ scenes/main.tscn
- ✓ scenes/gameplay_view.tscn
- ✓ project.godot

**Commits:**
- ✓ 351ba8e (Task 1: Navigation shortcuts and tab rename)
- ✓ 92dd985 (Task 2: Title removal and viewport clear color)

## Self-Check: PASSED

All files and commits verified successfully.
