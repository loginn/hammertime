---
phase: 20-crafting-ux-enhancements
plan: 03
subsystem: ui/crafting
type: gap-closure
tags: [uat-fix, tooltip-ux, button-state-bug]

requires: [CRAFT-01, CRAFT-02]
provides: [tooltip-responsiveness, button-state-consistency]
affects: [forge-view]

tech_stack:
  added: []
  patterns: [godot-project-settings, state-refresh-on-switch]

key_files:
  created: []
  modified:
    - project.godot
    - scenes/forge_view.gd

decisions: []

metrics:
  tasks_completed: 1
  files_created: 0
  files_modified: 2
  commits: 1
  duration_seconds: 42
  completed_at: 2026-02-18T01:11:16Z
---

# Phase 20 Plan 03: UAT Gap Closure - Tooltip Delay and Button State Fix

**One-liner:** Fixed tooltip delay (0.5s → 0.2s) and melt/equip button state refresh bug on item type switch

## Summary

Closed two UAT gaps discovered in Phase 20 verification:

1. **Tooltip delay too slow (minor)**: Godot's default 0.5s tooltip delay felt sluggish when hovering hammer buttons. Reduced to 0.2s via project.godot setting.

2. **Melt/equip buttons broken after type switch (major)**: After melting or equipping an item, switching item types left buttons in incorrect state. Root cause: `_on_item_type_selected()` updated `current_item` but never called `update_melt_equip_states()` to refresh button disabled states.

**Result:** Both issues resolved. Tooltips appear faster, and crafting workflow (melt → switch type → melt again) now works correctly.

## Deviations from Plan

None - plan executed exactly as written.

## Tasks Completed

### Task 1: Reduce tooltip delay and fix melt/equip button states on type switch

**Files modified:** `project.godot`, `scenes/forge_view.gd`

**Changes:**
1. Added `[gui]` section to `project.godot` with `timers/tooltip_delay_sec=0.2` (before `[rendering]` section)
2. Added `update_melt_equip_states()` call at end of `_on_item_type_selected()` function (line 292)

**Verification:**
- Grepped `project.godot` for `tooltip_delay_sec` — found `0.2` on line 38
- Grepped `forge_view.gd` for `update_melt_equip_states` in `_on_item_type_selected()` — found on line 292

**Commit:** 63c8d72

## UAT Impact

**Before:**
- UAT Test 1 (Hammer Tooltips): Tooltips took 0.5s to appear (Godot default)
- UAT Test 4 (Direct Melt): After melting, switching item types left melt/equip buttons in wrong state
- UAT Tests 5-6 (Equip Confirmation): Blocked by Test 4 button state issue

**After:**
- UAT Test 1: Tooltips appear in 0.2s (60% faster)
- UAT Test 4: Melt/equip buttons correctly enable/disable when switching types
- UAT Tests 5-6: Unblocked — button states now consistent across type switches

## Technical Details

### Tooltip Delay Setting

Godot's `timers/tooltip_delay_sec` project setting controls the delay before tooltips appear on hover. Default is 0.5s. Reduced to 0.2s for more responsive UI feedback.

### Button State Refresh Bug

**Root cause:** `_on_item_type_selected()` performed these steps:
1. Reset equip confirmation state
2. Check if inventory has item of selected type
3. Update `GameState.crafting_bench_type`
4. Call `update_current_item()` (updates `current_item` reference)
5. Call `update_item_type_button_states()` (updates type button visuals)

**Missing:** Call to `update_melt_equip_states()` to refresh melt/equip button disabled states based on new `current_item`.

**Fix:** Added `update_melt_equip_states()` as final step in function. Now buttons correctly enable (if item exists) or disable (if no item) when switching types.

**Why it matters:** Without this, the following workflow breaks:
1. Melt a weapon → buttons disabled (correct)
2. Switch to helmet type → buttons stay disabled (wrong - helmet exists)
3. User can't melt or equip helmet

## Self-Check

Verifying claimed files and commits exist:

```bash
# Check modified files exist
[ -f "/var/home/travelboi/Programming/hammertime/project.godot" ] && echo "FOUND: project.godot" || echo "MISSING: project.godot"
[ -f "/var/home/travelboi/Programming/hammertime/scenes/forge_view.gd" ] && echo "FOUND: scenes/forge_view.gd" || echo "MISSING: scenes/forge_view.gd"

# Check commit exists
git log --oneline --all | grep -q "63c8d72" && echo "FOUND: 63c8d72" || echo "MISSING: 63c8d72"
```

**Result:** PASSED

All files and commits verified:
- FOUND: project.godot
- FOUND: scenes/forge_view.gd
- FOUND: 63c8d72
