---
phase: 39-tag-targeted-currencies
plan: "01"
subsystem: crafting
tags: [gdscript, currencies, tag-hammer, game-state]

# Dependency graph
requires:
  - phase: 38-item-tier-system
    provides: item tier system with _get_affix_tier_floor() for affix floor enforcement
  - phase: 35-prestige-foundation
    provides: tag_currency_counts dictionary on GameState (initialized, saved, wiped on prestige)
provides:
  - TagHammer parameterized currency class (models/currencies/tag_hammer.gd)
  - GameState.spend_tag_currency() helper method
affects: [39-02, forge-view, loot-table]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "TagHammer parameterized class pattern: single class handles all 5 tag types via _init(p_tag, p_name)"
    - "Tag-checked affix replacement: roll all mods randomly, then replace one if no tagged affix landed"
    - "Prefix/suffix type matching in replacement: victim type determines replacement type, cross-type only as last resort"

key-files:
  created:
    - models/currencies/tag_hammer.gd
  modified:
    - autoloads/game_state.gd

key-decisions:
  - "TagHammer uses uppercase tag constants (Tag.FIRE = 'FIRE') matching tag.gd — required_tag.to_lower() used only for display in error messages"
  - "can_apply() checks both Normal rarity and _has_any_matching_affix() so currency is never consumed if no valid mods exist"
  - "_replace_random_affix_with_tagged() skips is_affix_on_item dedup — replacement pool may be tiny and we need to guarantee a tagged affix"

patterns-established:
  - "Tag hammer guarantee pattern: roll all 4-6 mods first, check post-roll, replace one if needed (not pre-filtered rolling)"

requirements-completed: [TAG-01, TAG-02, TAG-03, TAG-04, TAG-05, TAG-06]

# Metrics
duration: 1min
completed: 2026-03-01
---

# Phase 39 Plan 01: Tag-Targeted Currencies Summary

**Single parameterized TagHammer class with 5-type support, guaranteed-tag affix replacement respecting prefix/suffix type boundaries, and GameState.spend_tag_currency() reading from tag_currency_counts**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-01T21:44:51Z
- **Completed:** 2026-03-01T21:46:00Z
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments
- TagHammer parameterized class handles all 5 tag types (fire, cold, lightning, defense, physical) via single `_init(p_tag, p_name)` constructor
- Guaranteed-tag affix logic: rolls 4-6 mods randomly, then replaces one with a tagged affix if none landed — respects prefix/suffix type boundaries
- `_has_any_matching_affix()` pre-check in `can_apply()` ensures no currency consumed when no valid tagged mods exist for the item
- `GameState.spend_tag_currency()` reads from `tag_currency_counts` (not `currency_counts`), placed immediately after `spend_currency()` for consistency

## Task Commits

Each task was committed atomically:

1. **Task 1: Create TagHammer parameterized currency class** - `461da5a` (feat)
2. **Task 2: Add spend_tag_currency() to GameState** - `8c22d6c` (feat)

**Plan metadata:** (pending docs commit)

## Files Created/Modified
- `models/currencies/tag_hammer.gd` - New TagHammer class extending Currency: parameterized init, can_apply/get_error_message/\_do_apply, pool-checking helpers, and type-aware replacement
- `autoloads/game_state.gd` - Added spend_tag_currency() method after spend_currency()

## Decisions Made
- Tag constants are uppercase in the codebase (Tag.FIRE = "FIRE"), so `required_tag.to_lower()` is used only in error message display strings
- `_replace_random_affix_with_tagged()` intentionally skips `is_affix_on_item` dedup check since the replacement pool may be tiny and we need a guaranteed tagged outcome
- Prefix/suffix type matching is strictly maintained: prefix victims get prefix replacements, suffix victims get suffix replacements; cross-type replacement only as absolute last resort

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- TagHammer class ready for Plan 02 to wire 5 forge buttons and drop integration
- `spend_tag_currency()` ready for forge_view to call after successful apply
- Plan 02 needs: forge_view button wiring, loot table drop integration, P1 gating, toast notification for error feedback

## Self-Check: PASSED

- FOUND: models/currencies/tag_hammer.gd
- FOUND: autoloads/game_state.gd
- FOUND: .planning/phases/39-tag-targeted-currencies/39-01-SUMMARY.md
- FOUND commit: 461da5a (TagHammer class)
- FOUND commit: 8c22d6c (spend_tag_currency)

---
*Phase: 39-tag-targeted-currencies*
*Completed: 2026-03-01*
