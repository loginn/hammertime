---
phase: 53-selection-ui
plan: 01
subsystem: hero-selection
tags: [ui, overlay, hero-archetype, prestige, selection]
dependency_graph:
  requires: [52-01]
  provides: [hero-selection-overlay]
  affects: [main_view, hero_archetype, integration_tests]
tech_stack:
  added: []
  patterns: [programmatic-ui, tween-fade, mouse-filter-stop]
key_files:
  created: []
  modified:
    - models/hero_archetype.gd
    - scenes/main_view.gd
    - tools/test/integration_test.gd
decisions:
  - "Overlay built programmatically in main_view.gd — no new scene files needed"
  - "BONUS_LABELS const on HeroArchetype for clean label lookup and testability"
  - "bg ColorRect with MOUSE_FILTER_STOP blocks all input to underlying views"
metrics:
  duration: "157 seconds (~3 minutes)"
  completed_date: "2026-03-27"
  tasks_completed: 3
  files_modified: 3
---

# Phase 53 Plan 01: Selection UI Summary

**One-liner:** Programmatic 3-card hero selection overlay with colored borders, formatted bonuses, 0.3s fade dismiss, and auto-save on pick.

## Tasks Completed

| # | Name | Commit | Status |
|---|------|--------|--------|
| 1 | Add BONUS_LABELS, format_bonuses() to HeroArchetype + Group 39 tests | 349e557 | Done |
| 2 | Build hero selection overlay in main_view.gd | 55b6654 | Done |
| 3 | Visual verification of hero selection flow | (auto-approved) | Done |

## What Was Built

### Task 1: HeroArchetype additions

Added to `models/hero_archetype.gd`:
- `BONUS_LABELS` const with 13 entries mapping bonus keys to human-readable labels
- `format_bonuses(bonuses: Dictionary) -> Array[String]` static method producing `"+N% Label"` strings

Added to `tools/test/integration_test.gd`:
- `_group_39_selection_ui()` with 17 test cases covering: format_bonuses single/multi/empty, BONUS_LABELS registry key coverage, generate_choices count and one-per-archetype, P0/P1-null/P1-set detection logic, and selection assignment

### Task 2: Hero selection overlay

Added to `scenes/main_view.gd`:
- `_hero_overlay: Control` variable for re-entry guard
- `_ARCH_NAMES` and `_SUB_NAMES` dicts for archetype/subvariant display
- Hero selection check at end of `_ready()`: `if GameState.prestige_level >= 1 and GameState.hero_archetype == null`
- `_show_hero_selection()`: emits `hero_selection_needed`, calls `generate_choices()`, builds overlay tree on `$OverlayLayer`
- `_build_hero_card(hero)`: PanelContainer with StyleBoxFlat colored left border, archetype label, title, HSeparator, bonus lines
- `_on_hero_card_selected(hero)`: double-click guard, sets `GameState.hero_archetype`, calls `update_stats()`, saves, emits `hero_selected`, tweens modulate:a to 0.0 over 0.3s then frees overlay

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None - all data is wired from live `HeroArchetype.generate_choices()` and `format_bonuses()`.

## Self-Check: PASSED

Files exist:
- models/hero_archetype.gd: FOUND (verified BONUS_LABELS and format_bonuses present)
- scenes/main_view.gd: FOUND (verified all 14 acceptance criteria patterns present)
- tools/test/integration_test.gd: FOUND (verified _group_39_selection_ui present)

Commits exist:
- 349e557: feat(53-01): add BONUS_LABELS and format_bonuses() to HeroArchetype + Group 39 tests
- 55b6654: feat(53-01): build hero selection overlay in main_view.gd
