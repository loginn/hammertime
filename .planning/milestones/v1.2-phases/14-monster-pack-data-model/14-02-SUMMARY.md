---
phase: 14-monster-pack-data-model
plan: 02
subsystem: monsters
tags: [pack-generator, scaling, elemental, weighted-random, exponential-growth]

dependency_graph:
  requires:
    - phase: 14-monster-pack-data-model
      provides: MonsterType, MonsterPack, BiomeConfig Resources
  provides:
    - PackGenerator static utility for generating scaled monster packs
    - get_level_multiplier() exponential scaling (6% per level)
    - roll_element() weighted random element selection
    - generate_packs() complete pack array generation
    - debug_generate() development-time verification
  affects: [combat-system, gameplay-loop, phase-15]

tech_stack:
  added: [PackGenerator]
  patterns: [exponential-scaling, weighted-random-selection, static-generator]

key_files:
  created:
    - models/monsters/pack_generator.gd
  modified: []

key_decisions:
  - "6% growth rate chosen as sweet spot within 5-8% range (42,012x at level 300)"
  - "Weight normalization at roll time for robustness against config errors"
  - "debug_generate() as static method on PackGenerator, not separate test utility"

patterns_established:
  - "Pattern 1: PackGenerator follows LootTable/DefenseCalculator static utility pattern"
  - "Pattern 2: Exponential scaling via pow(1.06, level - 1) for HP and damage"
  - "Pattern 3: Weighted random element selection normalized at roll time"

duration: 3min
completed: 2026-02-16
---

# Phase 14 Plan 02: PackGenerator with Scaling and Element Selection Summary

**PackGenerator static utility producing 8-15 scaled monster packs per map with 6% exponential growth and biome-weighted elemental distribution**

## Performance

- **Duration:** 3 min
- **Tasks:** 2
- **Files created:** 1

## Accomplishments
- Created PackGenerator with 5 static methods following LootTable/DefenseCalculator pattern
- get_level_multiplier() uses pow(1.06, level - 1) for gentle exponential scaling
- roll_element() uses normalized weighted random matching LootTable.roll_rarity() pattern
- create_pack() scales MonsterType base stats by level multiplier (attack speed NOT scaled)
- generate_packs() produces 8-15 packs per map, all at same difficulty level
- debug_generate() prints formatted pack summary with element distribution counts

## Task Commits

1. **Task 1: Create PackGenerator with scaling and element selection** - `416fbce` (feat)
2. **Task 2: Add debug_generate for smoke testing** - `4cf0448` (feat)

## Files Created/Modified
- `models/monsters/pack_generator.gd` - Static utility with generate_packs(), roll_element(), get_level_multiplier(), create_pack(), debug_generate()

## Decisions Made
- Chose 6% growth rate (within user's 5-8% range) as sweet spot between manageable numbers and meaningful scaling
- Normalized weights at roll time rather than requiring biome configs to sum to 1.0 -- more robust
- debug_generate() lives on PackGenerator itself rather than a separate test file -- keeps utility self-contained

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Complete monster pack data model ready for Phase 15: Pack-Based Combat Loop
- PackGenerator.generate_packs(area_level) is the single entry point Phase 15 needs
- Each MonsterPack has hp, damage, attack_speed, element -- all combat needs
- DefenseCalculator (Phase 13) already accepts damage_type string matching pack element

---
*Phase: 14-monster-pack-data-model*
*Completed: 2026-02-16*
