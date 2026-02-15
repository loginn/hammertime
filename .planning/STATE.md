# Project State: Hammertime

**Updated:** 2026-02-15
**Milestone:** v1.1 Content & Balance

## Project Reference

**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

**Current Focus:** Extend tag-based affix system to support defensive equipment crafting and introduce area-gated currency progression.

**Architecture:** Godot 4.5 GDScript, feature-based folders (models/, scenes/, autoloads/, utils/), Resource-based data model, signal-based communication, 2,488 LOC across ~25 files.

## Current Position

**Phase:** 9 - Defensive Prefix Foundation
**Plan:** 1/1
**Status:** In Progress
**Progress:** `[==== ........... ]` 25% (1/4 phases complete)

**Next Action:** Continue with Phase 10 (Area-Gated Currency Drops) or Phase 11 (Drop Rate Rebalancing) - both are independent of each other.

## Performance Metrics

**Milestone v1.1:**
- Phases completed: 0/4 (Phase 9 in progress)
- Requirements delivered: 6/18 (defensive prefixes, utility prefixes, percentage stats, tier ranges, stat calculation, item updates)
- Time elapsed: <1 day
- Plans executed: 1
- Tasks completed: 2

| Phase | Plan | Duration | Tasks | Files | Date |
|-------|------|----------|-------|-------|------|
| 09 | 01 | 170s | 2 | 7 | 2026-02-15 |

**Previous milestone (v1.0):**
- Duration: 1 day (2026-02-15)
- Phases: 4 (5-8)
- Plans: 7
- Tasks: 14
- Files changed: 39
- Final LOC: 2,488 GDScript

**Previous milestone (v0.1):**
- Duration: 2 days (2026-02-14 → 2026-02-15)
- Phases: 4 (1-4)
- Plans: 8
- Files changed: 109
- Final LOC: 1,953 GDScript

## Accumulated Context

### Key Decisions

**v1.1 Roadmap (2026-02-15):**
- Derive 4 phases from 18 requirements following research recommendations
- Phase 9-10-11 independent (can parallelize), Phase 12 depends on 9-10-11 completion
- Defensive stats display-only (combat integration deferred to mapping milestone)
- Start with 6 defensive prefixes (flat/% armor/evasion/ES) to avoid affix pool bloat
- Hard gate currencies by area level (clearer than pure RNG)
- Area levels expanded to 1, 100, 200, 300 (from previous 1, 2, 3, 4)

**Phase 09-01 Implementation (2026-02-15):**
- Use Vector2i for configurable tier ranges (backward compatible, 30 tiers for defensive vs 8 for weapon)
- Store base_min/base_max in Affix to prevent double-scaling bug in from_affix()
- Apply percentage modifiers after flat additions using additive stacking
- Defensive/utility prefixes require Tag.DEFENSE to prevent rings from rolling them
- Add evasion/health properties to all defense items for future base type support

### Active TODOs

**Phase 9 preparation:**
- [ ] Establish tag taxonomy (WEAPON_ONLY, ARMOR_ONLY, ANY_ITEM) before adding affixes
- [ ] Define StatType enum additions (FLAT_ARMOR, INCREASED_ARMOR, FLAT_EVASION, INCREASED_EVASION, FLAT_ENERGY_SHIELD, INCREASED_ENERGY_SHIELD)
- [ ] Design UI disclaimer for display-only defensive stats (gray text or "(not yet functional)" label)

**Phase 11 preparation:**
- [ ] Create drop_simulator.gd to validate linear reward curve (not exponential)
- [ ] Test area bonus drop distribution with reduced eligible currency pool

**Phase 12 preparation:**
- [ ] Document baseline drop rates before any changes (current: 1.2 items/clear at area 1, 0.18 magic, 0.02 rare)
- [ ] Define target metrics (goal: 1 rare per 30 clears at area 1)

### Known Issues

- Non-weapon items have no prefix affixes (all prefixes require Tag.WEAPON) — ADDRESSED in Phase 9
- debug_hammers flag in game_state.gd (currently false)

### Fixed Issues

- ~~Light Sword item type button regenerates a free weapon; other types do not~~ - Fixed in quick-01 (2026-02-15)

### Blockers

None currently. All dependencies validated during research phase.

### Deferred Items

**v1.2+ scope:**
- Hybrid defense prefixes (armor+evasion single-slot affixes)
- Visual prefix/suffix separation in UI (color-coded or sectioned)
- Tag-based affix pool tooltips
- Defensive combat integration (damage reduction calculations)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 1 | Fix Light Sword item type button regenerating a free weapon while other types do not | 2026-02-15 | c0bcfb8 | [1-fix-light-sword-item-type-button-regener](./quick/1-fix-light-sword-item-type-button-regener/) |

## Session Continuity

**Last session:** Executed Phase 09 Plan 01 - Defensive Prefix Foundation
- Extended tag system with UTILITY and EVASION tags + 5 new StatType enums
- Made Affix tier_range configurable via Vector2i parameter (default 1-8)
- Fixed double-scaling bug in from_affix() by storing base_min/base_max
- Added 9 new prefixes (6 defensive + 3 utility) with 30-tier range
- Added percentage stat calculation to StatCalculator using additive stacking
- Updated armor/boots/helmet to apply flat + percentage modifiers
- Committed 2 tasks with atomic commits (0c8cf03, 9a4aee1)
- Created SUMMARY.md documenting implementation and decisions

**For next session:**
- Phase 09 complete - ready for Phase 10 (Area-Gated Currency Drops) or Phase 11 (Drop Rate Rebalancing)
- Both Phase 10 and 11 are independent and can be executed in parallel
- Phase 12 (Integration Testing) depends on 9-10-11 completion

---
*State initialized: 2026-02-15*
*Last updated: 2026-02-15*
*Stopped at: Completed 09-01-PLAN.md*
