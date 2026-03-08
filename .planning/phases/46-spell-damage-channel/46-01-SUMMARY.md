---
phase: 46-spell-damage-channel
plan: 01
subsystem: models
tags: [gdscript, stat-calculator, spell-damage, cast-speed]

requires:
  - phase: 45-affix-pool-expansion
    provides: FLAT_SPELL_DAMAGE, INCREASED_SPELL_DAMAGE, INCREASED_CAST_SPEED stat types and spell/DoT affixes
provides:
  - Weapon spell damage fields (base_spell_damage_min/max, base_cast_speed, spell_dps)
  - Ring base_cast_speed and spell_dps fields
  - SapphireRing tier-scaled base_cast_speed values
  - StatCalculator.calculate_spell_damage_range() static method
  - StatCalculator.calculate_spell_dps() static method
affects: [46-02 hero spell aggregation, 46-03 hero view spell display, 47 INT weapons]

tech-stack:
  added: []
  patterns: [spell damage pipeline mirrors attack damage pipeline]

key-files:
  created: []
  modified:
    - models/stats/stat_calculator.gd
    - models/items/weapon.gd
    - models/items/ring.gd
    - models/items/sapphire_ring.gd
    - tools/test/integration_test.gd

key-decisions:
  - "Task execution reordered (03 before 01/02) since Weapon and Ring update_value() depend on StatCalculator spell methods"
  - "Ring passes 0 as base spell damage to calculate_spell_dps since ring spell damage comes from affixes only"

patterns-established:
  - "Spell pipeline mirrors attack pipeline: flat -> %increased -> speed -> crit"
  - "Items with base_cast_speed == 0 produce spell_dps == 0 (no spell channel)"

requirements-completed: [SPELL-03, SPELL-04]

duration: 8min
completed: 2026-03-06
---

# Plan 01: Data Model + StatCalculator Spell Methods Summary

**StatCalculator gains spell damage range and spell DPS methods; Weapon and Ring gain spell damage fields with SapphireRing providing tier-scaled cast speed**

## Performance

- **Duration:** 8 min
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- StatCalculator has calculate_spell_damage_range() and calculate_spell_dps() mirroring the attack pipeline
- Weapon gains base_spell_damage_min/max, base_cast_speed, spell_dps (all default 0)
- Ring gains base_cast_speed and spell_dps; SapphireRing sets tier-scaled cast speed (T8=0.5 to T1=1.2)
- Integration test group 22 validates all spell field defaults, cast speed tiers, and StatCalculator spell methods

## Task Commits

Each task was committed atomically:

1. **Task 03: Add calculate_spell_damage_range() and calculate_spell_dps()** - `cd435f3` (feat)
2. **Task 01: Add spell damage fields to Weapon** - `b17613d` (feat)
3. **Task 02: Add base_cast_speed to Ring/SapphireRing + tests** - `641a561` (feat)

## Files Created/Modified
- `models/stats/stat_calculator.gd` - Added calculate_spell_damage_range() and calculate_spell_dps() static methods
- `models/items/weapon.gd` - Added spell damage fields and spell_dps computation in update_value()
- `models/items/ring.gd` - Added base_cast_speed and spell_dps fields with update_value() integration
- `models/items/sapphire_ring.gd` - Added tier-scaled base_cast_speed to TIER_STATS and _init()
- `tools/test/integration_test.gd` - Added test group 22 for spell damage channel validation

## Decisions Made
- Reordered task execution (03 -> 01 -> 02) since Weapon and Ring update_value() depend on StatCalculator spell methods
- Ring passes 0 as base spell damage since ring spell damage comes entirely from affixes

## Deviations from Plan

None - plan executed as written (task order adjusted for dependency correctness).

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Spell damage fields and StatCalculator methods ready for Hero aggregation (plan 02)
- SapphireRing provides cast speed enabling spell DPS testing end-to-end

---
*Phase: 46-spell-damage-channel*
*Plan: 01*
*Completed: 2026-03-06*
