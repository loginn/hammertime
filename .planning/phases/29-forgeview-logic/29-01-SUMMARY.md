---
phase: 29-forgeview-logic
plan: 01
subsystem: crafting-ui
tags: [gdscript, forgeview, bench-selection, melt, equip, inventory-arrays]

# Dependency graph
requires:
  - phase: 28-gamestate-data-model-and-drop-flow
    provides: "Array-based crafting_inventory, is_item_better() function, ForgeView array access patterns"
provides:
  - "get_best_item() helper for highest-tier item selection from slot arrays"
  - "Bench always loads highest-tier item (DPS for weapon/ring, tier for armor)"
  - "Auto-select next-best item after melt and equip operations"
  - "Equip confirmation reset on slot navigation (verified)"
affects: [30-display-and-counter]

# Tech tracking
tech-stack:
  added: []
  patterns: ["best-item selection via is_item_better() comparison loop"]

key-files:
  created: []
  modified:
    - "scenes/forge_view.gd"

key-decisions:
  - "get_best_item() lives on ForgeView (not a static helper) — keeps it near is_item_better()"
  - "Melt stays on same slot type after removal (does not auto-switch to different slot)"
  - "Bench item is not re-evaluated after hammer application (only on slot switch, melt, equip)"

patterns-established:
  - "Best-item selection: get_best_item(slot_name) replaces all [0] placeholder access"
  - "Auto-select after removal: melt/equip call get_best_item() to load next item"

requirements-completed: [BENCH-01, BENCH-02, INV-03, EQUIP-01, EQUIP-02]

# Metrics
duration: 3min
completed: 2026-02-19
---

# Phase 29 Plan 01: ForgeView Best-Item Selection and Auto-Select Summary

**get_best_item() helper replaces all [0] placeholder access with highest-tier selection, melt and equip auto-load next-best item after removal**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-19T04:10:00Z
- **Completed:** 2026-02-19T04:13:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Added get_best_item() helper that uses is_item_better() for DPS (weapon/ring) and tier (armor) comparison
- Replaced all crafting_inventory[slot][0] placeholder access with get_best_item(slot) calls across 4 sites
- Melt auto-selects next-best item from same slot after removal instead of setting null
- Equip auto-selects next-best item from same slot after moving item to hero equipment
- Verified equip confirmation reset on slot navigation still works correctly

## Task Commits

Each task was committed atomically:

1. **Task 1: Add get_best_item() helper and update bench selection** - `f791b8d` (feat)
2. **Task 2: Update melt and equip to auto-select next-best item** - `ef2656b` (feat)

## Files Created/Modified
- `scenes/forge_view.gd` - Added get_best_item(), updated _ready(), update_current_item(), update_inventory_display(), _on_melt_pressed(), _on_equip_pressed()

## Decisions Made
- get_best_item() placed on ForgeView near is_item_better() for locality
- Melt stays on same slot type (does not auto-switch to a different slot with items)
- Bench item is not re-evaluated after hammer application to avoid jarring mid-craft switches

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 30 (Display and Counter) can build x/10 counter on top of array-based inventory
- All bench selection, melt, and equip logic is complete
- Slot buttons already exist and need label updates for counter display

## Self-Check: PASSED

- [x] scenes/forge_view.gd exists
- [x] get_best_item() function defined and uses is_item_better()
- [x] Zero crafting_inventory[...][0] patterns remain
- [x] _on_melt_pressed calls get_best_item after removal
- [x] _on_equip_pressed calls get_best_item after removal
- [x] Commit f791b8d present (Task 1)
- [x] Commit ef2656b present (Task 2)

---
*Phase: 29-forgeview-logic*
*Completed: 2026-02-19*
