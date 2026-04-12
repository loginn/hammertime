---
status: complete
phase: 58-new-hammers-save-v9
source: [58-01-SUMMARY.md, 58-02-SUMMARY.md]
started: 2026-03-31T00:00:00Z
updated: 2026-03-31T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Alteration Hammer rerolls mods on Magic item
expected: Use the Alteration Hammer on a Magic item. All existing mods should be cleared and replaced with 1-2 new random mods. The item stays Magic rarity.
result: pass

### 2. Alteration Hammer rejects non-Magic items
expected: Attempting to use Alteration Hammer on a Normal or Rare item shows a rejection message and does not apply.
result: pass

### 3. Regal Hammer upgrades Magic to Rare
expected: Use the Regal Hammer on a Magic item. The item should become Rare rarity with exactly one additional mod added.
result: blocked
blocked_by: other
reason: "No regal hammers available in current game state to test"

### 4. Regal Hammer rejects non-Magic items
expected: Attempting to use Regal Hammer on a Normal or Rare item shows a rejection message and does not apply.
result: blocked
blocked_by: other
reason: "No regal hammers available — same blocker as test 3"

### 5. Hammer tooltips correct
expected: In ForgeView, hovering over the Alteration Hammer shows "Rerolls all mods on a magic item" and hovering over the Regal Hammer shows "Upgrades a magic item to rare by adding one mod".
result: pass

### 6. Save/load preserves stash and bench
expected: Place items in stash, put one on the crafting bench. Save the game, reload. Stash contents and bench item should be exactly as before save.
result: pass

## Summary

total: 6
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 2

## Gaps

[none yet]
