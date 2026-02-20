---
phase: 32-biome-compression-and-difficulty-scaling
plan: 01
subsystem: gameplay
tags: [godot, gdscript, monsters, biomes, difficulty-scaling, pack-generation]

# Dependency graph
requires:
  - phase: 15-combat-loop
    provides: MonsterPack consumption — PackGenerator.generate_packs() feeds combat
provides:
  - Compressed biome boundaries (Forest 1-24, Dark Forest 25-49, Cursed Woods 50-74, Shadow Realm 75+)
  - 10% compounding difficulty curve with boss wall / relief / ramp-back pattern
  - Infinite smooth scaling in Shadow Realm (75+)
affects:
  - Any system reading BiomeConfig.get_biome_for_level()
  - Any system reading PackGenerator.get_level_multiplier()
  - Combat loop difficulty expectations
  - Drop scaling (difficulty_bonus still based on biome avg HP)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Boss wall / relief / ramp-back difficulty curve implemented as pure function with BIOME_BOUNDARIES and BIOME_STAT_RATIOS constants
    - Pre-computed stat ratios stored as constants (avoids runtime biome config reads)
    - Quadratic ease-in (t*t) for smooth ramp-back interpolation

key-files:
  created: []
  modified:
    - models/monsters/biome_config.gd
    - models/monsters/pack_generator.gd

key-decisions:
  - "Biomes compressed 4x: Forest 1-24, Dark Forest 25-49, Cursed Woods 50-74, Shadow Realm 75+ (was 100/200/300 spans)"
  - "GROWTH_RATE raised from 0.06 to 0.10 — 10% compounding per level"
  - "Boss walls only at Cursed Woods exit (72-74) and predecessors — Shadow Realm has no repeating boss walls since no biome boundary exists after 75"
  - "Relief dip formula: peak_base * 1.60 * 0.70 / stat_ratio — accounts for biome base HP jumps to ensure genuine relief"
  - "Pre-computed BIOME_STAT_RATIOS (1.63, 0.955, 1.17) stored as constant to avoid runtime BiomeConfig reads"

patterns-established:
  - "Difficulty curve in get_level_multiplier(): ordered checks — relief first, then boss wall, then ramp-back, then base"
  - "Quadratic ease-in ramp-back: t = levels_into_biome/8.0, ease_t = t*t, interpolate relief to base over 7 levels"

requirements-completed: [PROG-01, PROG-02]

# Metrics
duration: 3min
completed: 2026-02-19
---

# Phase 32 Plan 01: Biome Compression and Difficulty Scaling Summary

**Biomes compressed from ~100-level spans to 25-level spans with 10% compounding growth, boss wall spikes at biome exits, relief dips at biome entries (stat-ratio-adjusted), and quadratic ramp-back over 8 levels**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-19T12:40:34Z
- **Completed:** 2026-02-19T12:43:43Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Compressed all four biomes from ~100-level spans to 25-level spans (Forest 1-24, Dark Forest 25-49, Cursed Woods 50-74, Shadow Realm 75+)
- Redesigned `get_level_multiplier()` with 10% compounding base, boss walls (+15/35/60%), stat-adjusted relief dips at biome entries, and quadratic ease-in ramp-back
- Shadow Realm scales infinitely with pure 10% compounding — no repeating boss wall pattern

## Task Commits

Each task was committed atomically:

1. **Task 1: Compress biome level boundaries** - `e3a982d` (feat)
2. **Task 2: Redesign difficulty scaling with boss wall / relief / ramp-back curve** - `6fb79ce` (feat)

**Plan metadata:** `97f6f29` (docs: complete plan)

## Files Created/Modified
- `/var/home/travelboi/Programming/hammertime/models/monsters/biome_config.gd` - Updated biome level boundaries from 100/200/300 spans to 25/50/75; updated doc comment and inline biome comments
- `/var/home/travelboi/Programming/hammertime/models/monsters/pack_generator.gd` - New `get_level_multiplier()` with GROWTH_RATE=0.10, BIOME_BOUNDARIES, BIOME_STAT_RATIOS, boss wall/relief/ramp-back curve; updated class-level and function-level doc comments

## Decisions Made
- GROWTH_RATE raised to 0.10 (10%) — tighter biomes need faster per-level progression to feel impactful
- Relief dip accounts for base stat ratios (BIOME_STAT_RATIOS) so the dip is genuine despite stronger monsters in new biome
- Shadow Realm has no boss walls: since no biome boundary exists after 75, the boss wall loop naturally never triggers for levels 75+ — no special-case logic needed (only the 72-74 wall at Cursed Woods exit exists)
- Pre-computed stat ratios stored as constants to avoid runtime coupling with BiomeConfig

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed incorrect boss wall skip for boundary 75**
- **Found during:** Task 2 (difficulty scaling redesign)
- **Issue:** Initial implementation skipped `boundary == 75` in the boss wall check to "prevent Shadow Realm boss walls", but this incorrectly suppressed the boss wall at levels 72-74 (the Cursed Woods exit wall). The plan explicitly requires boss walls at 72-74.
- **Fix:** Removed the `boundary == 75` skip. Shadow Realm naturally has no boss walls because there is no biome boundary after 75 — the loop condition `level < boundary` can never be satisfied for levels >= 75 with no boundary > 75.
- **Files modified:** models/monsters/pack_generator.gd
- **Verification:** Python simulation confirmed levels 72 (+15%), 73 (+35%), 74 (+60%) spike correctly; levels 83+ return pure `pow(1.1, level-1)`
- **Committed in:** 6fb79ce (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Essential correctness fix — without it, the Cursed Woods boss wall was suppressed. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Biome compression and difficulty redesign complete
- PackGenerator and BiomeConfig ready for any downstream systems reading level multipliers or biome data
- No blockers
- Any downstream display of level numbers (e.g., UI showing "Level 100" as hard content) should be reviewed since the cap is now effectively 75 for biome transitions

## Self-Check: PASSED

- FOUND: models/monsters/biome_config.gd
- FOUND: models/monsters/pack_generator.gd
- FOUND: .planning/phases/32-biome-compression-and-difficulty-scaling/32-01-SUMMARY.md
- FOUND commit: e3a982d (Task 1 — compress biome boundaries)
- FOUND commit: 6fb79ce (Task 2 — redesign difficulty scaling)

---
*Phase: 32-biome-compression-and-difficulty-scaling*
*Completed: 2026-02-19*
