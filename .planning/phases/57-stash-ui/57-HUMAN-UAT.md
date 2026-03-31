---
status: diagnosed
phase: 57-stash-ui
source: [57-VERIFICATION.md]
started: 2026-03-28T00:00:00Z
updated: 2026-03-28T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Visual layout — 5 labeled groups of dim grey slots render correctly
expected: ForgeView displays a row of letter-icon squares for each equipment slot type showing stash occupancy, empty stash slots render as dim/greyed squares
result: issue
reported: "Yes, but they are not clearly separated into 5 groups of 3"
severity: minor

### 2. Abbreviation rendering — filled slots show correct 2-3 letter codes
expected: Each filled stash slot shows a 2-3 letter abbreviation matching the item type (e.g. W for wand, S for sword)
result: pass

### 3. Tooltip behaviour — hover shows details; disabled-slot suppression is acceptable
expected: Hovering/long-pressing a stash item shows a popup with the item's full details (name, rarity, affixes)
result: pass

### 4. Tap-to-bench — item transfers, slot dims
expected: Tapping a filled stash square moves that item to the crafting bench; the item is removed from stash and cannot be put back
result: pass

### 5. Bench-occupied toast — "Melt or equip first" appears on blocked tap
expected: When bench is occupied, tapping a stash slot shows "Melt or equip first" error toast
result: issue
reported: "Error toast does not appear"
severity: major

### 6. Flash/pulse animations — yellow flash on transfer; alpha pulse on bench clear
expected: Yellow flash on successful stash-to-bench transfer; alpha pulse on all stash slots when bench clears via melt/equip
result: issue
reported: "Yellow pulse does not appear, alpha pulse works but looks like there's 2 pulses"
severity: major

### 7. Groups 45-47 pass in Godot test runner
expected: Integration test groups 45 (stash display data), 46 (tap-to-bench mutation), 47 (tooltip content) all pass
result: pass

## Summary

total: 7
passed: 4
issues: 3
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "ForgeView displays 5 clearly separated groups of 3 stash slots per equipment type"
  status: failed
  reason: "User reported: Yes, but they are not clearly separated into 5 groups of 3"
  severity: minor
  test: 1
  root_cause: "StashDisplay groups have only 10px gaps, no visual separators, and 9px font labels — insufficient visual distinction"
  artifacts:
    - path: "scenes/forge_view.tscn"
      issue: "VBoxContainer groups at x=0,96,192,288,384 with only 10px gaps, no separators, tiny labels"
  missing:
    - "Increase inter-group gaps to 20-30px or add VSeparator/ColorRect dividers"
    - "Increase group label font size from 9 to 11-12"
  debug_session: ".planning/debug/stash-group-separation.md"

- truth: "When bench is occupied, tapping a stash slot shows 'Melt or equip first' error toast"
  status: failed
  reason: "User reported: Error toast does not appear"
  severity: major
  test: 5
  root_cause: "_update_stash_display() disables buttons when bench occupied (line 394), preventing pressed signal — toast guard in _on_stash_slot_pressed is unreachable dead code"
  artifacts:
    - path: "scenes/forge_view.gd"
      issue: "Line 394 btn.disabled=(crafting_bench!=null) blocks pressed signal; lines 408-410 toast guard never reached"
  missing:
    - "Remove disabled state from bench-occupied condition so pressed signal fires and toast guard can execute"
  debug_session: ".planning/debug/stash-bench-occupied-toast.md"

- truth: "Yellow flash on successful stash-to-bench transfer; alpha pulse on all stash slots when bench clears"
  status: failed
  reason: "User reported: Yellow pulse does not appear, alpha pulse works but looks like there's 2 pulses"
  severity: major
  test: 6
  root_cause: "Two bugs: (1) _flash_stash_slot called before _update_stash_display which clobbers modulate to grey on same frame; (2) disabled-to-enabled theme transition creates visual pop before alpha pulse tween"
  artifacts:
    - path: "scenes/forge_view.gd"
      issue: "Line 424 flash before line 428 _update_stash_display clobbers tween; lines 512-513/557-558 disabled transition + pulse overlap"
  missing:
    - "Move _flash_stash_slot call to after _update_stash_display so tween overwrites grey"
    - "Add frame delay or pre-set modulate before _pulse_stash_slots to prevent double-pulse"
  debug_session: ".planning/debug/stash-animation-bugs.md"
