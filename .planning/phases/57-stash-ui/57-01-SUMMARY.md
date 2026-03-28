---
phase: 57-stash-ui
plan: 01
subsystem: ui
tags: [godot, gdscript, forge-view, stash, buttons, tween]

# Dependency graph
requires:
  - phase: 55-stash-data-model
    provides: GameState.stash dict, add_item_to_stash(), GameEvents.stash_updated signal, crafting_bench
provides:
  - StashDisplay scene subtree (15 slot buttons in 5 labeled groups) replacing ItemTypeButtons
  - forge_view.gd stash display logic: _update_stash_display(), _get_item_abbreviation(), _build_stash_tooltip()
  - Tap-to-bench handler: _on_stash_slot_pressed() with bench guard, flash animation
  - Bench-clear stash re-enable: _pulse_stash_slots() called from melt and equip paths
  - Integration test groups 45-47 for stash display, tap-to-bench, and tooltip text

affects: [57-02-PLAN, forge_view, stash ui interactions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fixed slot index mapping: stash_slot_buttons[slot_type][i] always reads GameState.stash[slot_type][i]"
    - "Tween flash on transfer (D-07): yellow flash then dim; pulse on bench clear (D-09)"
    - "Modulate Color(0.4, 0.4, 0.4) for dim/empty slots, Color(1,1,1) for filled"
    - "Bench-occupied gate: filled slots disabled when crafting_bench != null"

key-files:
  created: []
  modified:
    - scenes/forge_view.tscn
    - scenes/forge_view.gd
    - tools/test/integration_test.gd

key-decisions:
  - "Used is-keyword for item abbreviation lookup (not get_class() strings) per Research Pitfall 5"
  - "Removed currently_hovered_type and item type hover branch from update_hero_stats_display()"
  - "_on_stash_slot_pressed removes item from stash AFTER flash tween fires (fire-and-forget tween)"
  - "Filled-but-disabled slots (bench occupied) will not show tooltip per Godot built-in behavior — accepted per plan"

patterns-established:
  - "stash_slot_buttons dict populated in _ready() via $StashDisplay/... node paths"
  - "All stash state mutations followed by explicit _update_stash_display() call (signal not emitted on removal)"

requirements-completed: [STSH-02, STSH-05]

# Metrics
duration: 25min
completed: 2026-03-28
---

# Phase 57 Plan 01: Stash UI Summary

**15-slot StashDisplay grid in ForgeView with abbreviation labels, dim/filled states, tooltip_text, tap-to-bench handler, and tween animations wired to stash_updated signal**

## Performance

- **Duration:** 25 min
- **Started:** 2026-03-28T00:00:00Z
- **Completed:** 2026-03-28
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Replaced ItemTypeButtons (5 hidden type-select buttons) with StashDisplay (15 slot buttons in 5 labeled groups of 3)
- Added full stash display logic: abbreviation lookup for 21 item types, tooltip builder, dim/enabled states gated by bench occupancy
- Wired tap-to-bench handler with bench-occupied guard, flash animation (D-07), and bench-clear pulse (D-09)
- Connected GameEvents.stash_updated for live refresh during combat (D-10)
- Added 3 integration test groups (45-47) covering stash array data layer, tap-to-bench mutation, and tooltip text content

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace ItemTypeButtons with StashDisplay scene tree and add stash display logic** - `dd7a395` (feat)
2. **Task 2: Add integration tests for stash UI data-layer behavior** - `711990d` (test)

## Files Created/Modified
- `scenes/forge_view.tscn` - Replaced ItemTypeButtons Control+5 children with StashDisplay Control + 5 VBoxContainer groups (each with Label + HBoxContainer + 3 Buttons)
- `scenes/forge_view.gd` - Added stash display functions, removed item type button @onready refs, connect blocks, hover functions, and dead code stubs
- `tools/test/integration_test.gd` - Added groups 45-47 for stash UI data-layer behavior

## Decisions Made
- Used `is` keyword for abbreviation lookup (not `get_class()`) per Research Pitfall 5 — avoids class-name string fragility
- Removed `currently_hovered_type` and the item-type hover branch from `update_hero_stats_display()` — the feature was only useful with the old type-select buttons, which are now gone
- Flash tween fires before `remove_at` so it can reference the correct button (fire-and-forget, tween ends on dim regardless)
- Accepted that filled-but-disabled slots (bench occupied per D-05) will not show tooltip_text — Godot suppresses tooltips on disabled Controls; this is an accepted feature gap per Research Pitfall 6

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None - all stash display data is wired to live GameState.stash via _update_stash_display().

## Next Phase Readiness
- ForgeView now displays all 15 stash slots with correct abbreviations, dim/enabled states, and tooltips
- Tap-to-bench interaction fully functional including bench-occupied guard and tween feedback
- Ready for Phase 57 Plan 02 (which may add item selection or further stash interaction)

## Self-Check

- [x] `scenes/forge_view.tscn` contains StashDisplay node tree (verified via grep: 31 matches)
- [x] `scenes/forge_view.gd` contains all required functions (verified via grep)
- [x] `tools/test/integration_test.gd` contains groups 45-47 (verified via grep)
- [x] Commits dd7a395 and 711990d exist

---
*Phase: 57-stash-ui*
*Completed: 2026-03-28*
