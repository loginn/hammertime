---
phase: 13-defensive-stat-foundation
plan: 02
subsystem: gameplay-loop
tags: [defense, combat, gameplay-view, hero-view, energy-shield]

dependency_graph:
  requires:
    - phase: 13-defensive-stat-foundation
      provides: DefenseCalculator, Hero ES tracking
  provides:
    - Defense-aware combat loop in gameplay_view
    - ES display in hero_view stats panel
    - ES recharge between area clears
    - Defense stats display (armor %, dodge %, ES current/max)
  affects: [combat-system, ui-display, hero-view]

tech_stack:
  added: []
  patterns: [defense-pipeline-integration, damage-result-dictionary]

key_files:
  created: []
  modified:
    - scenes/gameplay_view.gd
    - scenes/hero_view.gd

key_decisions:
  - "Removed calculate_monster_damage() entirely rather than wrapping it"
  - "All current damage defaults to physical + is_spell=false until Phase 14"
  - "ES display uses current/max format (e.g., '45/60') in both gameplay and hero views"

patterns_established:
  - "Pattern 1: Combat damage flows through DefenseCalculator.calculate_damage_taken() returning result Dictionary"
  - "Pattern 2: ES recharge called explicitly between clears (not on a timer)"

duration: 3min
completed: 2026-02-16
---

# Phase 13 Plan 02: Wire Defense Into Gameplay Loop + ES Display Summary

**DefenseCalculator wired into gameplay combat loop with full 4-stage pipeline, ES recharge between clears, and defense stats (armor %, dodge %, ES current/max) displayed in gameplay and hero views**

## Performance

- **Duration:** 3 min
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced old calculate_monster_damage() with DefenseCalculator.calculate_damage_taken() full pipeline
- All combat damage now routes through evasion -> resistance -> armor -> ES/life split
- ES recharges 33% between successful area clears
- Gameplay view shows raw monster damage, armor reduction %, evasion dodge %, and ES current/max
- Hero view shows ES as current/max format in stats panel
- Dodge events print "Hero dodged the attack!" feedback
- ES damage split visible in combat output

## Task Commits

1. **Task 1: Wire DefenseCalculator into gameplay_view combat loop** - `fa61035` (feat)
2. **Task 2: Display energy shield in hero_view stats panel** - `93403a6` (feat)

## Files Created/Modified
- `scenes/gameplay_view.gd` - Replaced damage calc with DefenseCalculator pipeline, added ES recharge, defense display
- `scenes/hero_view.gd` - ES display as current/max in stats panel

## Decisions Made
- Removed calculate_monster_damage() entirely instead of wrapping -- cleaner, no dead code
- Default all damage to "physical" + is_spell=false until Phase 14 adds elemental monster types
- ES display in hero_view shows current/max format for clarity

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 5 phase success criteria satisfied (armor, evasion, resistance, ES buffer, ES recharge)
- Defense pipeline ready for Phase 14 elemental damage types (just pass different damage_type string)
- Combat system ready for Phase 15 pack-based combat loop

---
*Phase: 13-defensive-stat-foundation*
*Completed: 2026-02-16*
