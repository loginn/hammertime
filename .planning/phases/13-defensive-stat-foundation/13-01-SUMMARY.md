---
phase: 13-defensive-stat-foundation
plan: 01
subsystem: defense-calculations
tags: [defense, armor, evasion, energy-shield, resistance, calculator]

dependency_graph:
  requires:
    - phase: 03-unified-calculations
      provides: StatCalculator pattern, static utility class conventions
  provides:
    - DefenseCalculator with full damage mitigation pipeline
    - Hero current_energy_shield tracking
    - Hero apply_damage() defense-aware method
    - Hero recharge_energy_shield() between-fight recovery
  affects: [combat-system, gameplay-loop, hero-stats]

tech_stack:
  added: [DefenseCalculator]
  patterns: [defense-pipeline, diminishing-returns-formula, es-split-model]

key_files:
  created:
    - models/stats/defense_calculator.gd
  modified:
    - models/hero.gd

key_decisions:
  - "K=5 for armor diminishing returns (PoE standard)"
  - "K=200 for evasion diminishing returns (50% dodge at 200 evasion)"
  - "apply_damage() is new method separate from take_damage() for backward compatibility"
  - "ES resets to max on gear change and revive"

patterns_established:
  - "Pattern 1: Defense pipeline as static method returning Dictionary with dodged/life_damage/es_damage"
  - "Pattern 2: ES tracking as mutable float on Hero separate from int total_energy_shield"
  - "Pattern 3: Between-fight recharge as explicit method call (not automatic)"

duration: 3min
completed: 2026-02-16
---

# Phase 13 Plan 01: DefenseCalculator + Hero ES Tracking Summary

**DefenseCalculator with 4-stage damage pipeline (evasion -> resistance -> armor -> ES/life split) and Hero energy shield tracking with mutable current ES, apply_damage(), and 33% between-fight recharge**

## Performance

- **Duration:** 3 min
- **Tasks:** 2
- **Files created:** 1
- **Files modified:** 1

## Accomplishments
- Created DefenseCalculator with 5 static methods implementing full defense pipeline
- Armor uses PoE-style diminishing returns: armor/(armor + 5*damage)
- Evasion uses hyperbolic DR: evasion/(evasion + 200), 75% cap, attacks only
- Resistances clamp at 75% effective with over-cap allowed
- ES splits damage 50/50 with overflow to life when depleted
- Hero tracks current_energy_shield separately from total (max)
- Hero can recharge 33% of max ES between fights
- ES resets on gear change and revive

## Task Commits

1. **Task 1: Create DefenseCalculator with full damage mitigation pipeline** - `6715a10` (feat)
2. **Task 2: Add energy shield tracking and damage application to Hero** - `9542ee3` (feat)

## Files Created/Modified
- `models/stats/defense_calculator.gd` - Static utility class with 5 defense calculation methods
- `models/hero.gd` - Added current_energy_shield, apply_damage(), recharge_energy_shield(), get_current_energy_shield()

## Decisions Made
- K=5 for armor formula (PoE standard, well-understood by ARPG players)
- K=200 for evasion formula (makes 50% dodge achievable at ~200 total evasion from 3 gear slots)
- Created apply_damage() as NEW method rather than modifying take_damage() for backward compatibility
- ES resets to max in update_stats() so gear changes always give full ES

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- DefenseCalculator ready to wire into gameplay_view (Plan 02)
- Hero ES tracking ready for combat integration
- All defense formulas match CONTEXT.md locked decisions

---
*Phase: 13-defensive-stat-foundation*
*Completed: 2026-02-16*
