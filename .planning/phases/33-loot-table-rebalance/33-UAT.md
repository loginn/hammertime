---
status: diagnosed
phase: 33-loot-table-rebalance
source: [33-01-SUMMARY.md]
started: 2026-02-19T14:10:00Z
updated: 2026-02-19T14:25:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Currency gates at biome boundaries
expected: Play to area 25. Before area 25, you should NOT see Forge Hammer currency drops. At or after area 25, Forge Hammer currency should start appearing from pack kills. Similarly, Grand Hammer should not appear until area 50, and Claw/Tuning should not appear until area 75. Runic and Tack currencies should drop from area 1 onward.
result: issue
reported: "Spotted a bug with health calculations, my hero went back to 100 health after dying (i think ?) and it looks like the % health mods are not taken into account ? This prevents me from clearing beyond zone 20. Also difficulty curve is too steep, let's lower the % of progress more."
severity: blocker

### 2. Currency ramp-up on unlock
expected: When a new currency type first unlocks (e.g., Forge Hammer at area 25), drops should be infrequent at first and gradually increase over the next ~12 levels. By area 37 (25+12), Forge Hammer should feel like it's dropping at full rate (~1 per 3-5 packs).
result: pass

### 3. Earlier currencies persist at higher biomes
expected: At area 50+, Runic and Tack currencies should still be dropping at their full rate alongside the newly unlocked Grand Hammer. No earlier currency types should disappear or reduce when new ones unlock.
result: skipped
reason: Can't reach area 50+ due to blocker in test 1

### 4. Items drop from pack kills
expected: When killing individual packs during a map, items should occasionally drop (roughly 1-3 items across an entire map of 8-15 packs). You should see items appearing as you fight packs, not in a batch at the end of the map.
result: pass

### 5. All dropped items are Normal (0 affixes)
expected: Every item that drops from pack kills should have 0 affixes (Normal rarity). No items should drop with pre-rolled mods. The only way to add mods to items should be through the crafting system (hammers).
result: pass

### 6. No item rewards on map completion
expected: When all packs on a map are cleared and the map completes, you should NOT receive any item drops as a map completion reward. Items only come from individual pack kills during the map.
result: pass

### 7. Currency drop rate at full ramp
expected: Once a currency is fully ramped (12+ levels past its unlock), it should drop roughly once every 3-5 packs. At area 50+ with multiple currency types active, you should see a steady flow of various currencies from pack kills.
result: pass

## Summary

total: 7
passed: 5
issues: 1
pending: 0
skipped: 1

## Gaps

- truth: "Hero health reflects all equipped % health mods and syncs on stat update and revive"
  status: failed
  reason: "User reported: hero went back to 100 health after dying, % health mods not taken into account, can't clear beyond zone 20"
  severity: blocker
  test: 1
  root_cause: "calculate_defense() in hero.gd has no post-aggregation PERCENT_HEALTH multiplier — % health mods only scale individual item base_health, not the hero's total pool. Also update_stats() never syncs health = max_health after recalculation. Additionally FLAT_HEALTH from suffixes is double-counted (once in item update_value, once in suffix loop)."
  artifacts:
    - path: "models/hero.gd"
      issue: "calculate_defense() missing global PERCENT_HEALTH pass; update_stats() doesn't sync health to max_health; suffix FLAT_HEALTH double-counted"
  missing:
    - "Add post-aggregation PERCENT_HEALTH multiplier to total_health in calculate_defense()"
    - "Sync health = max_health in update_stats() after calculate_defense()"
    - "Remove duplicate FLAT_HEALTH addition from suffix loop (already baked into item base_health)"
  debug_session: ".planning/debug/phase33-uat-three-issues.md"

- truth: "Difficulty curve allows progression through zone 25 with reasonable gear"
  status: failed
  reason: "User reported: difficulty curve too steep, can't clear beyond zone 20, wants lower % progression"
  severity: blocker
  test: 1
  root_cause: "GROWTH_RATE=0.10 compounds to 6.12x by level 20, boss wall at levels 22-24 adds +15/+35/+60% spikes on top. Combined with health bugs suppressing hero power, the gap is too wide."
  artifacts:
    - path: "models/monsters/pack_generator.gd"
      issue: "GROWTH_RATE=0.10 too steep with current boss wall bonuses (+15/+35/+60%)"
  missing:
    - "Reduce GROWTH_RATE to 0.07-0.08 range"
    - "Reduce boss wall bonuses to +10/+20/+40% range"
  debug_session: ".planning/debug/phase33-uat-three-issues.md"
