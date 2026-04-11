---
status: partial
phase: 01-hammer-models
source: [01-VERIFICATION.md]
started: 2026-04-11
updated: 2026-04-11
---

## Current Test

[awaiting human testing]

## Tests

### 1. Augment Hammer rejects full Magic item
expected: Apply Augment on a Magic with 1 prefix + 1 suffix -> rejection (no consumption, error toast)
result: [pending]

### 2. Chaos Hammer mod count distribution
expected: Apply Chaos 10x on an empty Rare -> each time 4-6 mods present
result: [pending]

### 3. Exalt Hammer rejects full Rare
expected: Apply Exalt on a Rare with 3 prefix + 3 suffix -> rejection
result: [pending]

### 4. Alchemy Hammer Normal -> Rare with 4-6 mods
expected: Apply Alchemy on Normal -> item becomes Rare with 4-6 mods
result: [pending]

### 5. Divine preserves mod identity, changes values
expected: Record mod IDs + values on Rare, apply Divine, confirm same mod IDs with different values
result: [pending]

### 6. Annulment removes exactly 1 mod
expected: Apply Annulment on Magic/Rare with N>=1 mods -> exactly N-1 mods remain
result: [pending]

### 7. Godot editor loads project without parse errors
expected: Open scenes/forge_view.tscn + scenes/node_2d.tscn -> no red errors in Output panel
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps
