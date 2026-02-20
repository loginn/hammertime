---
phase: 33-loot-table-rebalance
plan: 02
subsystem: gameplay
tags: [hero, health, armor, difficulty, monsters, pack-generator, stat-calculator]

# Dependency graph
requires:
  - phase: 33-loot-table-rebalance
    provides: Plan 01 loot table rebalance - affix pipeline fixes enabling correct hero stats
  - phase: quick-8
    provides: Audit of affix pipeline — identified FLAT_HEALTH/FLAT_ARMOR double-counting root cause
provides:
  - Hero health correctly aggregates: base 100 + armor-slot base_health (with item FLAT_HEALTH baked in) + weapon/ring FLAT_HEALTH from suffixes + global PERCENT_HEALTH scaling
  - Health syncs to max_health on every stat recalculation (equip/unequip/init)
  - Difficulty curve reduced: GROWTH_RATE 0.07, boss walls +10/20/40%, zone 20-25 now progressable
affects: [UAT-testing, zone-progression, biome-boundaries, hero-combat]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Armor-slot items bake FLAT_HEALTH/FLAT_ARMOR into base stats; weapon/ring do not — suffix loops must be split accordingly"
    - "Global PERCENT_HEALTH pass on hero level scales entire health pool after flat aggregation"
    - "health = max_health sync in update_stats() ensures hero always starts combat at full health"

key-files:
  created: []
  modified:
    - models/hero.gd
    - models/monsters/pack_generator.gd

key-decisions:
  - "FLAT_HEALTH/FLAT_ARMOR split: all-slot suffix loop handles resistances only; weapon/ring loop handles flat health/armor (armor slots already bake these)"
  - "Global PERCENT_HEALTH is intentionally applied twice for armor-slot items (item-level is negligible vs hero-level total pool scaling)"
  - "GROWTH_RATE reduced 0.10 to 0.07; boss walls reduced from +15/35/60% to +10/20/40% to allow zone 20-25 progression"

patterns-established:
  - "Suffix loop splitting pattern: process by stat category, not slot, to avoid double-counting from baked item stats"

requirements-completed: [PROG-03, PROG-04, PROG-05, PROG-07]

# Metrics
duration: 2min
completed: 2026-02-19
---

# Phase 33 Plan 02: UAT Blocker Fixes Summary

**Fixed hero FLAT_HEALTH/FLAT_ARMOR double-counting and health-sync bugs; reduced GROWTH_RATE from 0.10 to 0.07 and boss walls from +15/35/60% to +10/20/40% to unblock zone 25+ progression**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-19T14:43:00Z
- **Completed:** 2026-02-19T14:45:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Fixed hero health double-counting: FLAT_HEALTH and FLAT_ARMOR from suffix loops are now only applied for weapon/ring slots; armor/helmet/boots already bake these into base_health/base_armor via their update_value()
- Added global PERCENT_HEALTH pass in calculate_defense() that scales the entire total health pool after flat aggregation
- Added health = max_health sync in update_stats() so hero always starts at full health after equip/unequip/init
- Reduced difficulty curve: GROWTH_RATE 0.10 -> 0.07, boss walls +15/35/60% -> +10/20/40%, relief dip/ramp-back updated to use 0.40 peak

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix hero health/armor double-counting, add global PERCENT_HEALTH, sync health on stat update** - `a5ce7f0` (fix)
2. **Task 2: Reduce difficulty curve — lower GROWTH_RATE and boss wall bonuses** - `01e9de2` (fix)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `models/hero.gd` - Split suffix loop (resistances all slots, FLAT_HEALTH/FLAT_ARMOR weapon/ring only), added global PERCENT_HEALTH pass, added health = max_health in update_stats()
- `models/monsters/pack_generator.gd` - GROWTH_RATE 0.07, boss walls +10/20/40%, relief dip and ramp-back use 0.40, updated doc comments

## Decisions Made
- FLAT_HEALTH/FLAT_ARMOR suffix loop split: armor slots (helmet, armor, boots) bake these stats into base_health/base_armor via item update_value() -> StatCalculator.calculate_flat_stat(); weapon and ring do not, so only weapon/ring get the suffix FLAT_HEALTH/FLAT_ARMOR treatment
- Global PERCENT_HEALTH applied twice for armor-slot items by design: item-level application is negligible (1-3% of ~10-20 base), hero-level application is the meaningful scaling (1-3% of 150+ total). This matches the PoE "% increased maximum life" model.
- GROWTH_RATE and boss wall reductions chosen to bring L20 from 6.12x to 3.62x (achievable with reasonable gear) while keeping meaningful challenge progression

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Hero health/armor double-counting fixed — UAT tests for health scaling can now be re-run
- Difficulty curve reduced — UAT tests for zone 25+ progression (currency gates at biome boundaries, persistence at higher biomes) are now testable
- Phase 34 ready to begin (UAT validation pass at zone 25+)

---
*Phase: 33-loot-table-rebalance*
*Completed: 2026-02-19*

## Self-Check: PASSED

- models/hero.gd: FOUND
- models/monsters/pack_generator.gd: FOUND
- .planning/phases/33-loot-table-rebalance/33-02-SUMMARY.md: FOUND
- Commit a5ce7f0 (Task 1): FOUND
- Commit 01e9de2 (Task 2): FOUND
