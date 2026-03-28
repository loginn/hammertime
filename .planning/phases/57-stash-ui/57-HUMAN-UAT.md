---
status: partial
phase: 57-stash-ui
source: [57-VERIFICATION.md]
started: 2026-03-28T00:00:00Z
updated: 2026-03-28T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Visual layout — 5 labeled groups of dim grey slots render correctly
expected: ForgeView displays a row of letter-icon squares for each equipment slot type showing stash occupancy, empty stash slots render as dim/greyed squares
result: [pending]

### 2. Abbreviation rendering — filled slots show correct 2-3 letter codes
expected: Each filled stash slot shows a 2-3 letter abbreviation matching the item type (e.g. W for wand, S for sword)
result: [pending]

### 3. Tooltip behaviour — hover shows details; disabled-slot suppression is acceptable
expected: Hovering/long-pressing a stash item shows a popup with the item's full details (name, rarity, affixes)
result: [pending]

### 4. Tap-to-bench — item transfers, slot dims
expected: Tapping a filled stash square moves that item to the crafting bench; the item is removed from stash and cannot be put back
result: [pending]

### 5. Bench-occupied toast — "Melt or equip first" appears on blocked tap
expected: When bench is occupied, tapping a stash slot shows "Melt or equip first" error toast
result: [pending]

### 6. Flash/pulse animations — yellow flash on transfer; alpha pulse on bench clear
expected: Yellow flash on successful stash-to-bench transfer; alpha pulse on all stash slots when bench clears via melt/equip
result: [pending]

### 7. Groups 45-47 pass in Godot test runner
expected: Integration test groups 45 (stash display data), 46 (tap-to-bench mutation), 47 (tooltip content) all pass
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps
