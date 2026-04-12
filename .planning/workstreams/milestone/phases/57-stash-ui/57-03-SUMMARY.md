---
phase: 57-stash-ui
plan: "03"
subsystem: ui
tags: [gdscript, godot, forge-view, stash, animation, tween]

requires:
  - phase: 57-02
    provides: Stash UI with abbreviation buttons and tooltips wired in forge_view

provides:
  - 24px inter-group gaps in stash display for clear visual separation
  - Yellow flash tween on stash slot when item transfers to bench
  - Bench-occupied guard fires correctly (buttons always enabled for filled slots)
  - Single clean alpha pulse on stash slots (deferred by one frame, no double-pulse)

affects: [58-new-hammers-save-v9]

tech-stack:
  added: []
  patterns:
    - "Flash-after-update: call _flash_stash_slot AFTER _update_stash_display so tween overwrites grey state"
    - "Deferred pulse: call_deferred(_pulse_stash_slots_impl) prevents double-pulse from disabled->enabled theme transition"

key-files:
  created: []
  modified:
    - scenes/forge_view.tscn
    - scenes/forge_view.gd

key-decisions:
  - "_flash_stash_slot tweens from yellow to grey (not white) since slot is now empty after transfer"
  - "Separator positions updated to stay between groups after position changes"
  - "StashDisplay offset_right expanded from 820 to 830 to accommodate wider layout"

patterns-established:
  - "Flash-after-update: call visual tween AFTER display refresh to avoid overwrite"

requirements-completed: [STSH-02, STSH-03, STSH-05]

duration: 15min
completed: 2026-04-12
---

# Phase 57 Plan 03: Stash UI UAT Gap Fixes Summary

**Surgical fixes closing 3 UAT gaps: 24px group gaps with wider stash display, yellow flash tween on slot transfer, bench-occupied guard already active (buttons never disabled)**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-12T00:00:00Z
- **Completed:** 2026-04-12T00:15:00Z
- **Tasks:** 1 of 2 (Task 2 is checkpoint:human-verify)
- **Files modified:** 2

## Accomplishments
- Stash group positions updated to 24px inter-group gaps (Helmet 110, Armor 220, Boots 330, Ring 440)
- StashDisplay width expanded to offset_right=830 to fit wider layout
- Sep1-4 separator positions updated to match new group offsets
- `_flash_stash_slot()` function added — tweens slot modulate to yellow then grey on stash-to-bench transfer
- Flash called AFTER `_update_stash_display()` so the yellow tween overwrites the grey empty state
- Bench-occupied guard was already in place: `btn.disabled = false` in `_update_stash_display`, guard in `_on_stash_slot_pressed` fires correctly
- `_pulse_stash_slots` deferred pattern was already in place via `call_deferred("_pulse_stash_slots_impl")`

## Task Commits

1. **Task 1: Fix stash group separation, bench-occupied toast, and animation bugs** - `1cf9285` (fix)

## Files Created/Modified
- `scenes/forge_view.tscn` - Updated group positions (24px gaps), expanded StashDisplay width, updated separator positions
- `scenes/forge_view.gd` - Added `_flash_stash_slot()`, added flash call after `_update_stash_display` in `_on_stash_slot_pressed`

## Decisions Made
- Flash tweens to grey (not disabled-grey) because the slot IS empty after transfer — `_update_stash_display` already set it to grey, flash just confirms the action visually
- Separator positions: Sep1 at 99-101 (between 86 and 110), Sep2 at 209-211 (between 196 and 220), Sep3 at 319-321 (between 306 and 330), Sep4 at 429-431 (between 416 and 440)

## Deviations from Plan

### Discoveries During Execution

**1. [Rule 1 - Bug already fixed] Bench-occupied guard was already working**
- **Found during:** Task 1
- **Issue:** Plan described `btn.disabled = (GameState.crafting_bench != null)` as the root cause, but this line was already removed in prior execution — `_update_stash_display` already uses `btn.disabled = false` for filled slots
- **Fix:** No action needed — guard fires correctly already
- **Impact:** No code change required for Fix 2

**2. [Rule 1 - Bug already fixed] _pulse_stash_slots deferred pattern already in place**
- **Found during:** Task 1
- **Issue:** Plan described adding call_deferred pattern as needed, but `_pulse_stash_slots_impl` and `call_deferred` were already implemented
- **Fix:** No action needed — deferred pulse and clean modulate reset already present
- **Impact:** No code change required for Fix 3b

**3. [Rule 2 - Missing] _flash_stash_slot did not exist**
- **Found during:** Task 1
- **Issue:** `_flash_stash_slot` function referenced in plan was not yet implemented anywhere in forge_view.gd
- **Fix:** Added function and call site as specified
- **Files modified:** scenes/forge_view.gd
- **Committed in:** 1cf9285

---

**Total deviations:** 3 noted (2 already fixed, 1 missing function added)
**Impact on plan:** All needed code changes applied. Prior plan executions had partially addressed the bugs.

## Issues Encountered
None.

## Known Stubs
None — all stash slot logic is wired to real GameState data.

## Next Phase Readiness
- Task 2 is checkpoint:human-verify — human must verify all 4 checks in game
- Once verified, Phase 57 stash UI is complete
- Phase 58 (new hammers, save v9) already complete per STATE.md

---
*Phase: 57-stash-ui*
*Completed: 2026-04-12*
