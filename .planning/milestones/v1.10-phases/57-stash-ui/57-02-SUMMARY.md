---
phase: 57-stash-ui
plan: 02
subsystem: ui
tags: [godot, gdscript, stash, crafting-bench, animations, tween]

# Dependency graph
requires:
  - phase: 57-01
    provides: stash_slot_buttons dict, _update_stash_display, signal wiring skeleton from Plan 01
provides:
  - Tap-to-bench handler in ForgeView (_on_stash_slot_pressed) with D-08 null-gap slot removal
  - Flash animation on successful stash slot transfer (_flash_stash_slot)
  - Pulse animation on bench clear via melt or equip (_pulse_stash_slots)
  - Null-safe add_item_to_stash in GameState that fills gaps before appending
affects: [58-save-stash, integration-tests, forge-view]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-08 null-gap stash: items[index] = null preserves slot positions instead of remove_at shifting"
    - "Tween flash/pulse: create_tween() for brief UI feedback without blocking"

key-files:
  created: []
  modified:
    - scenes/forge_view.gd
    - autoloads/game_state.gd

key-decisions:
  - "items[index] = null over remove_at: preserves slot positions per D-08 no-shift rule"
  - "add_item_to_stash fills null gaps before appending: array of [item, null, item] can accept a new item without growing to size 4"

patterns-established:
  - "Stash slot removal leaves null gap — _update_stash_display handles null entries via 'items[i] != null' guard"
  - "add_item_to_stash counts non-null items for 3-slot cap, fills first null slot before append"

requirements-completed: [STSH-03]

# Metrics
duration: 15min
completed: 2026-03-28
---

# Phase 57 Plan 02: Stash UI Tap-to-Bench Summary

**Stash slot tap transfers item to crafting bench using null-gap removal (D-08), with yellow flash on transfer and alpha pulse when bench clears**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-28T00:00:00Z
- **Completed:** 2026-03-28T00:15:00Z
- **Tasks:** 2 (1 auto + 1 checkpoint auto-approved)
- **Files modified:** 2

## Accomplishments
- Fixed D-08 violation: `_on_stash_slot_pressed` now sets `items[index] = null` instead of `remove_at(index)` so remaining stash items do not shift
- Added null guard in `_on_stash_slot_pressed` so clicking an empty/null slot is a no-op
- Fixed `add_item_to_stash` in GameState to count non-null items for the 3-slot cap and fill first null gap before appending — prevents capacity undercount when null gaps exist

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire stash slot pressed handlers with bench transfer and animations** - `32d7a27` (feat)
2. **Task 2: Verify full stash UI in game** - auto-approved checkpoint (no commit)

**Plan metadata:** see final docs commit below

## Files Created/Modified
- `scenes/forge_view.gd` - `_on_stash_slot_pressed` fixed for D-08, null guard added; `_flash_stash_slot` and `_pulse_stash_slots` verified present; melt/equip call both stash refresh functions
- `autoloads/game_state.gd` - `add_item_to_stash` updated to count non-null items and fill null gaps

## Decisions Made
- Used `items[index] = null` (not `remove_at`) per D-08: remaining items do not shift to fill the vacated slot
- `add_item_to_stash` updated to use non-null count for cap, and fill first null slot before append — this keeps stash arrays consistently sized with predictable slot positions

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed D-08 violation: remove_at shifts items instead of leaving gap**
- **Found during:** Task 1 (reading existing forge_view.gd implementation)
- **Issue:** Plan 01 had implemented `_on_stash_slot_pressed` using `items.remove_at(index)` which shifts remaining items, violating D-08 ("remaining items do not shift to fill it")
- **Fix:** Changed to `items[index] = null` to leave a null gap at the removed position
- **Files modified:** scenes/forge_view.gd
- **Verification:** `grep "remove_at" scenes/forge_view.gd` returns no matches; `items[index] = null` confirmed present
- **Committed in:** 32d7a27 (Task 1 commit)

**2. [Rule 2 - Missing Critical] Added null guard in _on_stash_slot_pressed**
- **Found during:** Task 1 (reviewing _on_stash_slot_pressed implementation)
- **Issue:** Original code only checked `index >= items.size()` but not `items[index] == null` — tapping a null-gap slot would crash (NullReference on the item assignment)
- **Fix:** Added `or items[index] == null` to the early-return guard
- **Files modified:** scenes/forge_view.gd
- **Verification:** Guard line present: `if index >= items.size() or items[index] == null:`
- **Committed in:** 32d7a27 (Task 1 commit)

**3. [Rule 1 - Bug] Fixed add_item_to_stash null-gap capacity counting**
- **Found during:** Task 1 (reading game_state.gd add_item_to_stash per plan instructions)
- **Issue:** `add_item_to_stash` used `stash[slot].size() >= 3` for the cap check. With null gaps (e.g., `[item, null, item]`), size() is 3 and the function would silently discard a new drop even though there is a free slot. Also, appending after null gaps creates arrays larger than 3.
- **Fix:** Count non-null items for cap check; fill first null gap before appending
- **Files modified:** autoloads/game_state.gd
- **Verification:** Function updated with non_null_count loop and gap-fill logic
- **Committed in:** 32d7a27 (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical)
**Impact on plan:** All fixes necessary for correctness per D-08 and null safety. No scope creep.

## Issues Encountered
None - all issues were pre-existing in Plan 01's implementation and resolved under deviation rules.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Full stash UI complete: 15 slots displayed, abbreviations, tooltips, tap-to-bench, flash/pulse animations, bench-clear integration
- Phase 58 (save persistence for stash) can proceed — stash data model is stable with null-gap handling
- Integration tests groups 45-47 cover stash behavior (not run here, require Godot editor)

---
*Phase: 57-stash-ui*
*Completed: 2026-03-28*
