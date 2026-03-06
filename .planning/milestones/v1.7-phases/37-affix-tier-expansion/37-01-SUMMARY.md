---
phase: 37-affix-tier-expansion
plan: 01
subsystem: game-data
tags: [gdscript, affixes, item-system, balance, save-format]

# Dependency graph
requires:
  - phase: 36-save-format-v3
    provides: "SaveManager v3 with prestige persistence and delete-on-old-version policy"
provides:
  - "All 27 active affix definitions uniformly expanded to Vector2i(1, 32) tier range"
  - "Resistance affixes retuned to base 1,2 (tier-1 ceiling 32-64%, down from 160-384%)"
  - "SAVE_VERSION = 4 with automatic v3 save deletion on load"
affects:
  - 38-item-tier-system
  - 39-tag-currencies
  - affix-system
  - balance

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Uniform 32-tier affix range: all affixes use Vector2i(1, 32); base_min/base_max are tier-32 floor values multiplied by (tier_range.y + 1 - tier)"
    - "Resistance base retuning: lower bases at wider tiers preserve cap safety (1-2% floor, 32-64% ceiling)"
    - "Save version bump pattern: increment SAVE_VERSION, existing delete-on-old-version policy handles cleanup automatically"

key-files:
  created: []
  modified:
    - autoloads/item_affixes.gd
    - autoloads/save_manager.gd

key-decisions:
  - "Resistance bases reduced from 5,12/3,8 to 1,2 so tier-1 ceiling is 32-64% (not game-breaking 160-384%)"
  - "Flat damage affixes preserve element-specific spread ratios: Physical 1:1.5, Lightning 1:4, Fire 1:2.5, Cold 1:2"
  - "Percentage damage affix bases unchanged at 2,10 (tier-1 ceiling 64-320% is acceptable per locked decision)"
  - "Defensive prefix bases unchanged; 30-tier to 32-tier change is minimal (same floor value, ceiling 30x to 32x)"
  - "No affix.quality() function — AFFIX-02 satisfied by uniform 32-tier scale enabling normalized comparison in Phase 38"
  - "No save migration logic — v3 saves deleted on load; backward compatibility not required (no live players)"

patterns-established:
  - "All new affixes must use Vector2i(1, 32) tier range going forward"
  - "Resistance affixes should use low base values (1-2) to keep tier-1 values within game-balance caps"

requirements-completed: [AFFIX-01, AFFIX-02]

# Metrics
duration: 8min
completed: 2026-03-01
---

# Phase 37 Plan 01: Affix Tier Expansion Summary

**27 active affixes uniformly expanded from mixed 5/8/30-tier ranges to Vector2i(1, 32), with resistance bases retuned from 5,12/3,8 to 1,2 (tier-1 ceiling 32-64%), and SAVE_VERSION bumped to 4**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-01T13:19:40Z
- **Completed:** 2026-03-01T13:27:59Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- All 27 active affix definitions now use Vector2i(1, 32) — 10 affixes had explicit range updates (4 flat damage from 8, 4 resistance from 8/5, and All Resistances from 5), 8 had 30->32 changes, 5 percentage damage prefixes gained explicit tier_range, and 5 suffix groups gained explicit tier_range
- Resistance affixes (Fire, Cold, Lightning, All) retuned to base_min=1, base_max=2 — prevents game-breaking tier-1 percentages (old bases would have given 160-384% resistance at tier 1)
- SAVE_VERSION bumped to 4; existing delete-on-old-version policy in load_game() automatically invalidates v3 saves containing old 8/30-tier affix data
- Flat damage element spread ratios preserved exactly: Physical tight (3,5,7,10), Lightning extreme (1,3,8,16), Fire wide (2,4,8,14), Cold moderate (2,5,7,12)
- models/affixes/affix.gd NOT modified — scaling formula locked as specified

## Task Commits

Each task was committed atomically:

1. **Task 1: Expand all affix tier ranges to 32 and retune base values** - `d9d9997` (feat)
2. **Task 2: Bump save version to 4** - `c72560a` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `autoloads/item_affixes.gd` - All 27 active affixes updated to Vector2i(1, 32); resistance bases retuned to 1,2; disabled suffixes untouched; from_affix() unchanged
- `autoloads/save_manager.gd` - SAVE_VERSION constant changed from 3 to 4 only

## Decisions Made
- Resistance bases reduced from 5,12/3,8 to 1,2 — necessary for cap safety at 32-tier scale (old bases produce 160-384% resistance at tier 1, which is game-breaking)
- Percentage damage affix bases kept at 2,10 — tier-1 ceiling of 64-320% is acceptable per pre-existing locked decision
- No affix.quality() function added — AFFIX-02 is satisfied by the uniform 32-tier scale itself, which makes normalized comparison possible when Phase 38 adds item_tier gating

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Affix data foundation complete for Phase 38 (Item Tier System)
- All affixes scaled uniformly 1-32; Phase 38 can gate affix tier access by item_tier using ITEM_TIERS_BY_PRESTIGE
- Phase 39 (Tag Currencies) can proceed — tag distribution in item_affixes.gd is stable
- Pre-prestige floor (tier-32 values) matches old worst-tier values within 10%: Defensive 2-5 flat/1-3%, Flat damage Physical 3-5 min/7-10 max; Resistance tier-32 floor is 1-2% (lower than old 5-12% tier-8 floor, intentional for cap safety)

## Self-Check: PASSED

- FOUND: autoloads/item_affixes.gd (27 occurrences of Vector2i(1, 32), 0 of old ranges)
- FOUND: autoloads/save_manager.gd (SAVE_VERSION = 4)
- FOUND: .planning/phases/37-affix-tier-expansion/37-01-SUMMARY.md
- FOUND commit: d9d9997 (Task 1 — affix tier expansion)
- FOUND commit: c72560a (Task 2 — save version bump)

---
*Phase: 37-affix-tier-expansion*
*Completed: 2026-03-01*
