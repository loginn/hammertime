---
status: complete
phase: 37-affix-tier-expansion
source: [37-01-SUMMARY.md]
started: 2026-03-01T14:00:00Z
updated: 2026-03-01T14:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Game launches without errors after affix expansion
expected: Run the game. It should launch and reach the main screen without any errors or crashes related to affix definitions, weapon creation, or item generation.
result: pass

### 2. Crafted affixes show wider value ranges at high tiers
expected: Use a Runic Hammer on a Normal weapon to make it Rare. The affixes rolled should show values from the 32-tier range. For example, a Physical Damage prefix at a high tier should show damage values noticeably higher than the old 8-tier ceiling (previously max was ~8x base, now can be up to 32x base).
result: pass
note: Tier tags (T1-T32) visible on affixes after opening worktree project in Godot.

### 3. Resistance affixes give reasonable values (not game-breaking)
expected: Craft or find an item with a Fire/Cold/Lightning Resistance suffix. Even at the best possible tier (tier 1), the resistance value should be in the 32-96 range (base 1-3 * 32 multiplier), NOT 160+ which would break the 75% cap.
result: pass
note: Bases adjusted from 1-2 to 1-3 during UAT for better per-tier variance.

### 4. Flat damage affixes preserve element flavor
expected: Compare damage affixes across elements on crafted weapons. Lightning Damage should have the widest min-to-max spread (roughly 1:4 ratio), Physical the tightest (roughly 1:1.5), with Fire and Cold in between. The element flavor should still be distinct.
result: pass

### 5. Old save triggers fresh start
expected: If you have an old save file from before this update, loading the game should start fresh (old save deleted). The game should not crash or show corrupt data from old affix definitions.
result: skipped
note: No live players — save migration is low stakes. Clean slate confirmed on first worktree launch.

## Summary

total: 5
passed: 4
issues: 0
pending: 0
skipped: 1
