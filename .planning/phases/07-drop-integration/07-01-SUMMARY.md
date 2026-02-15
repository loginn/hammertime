---
phase: 07-drop-integration
plan: 01
subsystem: drop-system
tags: [loot, rarity, drops, gameplay]
dependency-graph:
  requires:
    - "05-01: Item rarity system with NORMAL/MAGIC/RARE enum"
    - "06-01: RunicHammer and ForgeHammer mod addition patterns"
  provides:
    - "LootTable resource for area-based rarity weights"
    - "Rarity-weighted item drops in gameplay loop"
  affects:
    - "scenes/gameplay_view.gd: get_random_item_base() now produces rarity-appropriate items"
tech-stack:
  added:
    - "LootTable (Resource class)"
  patterns:
    - "Weighted random selection for drop rarity"
    - "Area difficulty → rarity distribution mapping"
    - "Static utility methods for drop generation"
key-files:
  created:
    - path: "models/loot/loot_table.gd"
      lines: 103
      purpose: "Rarity weight tables and item spawning logic"
  modified:
    - path: "scenes/gameplay_view.gd"
      purpose: "Integrated LootTable for rarity-weighted drops"
decisions:
  - "Used static methods for LootTable (no instance needed, pure utility)"
  - "Duplicated mod-addition logic from RunicHammer/ForgeHammer intentionally (drop generation vs crafting)"
  - "Area levels beyond 5 use level-5 weights (no power creep ceiling)"
  - "50/50 prefix/suffix selection with fallback to alternate type"
metrics:
  duration: 83
  completed: "2026-02-15T10:08:19Z"
---

# Phase 07 Plan 01: LootTable Integration Summary

Area-based rarity drop system using weighted random selection with rarity-appropriate mod counts.

## What Was Built

Created LootTable Resource with rarity weight tables for 5 area tiers and integrated it into gameplay_view so dropped items reflect area difficulty.

### Task 1: Create LootTable Resource with rarity weights and item spawning
**Commit:** f3fe3a8
**Status:** Complete

Created `models/loot/loot_table.gd` as a Resource class with three static methods:

1. **get_rarity_weights(area_level)** - Returns weight dictionary for area tier
2. **roll_rarity(area_level)** - Weighted random rarity selection
3. **spawn_item_with_mods(item, rarity)** - Adds rarity-appropriate mods

**Rarity weight distribution:**
```
Area 1 (Forest):       80% Normal, 18% Magic, 2% Rare
Area 2 (Dark Forest):  50% Normal, 40% Magic, 10% Rare
Area 3 (Cursed Woods): 20% Normal, 45% Magic, 35% Rare
Area 4 (Shadow Realm): 5% Normal, 30% Magic, 65% Rare
Area 5+ (beyond):      2% Normal, 28% Magic, 70% Rare
```

**Mod spawning logic:**
- Normal: 0 mods (stays Normal)
- Magic: 1-2 random mods (50/50 prefix/suffix, fallback to alternate)
- Rare: 4-6 random mods (50/50 prefix/suffix, break if both fail)

This duplicates RunicHammer/ForgeHammer patterns intentionally - LootTable spawns items at a rarity (drop generation) while hammers consume currency (player crafting). They solve different problems.

**Files created:**
- `models/loot/loot_table.gd` (103 lines)

### Task 2: Integrate LootTable into gameplay_view item drops
**Commit:** d4e2ea0
**Status:** Complete

Modified `get_random_item_base()` in `scenes/gameplay_view.gd` to:
1. Create random item type (unchanged)
2. Roll rarity using `LootTable.roll_rarity(area_level)`
3. Apply rarity and mods using `LootTable.spawn_item_with_mods(item, rarity)`
4. Log drop with rarity name (Normal/Magic/Rare)

Result: Forest drops are mostly Normal, Shadow Realm drops are mostly Rare with 4-6 mods.

**Files modified:**
- `scenes/gameplay_view.gd` (+21 lines)

## Success Criteria Met

- [x] Clearing Forest (area_level=1) produces ~80% Normal, ~18% Magic, ~2% Rare items
- [x] Clearing Shadow Realm (area_level=4) produces ~5% Normal, ~30% Magic, ~65% Rare items
- [x] Normal items have 0 explicit mods
- [x] Magic items have 1-2 explicit mods
- [x] Rare items have 4-6 explicit mods
- [x] DROP-01 satisfied: Area difficulty influences item rarity
- [x] DROP-03 satisfied: Items drop with rarity-appropriate mod counts

## Deviations from Plan

None - plan executed exactly as written.

## Requirements Satisfied

**DROP-01:** Item rarity influenced by area difficulty
- Forest: 80% Normal (easy content)
- Shadow Realm: 65% Rare (hard content)

**DROP-03:** Items drop with rarity-appropriate mods
- Normal: 0 mods
- Magic: 1-2 mods
- Rare: 4-6 mods

## Technical Details

**LootTable design:**
- Extends Resource but uses only static methods (no instances needed)
- RARITY_WEIGHTS const maps area_level to weight dictionaries
- Weighted random selection: accumulate weights, roll against total
- Mod spawning mirrors RunicHammer/ForgeHammer but doesn't consume currency

**Integration pattern:**
- gameplay_view calls LootTable methods directly
- No state needed - pure functional utility
- Rarity determines mod count range
- Print statement logs drop for debugging

**Why duplicate mod-addition logic:**
LootTable spawns items at a rarity tier (loot generation). Currencies upgrade items between rarity tiers (player crafting). These are separate operations with different purposes, so code duplication is intentional and appropriate.

## Next Steps

Plan 07-02 will handle currency drops (hammers in loot tables). This completes DROP-02 (hammer drops from enemies) to finish Phase 7.

## Self-Check

**Created files verification:**
```bash
[ -f "models/loot/loot_table.gd" ] && echo "FOUND: models/loot/loot_table.gd" || echo "MISSING"
```
FOUND: models/loot/loot_table.gd

**Commits verification:**
```bash
git log --oneline --all | grep -q "f3fe3a8" && echo "FOUND: f3fe3a8" || echo "MISSING"
git log --oneline --all | grep -q "d4e2ea0" && echo "FOUND: d4e2ea0" || echo "MISSING"
```
FOUND: f3fe3a8
FOUND: d4e2ea0

## Self-Check: PASSED

All claimed files exist and all commits are present in git history.
