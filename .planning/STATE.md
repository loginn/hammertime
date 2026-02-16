# Project State: Hammertime

**Updated:** 2026-02-16
**Milestone:** v1.1 Content & Balance

## Project Reference

**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

**Current Focus:** Extend tag-based affix system to support defensive equipment crafting and introduce area-gated currency progression.

**Architecture:** Godot 4.5 GDScript, feature-based folders (models/, scenes/, autoloads/, utils/), Resource-based data model, signal-based communication, 2,488 LOC across ~25 files.

## Current Position

**Phase:** 11 - Currency Area Gating
**Plan:** 1/2
**Status:** In progress
**Progress:** [██████████] 95%

**Next Action:** Continue Phase 11 Plan 02 (Drop rate rebalancing and simulation).

## Performance Metrics

**Milestone v1.1:**
- Phases completed: 2/3 (Phase 9, 10 complete; Phase 11 in progress)
- Requirements delivered: 18/18 (defensive prefixes, utility prefixes, percentage stats, tier ranges, stat calculation, item updates, defense aggregation, hero view sections, item stats display, ring prefixes, elemental resistance split, all-resistance option, resistance display)
- Time elapsed: 1 day
- Plans executed: 4
- Tasks completed: 8

| Phase | Plan | Duration | Tasks | Files | Date |
|-------|------|----------|-------|-------|------|
| 09 | 01 | 170s | 2 | 7 | 2026-02-15 |
| 09 | 02 | 28955s | 2 | 5 | 2026-02-16 |
| 10 | 01 | 130s | 2 | 6 | 2026-02-16 |
| 11 | 01 | 125s | 2 | 2 | 2026-02-16 |

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
| Phase 11 P01 | 125 | 2 tasks | 2 files |

## Accumulated Context

### Key Decisions

**v1.1 Roadmap (2026-02-15):**
- Derive 4 phases from 18 requirements following research recommendations
- Phase 9-10-11 independent (can parallelize), Phase 12 depends on 9-10-11 completion
- Defensive stats display-only (combat integration deferred to mapping milestone)
- Start with 6 defensive prefixes (flat/% armor/evasion/ES) to avoid affix pool bloat
- Hard gate currencies by area level (clearer than pure RNG)
- Area levels expanded to 1, 100, 200, 300 (from previous 1, 2, 3, 4)

**Phase 09 Implementation (2026-02-15 to 2026-02-16):**
- Use Vector2i for configurable tier ranges (backward compatible, 30 tiers for defensive vs 8 for weapon)
- Store base_min/base_max in Affix to prevent double-scaling bug in from_affix()
- Apply percentage modifiers after flat additions using additive stacking
- Defensive/utility prefixes require Tag.DEFENSE to prevent rings from rolling them
- Add evasion/health properties to all defense items for future base type support
- Separate defense type aggregation (armor/evasion/ES) in Hero model
- Hero View shows distinct Offense and Defense sections
- Defense section filters to non-zero values only
- Rename defensive prefixes to descriptive stat names (Flat Armor, % Armor, etc.)
- Add Tag.WEAPON to BasicRing to enable weapon prefix rolling

**Phase 10 Implementation (2026-02-16):**
- Individual resistance suffixes (fire/cold/lightning) replace generic Elemental Reduction for granular defense control
- All-resistance uses narrower tier range (1-5 vs 1-8) for rarity and value balance
- Resistance suffixes roll on all item types (weapons, rings, armor) via Tag.DEFENSE
- All-resistance adds to each individual resistance total (single aggregation loop prevents double-counting)

**Phase 11 Implementation (2026-02-16):**
- Hard gate currencies by area level (1/100/200/300) instead of pure RNG for clearer progression
- Ramp newly unlocked currencies from 10% to 100% over 50 levels to prevent instant abundance
- Distribute bonus drops uniformly to all eligible currencies (not just dropped ones) to prevent starter currency dominance
- Use 0.02 difficulty scaling for expanded 1-300+ area range (prevents absurd multipliers)
- Map area tiers to 1/100/200/300 thresholds for meaningful progression gates
- Hero View displays fire/cold/lightning resistance totals after base defenses (non-zero only)

### Active TODOs

**Phase 9 preparation:**
- [x] Establish tag taxonomy (WEAPON_ONLY, ARMOR_ONLY, ANY_ITEM) before adding affixes - COMPLETE
- [x] Define StatType enum additions (FLAT_ARMOR, INCREASED_ARMOR, FLAT_EVASION, INCREASED_EVASION, FLAT_ENERGY_SHIELD, INCREASED_ENERGY_SHIELD) - COMPLETE
- [x] Design UI disclaimer for display-only defensive stats (gray text or "(not yet functional)" label) - DECIDED: No disclaimer needed, show normally

**Phase 11 preparation:**
- [ ] Create drop_simulator.gd to validate linear reward curve (not exponential)
- [ ] Test area bonus drop distribution with reduced eligible currency pool

**Phase 12 preparation:**
- [ ] Document baseline drop rates before any changes (current: 1.2 items/clear at area 1, 0.18 magic, 0.02 rare)
- [ ] Define target metrics (goal: 1 rare per 30 clears at area 1)

### Known Issues

- debug_hammers flag in game_state.gd (currently false)
- User reported defensive affixes may not be affecting defensive stats (code logic appears correct, may be visual refresh issue - under investigation)

### Fixed Issues

- ~~Light Sword item type button regenerates a free weapon; other types do not~~ - Fixed in quick-01 (2026-02-15)
- ~~Non-weapon items have no prefix affixes (all prefixes require Tag.WEAPON)~~ - Fixed in Phase 09-01 (2026-02-15)
- ~~Rings cannot roll any prefixes~~ - Fixed in Phase 09-02 (2026-02-16) - added Tag.WEAPON to BasicRing
- ~~Defensive prefix names unclear (Armored, Healthy, Evasive)~~ - Fixed in Phase 09-02 (2026-02-16) - renamed to stat names
- ~~UI panel overlap with long stat lists~~ - Fixed in Phase 09-02 (2026-02-16) - increased panel spacing

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

**Last session:** 2026-02-16T01:33:31Z
- Executed Phase 11 Plan 01 - Currency Area Gating
- Added CURRENCY_AREA_GATES constant mapping currencies to unlock levels (1/100/200/300)
- Implemented _calculate_currency_chance() ramping helper (10% → 100% over 50 levels)
- Applied hard gating and ramping to roll_currency_drops() with uniform bonus distribution
- Expanded RARITY_WEIGHTS from 1-5 to 1/100/200/300/500 thresholds
- Updated area naming to tier-based system (Forest/Dark Forest/Cursed Woods/Shadow Realm)
- Adjusted difficulty scaling from 0.5 to 0.02 for expanded 1-300+ area range
- Committed 2 tasks with atomic commits (8ef163b, b5e2c0c)
- Created 11-01-SUMMARY.md documenting implementation and design decisions
- Phase 11 Plan 01 complete - 1/2 plans executed

**For next session:**
- Continue Phase 11 Plan 02 (Drop rate rebalancing and simulation)
- Phase 11 has 1 remaining plan
- All v1.1 milestone requirements delivered (18/18)

---
*State initialized: 2026-02-15*
*Last updated: 2026-02-16*
*Stopped at: Completed 10-01-PLAN.md*
