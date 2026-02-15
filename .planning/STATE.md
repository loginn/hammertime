# Project State: Hammertime

**Last updated:** 2026-02-15

## Project Reference

**Core Value:** The crafting loop must feel rewarding — finding items, using hammers to shape them, and equipping the result to push further into harder content.

**Current Milestone:** v1.0 Crafting Overhaul

**Current Focus:** Phase 7 - Drop Integration (in progress)

## Current Position

**Phase:** 7 of 8 (v1.0 Crafting Overhaul)

**Plan:** 07-01 complete (Plan 1 of 2)

**Status:** Phase 7 in progress

**Progress:**
```
[█████████░] 93%
v1.0 Milestone Progress: [███████---] 64% (1/2 plans complete in Phase 7)

Phase 5: Item Rarity System        [████] Complete (2/2 plans complete)
Phase 6: Currency Behaviors         [████] Complete (2/2 plans complete)
Phase 7: Drop Integration           [██--] In Progress (1/2 plans complete)
Phase 8: UI Migration               [----] Pending
```

## Performance Metrics

### Milestone: v1.0 Crafting Overhaul

**Target:** Replace basic 3-hammer system with rarity tiers and 6 themed crafting hammers

**Requirements:** 22 total
- Item Rarity: 6 requirements
- Crafting Currencies: 9 requirements
- Drop System: 3 requirements
- UI: 4 requirements

**Coverage:** 22/22 mapped (100%)

**Phases planned:** 4 phases (5-8)

**Started:** 2026-02-15

**Completed:** In progress

**Duration:** TBD

**Current Phase Performance:**
- Phase 5, Plan 1: 96s (2 tasks, 6 files)
- Phase 5, Plan 2: 103s (2 tasks, 3 files)
- Phase 6, Plan 1: 106s (2 tasks, 3 files)
- Phase 6, Plan 2: 87s (2 tasks, 4 files)
- Phase 7, Plan 1: 83s (2 tasks, 2 files)

### Previous Milestone: v0.1 Code Cleanup & Architecture

**Completed:** 2026-02-15 (2 days)

**Stats:** 4 phases, 8 plans, 45 commits, 109 files changed, 1,953 LOC GDScript

**Key outcomes:**
- Formatted 18 GDScript files, added 78 return type hints
- Reorganized 25 files into feature-based folders
- Migrated data classes from Node to Resource
- Created GameState/GameEvents autoloads
- Built unified StatCalculator (removed 96 lines of duplication)
- Replaced get_node() with signal-based communication (33 @onready refs)

## Accumulated Context

### Decisions Made

**v1.0 Milestone Planning (2026-02-15):**
- Phase structure: 5 (Rarity) → 6 (Currencies) → 7 (Drops) → 8 (UI)
- Rarity system as foundation before currency behaviors
- Drop integration before UI to validate full system
- Start phase numbering at 5 (continuing from v0.1)

**v0.1 Milestone (2026-02-14 to 2026-02-15):**
- Resource over Node for data model
- GameState/GameEvents autoloads for state management
- StatCalculator singleton for unified calculations
- Signal-based parent coordination (call down, signal up)
- @onready caching over repeated get_node() calls
- [Phase 05]: Used dictionary-based RARITY_LIMITS instead of match statement for configuration flexibility
- [Phase 05]: Added custom_max_prefixes/suffixes override mechanism for future exotic bases
- [Phase 05]: Applied rarity color via modulate property rather than BBCode for cleaner separation
- [Phase 05]: Chose soft blue (#6888F5) and gold (#FFD700) for Magic/Rare for dark background readability
- [Phase 06]: Set rarity BEFORE calling add_prefix/add_suffix to ensure proper limit enforcement in upgrade hammers
- [Phase 06]: Used template method pattern in base Currency.apply() to enforce consume-only-on-success (CRAFT-09)
- [Phase 06]: Random mod selection uses 50/50 prefix/suffix choice with fallback to alternate type
- [Phase 06]: TackHammer and GrandHammer use same 50/50 prefix/suffix logic as upgrade hammers
- [Phase 06]: ClawHammer preserves rarity when removing mods per CRAFT-05
- [Phase 06]: TuningHammer only rerolls explicit mods (not implicit) per CRAFT-06
- [Phase 07]: LootTable uses static methods (no instance needed, pure utility)
- [Phase 07]: Duplicated mod-addition logic from RunicHammer/ForgeHammer intentionally (drop generation vs crafting)
- [Phase 07]: Area levels beyond 5 use level-5 weights to prevent power creep ceiling

### Active TODOs

**Planning:**
- [x] Create Phase 5 plan (Item Rarity System)
- [x] Create Phase 6 plan (Currency Behaviors)

**Implementation:**
- [x] Phase 6, Plan 1: Currency foundation with upgrade hammers (06-01 complete)
- [x] Phase 6, Plan 2: Modifier hammers (TackHammer, GrandHammer, ClawHammer, TuningHammer) (06-02 complete)

### Known Blockers

**Current:** None

**Resolved:**
- v0.1 complete: Clean architecture foundation established

### Context for Next Session

**What we're building:** v1.0 Crafting Overhaul replacing basic 3-hammer system with Normal/Magic/Rare items and 6 themed crafting hammers

**Where we are:** Phase 7 in progress. LootTable implemented for rarity-weighted item drops. Ready for Plan 07-02 (currency drops).

**Next step:** Execute Phase 7, Plan 2 - Currency Drops (hook hammer drops into enemy loot tables)

**Key context:**
- Rarity system complete: Enum, limits, enforcement, and visual display (Phase 5)
- Currency system complete: All 6 hammers implemented (Phase 6)
  - RunicHammer: Normal → Magic (1-2 mods)
  - ForgeHammer: Normal → Rare (4-6 mods)
  - TackHammer: Add mod to Magic (respects 1+1)
  - GrandHammer: Add mod to Rare (respects 3+3)
  - ClawHammer: Remove random mod (any rarity)
  - TuningHammer: Reroll mod values (any rarity)
- All currencies use template method pattern with consume-only-on-success
- All currencies validate before applying with descriptive error messages

**Files to reference:**
- `.planning/ROADMAP.md` - Phase 7 goals and requirements
- `.planning/REQUIREMENTS.md` - DROP-01 through DROP-03 requirements
- `models/currencies/*.gd` - All 6 hammer implementations
- `models/loot/loot_table.gd` - Rarity-weighted drop system
- `.planning/phases/07-drop-integration/07-01-SUMMARY.md` - LootTable implementation

## Session Continuity

**Previous session:** Phase 6, Plan 2 execution (2026-02-15)

**This session:** Phase 7, Plan 1 execution (2026-02-15)

**Next session:** Phase 7, Plan 2 execution

**Handoff notes:**
- Phase 7 in progress: LootTable implemented for rarity-weighted item drops
- 1/2 plans complete in Phase 7
- DROP-01 and DROP-03 satisfied (area difficulty → rarity, rarity-appropriate mods)
- LootTable uses static methods with weighted random selection
- Forest: 80% Normal, Shadow Realm: 65% Rare
- Magic items: 1-2 mods, Rare items: 4-6 mods
- Ready for Plan 07-02: Currency Drops (hammer loot from enemies)
