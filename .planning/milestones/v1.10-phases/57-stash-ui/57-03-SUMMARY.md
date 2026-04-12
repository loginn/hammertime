---
phase: 57-stash-ui
plan: "03"
subsystem: ui
tags: [gdscript, godot, forge-view, stash, animation, tween]

requires:
  - phase: 57-02
    provides: Stash UI with abbreviation buttons and tooltips wired in forge_view

provides:
  - 24px inter-group gaps in stash display (committed but layout fundamentally broken)
  - Yellow flash tween on stash slot (committed but user considers ugly — deferred to UI revamp)
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
  - "UAT revealed stash groups hidden behind hero view — layout approach needs full UI revamp"
  - "Yellow flash committed but user considers it ugly — will redesign during UI revamp"
  - "Bench-occupied toast works correctly — no changes needed"
  - "Redirecting to UI revamp planning instead of further position tweaks"

patterns-established:
  - "Flash-after-update: call visual tween AFTER display refresh to avoid overwrite"

requirements-completed: []

duration: 15min
completed: null
status: partial
---

# Phase 57 Plan 03: Stash UI UAT Gap Fixes Summary

**Applied 3 UAT gap fixes but testing revealed stash layout needs full UI revamp — groups hidden behind hero view**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-12T00:00:00Z
- **Completed:** PARTIAL — redirected to UI revamp
- **Tasks:** 1 of 2 completed
- **Files modified:** 2
- **Status:** partial — user redirecting to UI revamp planning

## Accomplishments
- Stash group positions updated to 24px inter-group gaps (Helmet 110, Armor 220, Boots 330, Ring 440)
- StashDisplay width expanded to offset_right=830 to fit wider layout
- Sep1-4 separator positions updated to match new group offsets
- `_flash_stash_slot()` function added — tweens slot modulate to yellow then grey on stash-to-bench transfer
- Flash called AFTER `_update_stash_display()` so the yellow tween overwrites the grey empty state
- Bench-occupied guard was already in place and fires correctly

## Task Commits

1. **Task 1: Fix stash group separation, bench-occupied toast, and animation bugs** - `1cf9285` (fix) — committed

## UAT Results (Task 2: Human Verification)

1. **Stash groups visually separated** — FAIL: Stash groups are hidden behind the hero view. Layout is fundamentally broken, not fixable with position tweaks alone.
2. **Bench-occupied toast** — PASS: Toast appears correctly when tapping a stash slot with bench occupied.
3. **Yellow flash** — UGLY: Flash works but user considers it visually unappealing. Deferred to planned UI revamp.
4. **Alpha pulse** — Not tested (blocked by layout issue).

## Files Created/Modified
- `scenes/forge_view.tscn` - Updated group positions (24px gaps), expanded StashDisplay width, updated separator positions
- `scenes/forge_view.gd` - Added `_flash_stash_slot()`, added flash call after `_update_stash_display` in `_on_stash_slot_pressed`

## Decisions Made
- Stash layout approach (absolute-positioned groups in StashDisplay) is fundamentally broken — groups render behind the hero view panel
- Position tweaks cannot fix this; needs a full UI revamp of ForgeView layout
- Yellow flash design will be revisited during UI revamp
- User is stopping this plan and redirecting to plan a proper UI revamp

## Deviations from Plan

### UAT Rejection — Layout Fundamentally Broken

**Issue:** Task 1 changes were committed (1cf9285) but Task 2 human verification revealed stash groups are hidden behind the hero view. The layout approach of adjusting group positions within the existing scene tree cannot resolve this because the StashDisplay is layered behind other UI elements.

**Resolution:** User is stopping plan 57-03 and redirecting effort to a full UI revamp that will address the stash layout holistically.

## Issues Encountered
- Stash group layout hidden behind hero view — fundamental scene tree / z-order / layout container issue, not a simple position fix

## Known Stubs
None.

## Next Steps
- Plan a proper UI revamp phase to fix ForgeView layout holistically
- Yellow flash animation to be redesigned during UI revamp
- Bench-occupied toast is working and can be kept as-is

---
*Phase: 57-stash-ui*
*Status: PARTIAL — redirected to UI revamp*
*Last updated: 2026-04-12*
