---
phase: 16-drop-system-split
plan: 01
subsystem: loot-system
tags: [currency-drops, per-pack-drops, difficulty-bonus, combat-engine, loot-table]

dependency_graph:
  requires:
    - phase: 15-pack-based-combat-loop
      provides: CombatEngine with _on_pack_killed lifecycle hook
  provides:
    - LootTable.roll_pack_currency_drop() for per-pack currency rolling
    - MonsterPack.difficulty_bonus for drop rate scaling by pack toughness
    - CombatEngine per-pack currency drop wiring with run accumulation
    - GameEvents.currency_dropped signal for UI observation
  affects: [drop-system, phase-16-02, phase-17, gameplay-loop]

tech_stack:
  added: []
  patterns: [per-pack-drop-rolling, difficulty-based-bonus, run-currency-tracking]

key_files:
  created: []
  modified:
    - models/loot/loot_table.gd
    - models/monsters/monster_pack.gd
    - models/monsters/pack_generator.gd
    - models/combat/combat_engine.gd
    - autoloads/game_events.gd

key_decisions:
  - "Two-tier difficulty bonus: 1.0x (normal) and 1.5x (tough) based on monster type base_hp vs biome average"
  - "Added biome parameter to PackGenerator.create_pack() for HP comparison during pack creation"
  - "Per-pack base chances scaled down from per-clear rates for ~12 packs/map average"
  - "Area multiplier formula: 1.0 + log(area_level) * 0.15 giving 1.0x at area 1, ~1.85x at area 300"
  - "run_currency_earned resets on start_combat, accumulates on each pack kill"

patterns_established:
  - "Pattern 1: Per-pack drops via LootTable static method called from CombatEngine._on_pack_killed"
  - "Pattern 2: Run tracking accumulator on CombatEngine for display-only data (actual state in GameState)"
  - "Pattern 3: difficulty_bonus computed at pack creation time, not at drop time — avoids recalculation"

duration: 5min
completed: 2026-02-17
---

# Phase 16 Plan 01: Per-Pack Currency Drops Summary

**Per-pack currency drops with area scaling, area gating, and difficulty bonus wired into CombatEngine pack kill handler**

## Performance

- **Duration:** 5 min
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added difficulty_bonus field to MonsterPack (1.0 normal, 1.5 for above-average HP packs)
- PackGenerator.create_pack() now computes difficulty bonus from biome monster type HP averages
- LootTable.roll_pack_currency_drop() rolls 0-2 currencies per pack with area scaling and gating
- CombatEngine._on_pack_killed() immediately adds currency to GameState and tracks per-run totals
- GameEvents.currency_dropped signal defined and emitted for Phase 17 UI observation

## Task Commits

1. **Task 1: Add difficulty_bonus to MonsterPack and set in PackGenerator** - `33a6843` (feat)
2. **Task 2: Add roll_pack_currency_drop() and wire into CombatEngine** - `e80d83c` (feat)

## Files Created/Modified
- `models/monsters/monster_pack.gd` - Added difficulty_bonus field (1.0 default)
- `models/monsters/pack_generator.gd` - Set difficulty_bonus in create_pack based on biome HP average, added biome parameter
- `models/loot/loot_table.gd` - Added roll_pack_currency_drop() static method
- `models/combat/combat_engine.gd` - Per-pack drop wiring in _on_pack_killed, run_currency_earned accumulator
- `autoloads/game_events.gd` - Added currency_dropped signal

## Decisions Made
- Used two-tier difficulty bonus (1.0/1.5) rather than continuous scaling — simple and clear per CONTEXT.md
- Added biome as optional parameter to create_pack() to maintain backward compatibility with debug_generate
- Per-pack base chances: runic 15%, tack 10%, forge 5%, grand 3%, claw 4%, tuning 4% (before area multiplier)
- Area multiplier uses log scaling for smooth progression without extreme late-game inflation

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Per-pack currency drops functional and wired
- Old per-area-clear currency drops still present (removed in Plan 02)
- Ready for Plan 02: map completion item drops and old drop code removal

---
*Phase: 16-drop-system-split*
*Completed: 2026-02-17*
