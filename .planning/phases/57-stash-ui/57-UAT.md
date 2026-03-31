---
status: complete
phase: 57-stash-ui
source: [57-01-SUMMARY.md, 57-02-SUMMARY.md, 57-03 gap closure]
started: 2026-03-31T00:00:00Z
updated: 2026-03-31T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Stash group layout — 5 clearly separated groups with readable labels
expected: ForgeView shows a StashDisplay row with 5 distinct groups (Weapon, Helmet, Armor, Boots, Ring). Each group has a readable label above 3 slot buttons. Groups are clearly separated by visible gaps.
result: pass

### 2. Abbreviation rendering — filled slots show correct codes
expected: Each filled stash slot shows a 2-3 letter abbreviation matching the item type (e.g. W for wand, S for sword). Empty slots are dim/grey.
result: pass

### 3. Tooltip behaviour — hover/long-press shows item details
expected: Hovering or long-pressing a filled stash slot shows a popup with the item's full details (name, rarity, affixes).
result: pass

### 4. Tap-to-bench — item transfers, slot dims
expected: Tapping a filled stash slot moves that item to the crafting bench. The slot becomes empty/dim. The item cannot be put back.
result: pass

### 5. Bench-occupied toast — "Melt or equip first" in header
expected: When bench already has an item, tapping a filled stash slot shows "Melt or equip first" error toast near the top of the screen with a visible dark background.
result: pass

### 6. Yellow flash on transfer
expected: When tapping a filled stash slot (bench empty), a brief yellow flash appears on that slot as the item moves to the bench.
result: skipped
reason: Feature dropped — yellow flash removed per user decision

### 7. Alpha pulse on bench clear
expected: After melting or equipping the bench item, all stash slots play a single clean alpha fade-out/fade-in pulse. No double-pulse or visual pop.
result: pass

## Summary

total: 7
passed: 6
issues: 0
pending: 0
skipped: 1
blocked: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
