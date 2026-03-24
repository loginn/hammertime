---
phase: 50-data-foundation
plan: 01
subsystem: data
tags: [gdscript, godot, hero-archetype, resource, game-state, game-events, integration-tests]

# Dependency graph
requires: []
provides:
  - HeroArchetype Resource class with 9-hero REGISTRY (3 archetypes x 3 subvariants)
  - from_id() static factory returning null-safe HeroArchetype
  - generate_choices() returning exactly 3 heroes (1 per archetype) for prestige selection
  - GameState.hero_archetype nullable field defaulting to null
  - GameEvents.hero_selection_needed and hero_selected signals
  - Group 36 integration tests covering all HERO-01/02/03 requirements
affects:
  - 51-stat-integration (passive_bonuses dict drives stat modifier application)
  - 52-save-load (hero_archetype field serialization)
  - 53-selection-ui (generate_choices() and hero_selected signal for selection screen)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - HeroArchetype extends Resource with static REGISTRY dict (same pattern as Item/MonsterType)
    - Static factory from_id() returning null for unknown ids with push_warning
    - Static generate_choices() with typed Array[HeroArchetype] return for type safety
    - Passive bonuses stored as plain string-keyed Dictionary (not Tag.StatType enum)

key-files:
  created:
    - models/hero_archetype.gd
  modified:
    - autoloads/game_events.gd
    - autoloads/game_state.gd
    - tools/test/integration_test.gd

key-decisions:
  - "HeroArchetype extends Resource (not Node) following existing data model pattern"
  - "Passive bonus keys are plain strings (attack_damage_more, bleed_chance_more, etc.) not Tag.StatType enum values — avoids enum coupling in data layer"
  - "hero_archetype field NOT wired into initialize_fresh_game() or _wipe_run_state() — Phase 52 scope"
  - "generate_choices() picks random id from each archetype bucket ensuring one STR, one DEX, one INT"

patterns-established:
  - "Hero archetype data lives in const REGISTRY dict, not scene/resource files"
  - "Archetype identity via Archetype enum, subvariant via Subvariant enum — type-safe matching"
  - "spell_user bool on HeroArchetype controls INT vs STR/DEX gameplay identity"

requirements-completed: [HERO-01, HERO-02, HERO-03]

# Metrics
duration: 2min
completed: 2026-03-24
---

# Phase 50 Plan 01: Hero Archetype Data Model Summary

**HeroArchetype Resource with 9-hero REGISTRY (3 archetypes x 3 subvariants), null-safe factory, random-selection generator, and wired GameState/GameEvents infrastructure**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-24T17:24:14Z
- **Completed:** 2026-03-24T17:25:51Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Created `models/hero_archetype.gd` with full 9-hero REGISTRY (str_hit/dot/elem, dex_hit/dot/elem, int_hit/dot/elem), static from_id() factory, and static generate_choices() method
- Added `hero_selection_needed` and `hero_selected(archetype: HeroArchetype)` signals to GameEvents
- Added nullable `hero_archetype: HeroArchetype = null` field to GameState
- Added Group 36 integration tests covering HERO-01 (registry count), HERO-02 (from_id, generate_choices, GameState, GameEvents), HERO-03 (titles, colors), and D-07 (spell_user authority)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create HeroArchetype Resource with 9-hero REGISTRY** - `a01629f` (feat)
2. **Task 2: Wire GameEvents signals and GameState field** - `e04551b` (feat)
3. **Task 3: Add Group 36 integration tests for HeroArchetype** - `7cec04f` (test)

**Plan metadata:** (docs commit — see final_commit step)

## Files Created/Modified
- `models/hero_archetype.gd` - HeroArchetype Resource with REGISTRY, from_id(), generate_choices()
- `autoloads/game_events.gd` - Added hero_selection_needed and hero_selected signals
- `autoloads/game_state.gd` - Added hero_archetype: HeroArchetype = null field
- `tools/test/integration_test.gd` - Added Group 36 with ~25 checks for all HERO requirements

## Decisions Made
- Passive bonus keys stored as plain strings (attack_damage_more, bleed_chance_more, etc.) not Tag.StatType enum — avoids enum coupling in data layer, Phase 51 will translate keys to stat types during application
- hero_archetype NOT added to initialize_fresh_game() or _wipe_run_state() — prestige wipe/reset behavior belongs to Phase 52 to avoid scope creep
- generate_choices() uses pick_random() on each archetype's id list — no seeded randomness needed since choices reset on prestige anyway

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- HeroArchetype data model complete. Phase 51 (stat integration) can read passive_bonuses dict and apply modifiers via StatCalculator.
- Phase 52 (save/load) can serialize/deserialize hero_archetype field using hero_id string.
- Phase 53 (selection UI) can call generate_choices() and connect to hero_selected signal.
- No blockers or concerns.

---
*Phase: 50-data-foundation*
*Completed: 2026-03-24*
