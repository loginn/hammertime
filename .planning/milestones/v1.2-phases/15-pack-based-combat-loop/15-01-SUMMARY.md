---
phase: 15-pack-based-combat-loop
plan: 01
subsystem: combat
tags: [combat-engine, state-machine, timers, attack-speed, crit, defense-pipeline]

dependency_graph:
  requires:
    - phase: 13-defensive-stat-foundation
      provides: DefenseCalculator with 4-stage damage pipeline
    - phase: 14-monster-pack-data-model
      provides: MonsterPack, PackGenerator with scaling and element selection
  provides:
    - CombatEngine node with state machine (IDLE/FIGHTING/MAP_COMPLETE/HERO_DEAD)
    - Dual independent attack timers (hero and pack)
    - Weapon base_attack_speed property for combat cadence
    - 7 combat signals on GameEvents for UI observation
    - Per-hit crit rolls in combat (separate from DPS expected-value)
  affects: [gameplay-view, combat-ui, phase-15-02, phase-17]

tech_stack:
  added: [CombatEngine]
  patterns: [state-machine-combat, dual-timer-architecture, dps-to-per-hit-conversion]

key_files:
  created:
    - models/combat/combat_engine.gd
  modified:
    - models/items/weapon.gd
    - models/items/light_sword.gd
    - autoloads/game_events.gd

key_decisions:
  - "base_attack_speed is separate from base_speed (DPS multiplier) - two different concepts"
  - "Hero damage per hit = total_dps / hero_attack_speed to remove speed double-counting"
  - "Per-hit crit rolls using randf() rather than expected-value averaging"
  - "auto_retry defaults to true - player retries immediately after death"
  - "Timers created programmatically in _ready() - no .tscn needed for CombatEngine"

patterns_established:
  - "Pattern 1: CombatEngine as Node with child Timer nodes for independent attack cadences"
  - "Pattern 2: State machine enum for combat lifecycle (IDLE -> FIGHTING -> MAP_COMPLETE/HERO_DEAD)"
  - "Pattern 3: DPS / attack_speed conversion for per-hit damage in real-time combat"
  - "Pattern 4: All combat events emitted through GameEvents autoload for decoupled observation"

duration: 4min
completed: 2026-02-16
---

# Phase 15 Plan 01: CombatEngine Core + Weapon Attack Speed Summary

**CombatEngine with dual independent attack timers, state machine combat loop, weapon-based hero attack speed, and 7 combat signals on GameEvents**

## Performance

- **Duration:** 4 min
- **Tasks:** 2
- **Files created:** 1
- **Files modified:** 3

## Accomplishments
- Created CombatEngine node with IDLE/FIGHTING/MAP_COMPLETE/HERO_DEAD state machine
- Dual Timer nodes for independent hero and pack attack cadences
- Hero damage per hit derived from total_dps / attack_speed with per-hit crit rolls
- Pack damage routes through DefenseCalculator full 4-stage pipeline (evasion, resistance, armor, ES split)
- 33% ES recharge between packs, full ES recharge between maps
- Deterministic area progression (area_level + 1 on map clear)
- Auto-retry after death with toggle
- Added base_attack_speed to Weapon (default 1.0), LightSword set to 1.8
- Added 7 combat signals to GameEvents for Phase 17 UI observation

## Task Commits

1. **Task 1: Add base_attack_speed to Weapon and combat signals to GameEvents** - `a4e4391` (feat)
2. **Task 2: Create CombatEngine with state machine and dual attack timers** - `0b6612d` (feat)

## Files Created/Modified
- `models/combat/combat_engine.gd` - CombatEngine node: state machine, dual timers, combat loop
- `models/items/weapon.gd` - Added base_attack_speed property (attacks per second for combat timer)
- `models/items/light_sword.gd` - Set base_attack_speed to 1.8 (fast sword)
- `autoloads/game_events.gd` - Added 7 combat signals (combat_started, pack_killed, hero_attacked, pack_attacked, hero_died, map_completed, combat_stopped)

## Decisions Made
- base_attack_speed (combat timer cadence) kept separate from base_speed (DPS multiplier) to avoid conflating two concepts
- Hero damage per hit = total_dps / hero_attack_speed correctly removes speed from DPS
- Per-hit crit uses randf() roll, not expected-value averaging (DPS display uses expected-value, combat uses real rolls)
- auto_retry defaults true -- player immediately retries on death
- Timers created programmatically in _ready() rather than in .tscn -- CombatEngine is self-contained

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CombatEngine ready for Plan 15-02 to wire into gameplay_view
- PackGenerator.generate_packs() provides fresh packs per map
- DefenseCalculator handles all damage mitigation
- GameEvents signals ready for UI connections

---
*Phase: 15-pack-based-combat-loop*
*Completed: 2026-02-16*
