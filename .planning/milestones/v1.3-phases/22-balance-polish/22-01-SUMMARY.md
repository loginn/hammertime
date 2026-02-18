---
phase: 22-balance-polish
plan: 01
subsystem: balance-ui
tags: [balance, starter-gear, monster-stats, debug-flag, ui-polish]

# Dependency graph
requires:
  - phase: 14-monster-pack-data-model
    provides: BiomeConfig with MonsterType.create() base stats
  - phase: 18-save-load-foundation
    provides: GameState.initialize_fresh_game() with currency_counts
provides:
  - 1 starter Runic Hammer on fresh game
  - Reduced Forest biome monster base HP/damage (~40%)
  - debug_hammers disabled for production
  - Verified stat panel sizing (no changes needed)
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - autoloads/game_state.gd
    - models/monsters/biome_config.gd

key-decisions:
  - "40% flat reduction to Forest monster base_hp and base_damage (not a multiplier)"
  - "Attack speeds unchanged to preserve monster type identity"
  - "Only Forest biome reduced; other biomes remain unchanged"
  - "Stat panel sizing already adequate at font size 11 — no .tscn changes needed"

patterns-established: []

requirements-completed: [BAL-01, BAL-02, UI-01]

# Metrics
duration: 5min
completed: 2026-02-18
---

# Plan 22-01 Summary: Balance & Polish

**Starter gear, Forest difficulty reduction, debug flag disable, stat panel verification**

## Performance

- **Duration:** 5 min
- **Tasks:** 2 (1 code change, 1 verification-only)
- **Files modified:** 2

## Accomplishments
- Fresh game now starts with 1 Runic Hammer so player can craft their first magic weapon
- Forest biome monsters reduced ~40% HP and damage for survivable level 1 experience
- debug_hammers set to false (was giving 999 of each hammer on every start)
- HeroStatsPanel verified: 410x410px content area fits worst-case 14-line display at font size 11

## Task Commits

Each task was committed atomically:

1. **Task 1: Starter gear, monster rebalance, and debug flag** - `d9702a8` (feat)
2. **Task 2: Stat panel verification** - No commit (verification confirmed existing sizing is adequate, no changes needed)

## Files Created/Modified
- `autoloads/game_state.gd` - debug_hammers=false, runic starts at 1
- `models/monsters/biome_config.gd` - Forest monster base stats reduced ~40%

## Decisions Made
- Applied flat 40% reduction rather than a level-dependent multiplier — simpler, more transparent, exponential growth naturally scales stats back up at higher levels
- Did not change attack speeds — fast monsters (Spider 1.8, Sprite 2.0) are still fast but deal less damage per hit
- Stat panel needed no changes — current 11pt font with 410px height handles worst-case 14-line display

## Deviations from Plan
- forge_view.tscn listed in files_modified but not actually changed (verification confirmed no changes needed for UI-01)

## Issues Encountered
None

## User Setup Required
None

## Next Phase Readiness
- BAL-01, BAL-02, UI-01 complete — all Phase 22 requirements delivered
- v1.3 milestone complete (all 22 phases done)

---
*Phase: 22-balance-polish*
*Completed: 2026-02-18*
