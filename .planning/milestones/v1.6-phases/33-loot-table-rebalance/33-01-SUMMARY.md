---
phase: 33-loot-table-rebalance
plan: 01
subsystem: loot
tags: [gdscript, loot-table, currency, drop-rates, biome-compression]

# Dependency graph
requires:
  - phase: 32-biome-compression-and-difficulty-scaling
    provides: Compressed 25-level biome boundaries (Forest 1-24, Dark Forest 25-49, Cursed Woods 50-74, Shadow Realm 75+)
provides:
  - Currency gates at biome boundaries: forge 25, grand 50, claw/tuning 75
  - 12-level sqrt ramp-up for newly unlocked currencies (~29% rate at unlock, 100% at +12)
  - Per-pack item drops at 18% constant chance (1-3 per map)
  - Normal-only item drops — crafting is sole source of item mods
  - Map completion no longer awards items
affects: [loot, crafting, progression, biomes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-pack item drop: LootTable.roll_pack_item_drop() returns bool, CombatEngine emits items_dropped signal on true"
    - "Sqrt ramp curve for currency unlock: sqrt(levels_since_unlock / ramp_duration) gives immediate-but-low feel"

key-files:
  created: []
  modified:
    - models/loot/loot_table.gd
    - models/combat/combat_engine.gd
    - scenes/gameplay_view.gd
    - autoloads/game_events.gd

key-decisions:
  - "Currency gates moved from 100/200/300 to 25/50/75 to match compressed biome boundaries from Phase 32"
  - "Sqrt ramp curve (not linear) for newly unlocked currencies: immediate but low feel, full rate after 12 levels"
  - "Area multiplier removed from currency drop calculation — no area scaling needed within 25-level biomes"
  - "Items drop per-pack at constant 18% (not on map completion), always as Normal (0 affixes)"
  - "roll_rarity, spawn_item_with_mods, get_map_item_count removed — dead code after Normal-only constraint"

patterns-established:
  - "Normal-only drops: items always drop with 0 affixes; crafting (hammers) is the sole path to item mods"
  - "Per-pack loot: both currency and items resolve on pack kill, not on map completion"

requirements-completed: [PROG-03, PROG-04, PROG-05, PROG-07]

# Metrics
duration: 2min
completed: 2026-02-19
---

# Phase 33 Plan 01: Loot Table Rebalance Summary

**Currency gates compressed to biome boundaries (25/50/75), items now drop per-pack as Normal-only with sqrt ramp-up, map completion rewards removed**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-19T13:59:46Z
- **Completed:** 2026-02-19T14:01:55Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Currency gates retimed to biome boundaries: Forge Hammer at area 25, Grand Hammer at 50, Claw/Tuning at 75
- New currencies ramp from ~29% to full rate over 12 levels using sqrt curve (immediate but low)
- Items drop from pack kills at constant 18% chance (targeting 1-3 per 8-15 pack map), never from map completion
- All dropped items are Normal (0 affixes) — crafting loop is now the sole source of item mods
- Dead code removed: roll_rarity, spawn_item_with_mods, get_map_item_count, area_multiplier scaling

## Task Commits

Each task was committed atomically:

1. **Task 1: Retune currency gates and ramp-up for compressed biomes** - `7f0f02a` (feat)
2. **Task 2: Move item drops to per-pack kills, enforce Normal-only, remove map completion drops** - `3df97c0` (feat)

## Files Created/Modified

- `models/loot/loot_table.gd` - CURRENCY_AREA_GATES updated (25/50/75), ramp_duration=12 with sqrt curve, base chances retuned, area_multiplier removed, roll_pack_item_drop() added, dead rarity/item functions removed
- `models/combat/combat_engine.gd` - Per-pack item drop in _on_pack_killed, map completion item drop removed from _on_map_completed, doc comments updated
- `autoloads/game_events.gd` - items_dropped signal simplified: area_level only (removed item_count param)
- `scenes/gameplay_view.gd` - _on_items_dropped updated to new signal, get_random_item_base simplified to Normal-only (no rarity/mod logic)

## Decisions Made

- Used sqrt curve for currency ramp (not linear): sqrt(progress) gives ~29% at unlock+1, ~50% at +3, ~71% at +6, 100% at +12. This matches the "immediate but low" shape — players see new currency quickly but it takes 12 levels to fully feel it.
- Removed area_multiplier from currency drops: the old 1.0x-1.85x scaling was designed for 300-level ranges. With 25-level biomes, new currencies are introduced at each boundary instead.
- Set PACK_ITEM_DROP_CHANCE = 0.18 constant: 2/11 packs avg = ~2 items per map, no area scaling needed.
- Kept RARITY_ANCHORS dict in loot_table.gd with legacy comment (data retained, not used in active drop path).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Loot system fully aligned with Phase 32's compressed biome structure
- Currency drop rates ready for gameplay testing (forge/runic/tack 25%, grand/claw/tuning 20%)
- Crafting loop is now the primary item progression path — Normal drops provide bases, hammers add mods
- No blockers for remaining phases in Phase 33

## Self-Check: PASSED

- FOUND: models/loot/loot_table.gd
- FOUND: models/combat/combat_engine.gd
- FOUND: scenes/gameplay_view.gd
- FOUND: autoloads/game_events.gd
- FOUND: .planning/phases/33-loot-table-rebalance/33-01-SUMMARY.md
- FOUND: 7f0f02a (Task 1 commit)
- FOUND: 3df97c0 (Task 2 commit)

---
*Phase: 33-loot-table-rebalance*
*Completed: 2026-02-19*
