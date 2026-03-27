---
phase: 54-polish-balance
plan: 01
subsystem: ui
tags: [godot, gdscript, forge-view, hero-archetype, bbcode, stat-panel]

# Dependency graph
requires:
  - phase: 53-selection-ui
    provides: Hero selection overlay and BONUS_LABELS const on HeroArchetype
  - phase: 52-save-persistence
    provides: hero_archetype round-trip via from_id() and prestige wipe
  - phase: 50-data-foundation
    provides: HeroArchetype resource with title, color, passive_bonuses, format_bonuses()
provides:
  - Hero title and passive bonus block in ForgeView stat panel (PASS-03)
  - Classless Adventurer guard — null archetype shows no hero section
affects: [prestige-flow, forge-view-display, future-archetype-features]

# Tech tracking
tech-stack:
  added: []
  patterns: [BBCode color tag for archetype-colored title in RichTextLabel, static method call HeroArchetype.format_bonuses()]

key-files:
  created: []
  modified:
    - scenes/forge_view.gd

key-decisions:
  - "Hero title uses BBCode [color=#hex] rather than modulate to allow per-section coloring within a single label"
  - "Classless Adventurer (null archetype) shows no hero section — Offense starts immediately, per D-04"
  - "format_bonuses() called as static HeroArchetype.format_bonuses(archetype.passive_bonuses), not instance method, per D-03"
  - "Hero section prepended before Offense using += appends, replacing old Hero Stats header entirely"

patterns-established:
  - "BBCode [color=#hex] for per-text coloring inside RichTextLabel stat panels"
  - "Null-guard on GameState.hero_archetype before rendering hero section"

requirements-completed: [PASS-03]

# Metrics
duration: 15min
completed: 2026-03-27
---

# Phase 54 Plan 01: Polish-Balance Summary

**Hero title in archetype BBCode color + Passive bonus lines added before Offense section in ForgeView stat panel; classless Adventurer shows no hero header**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-27T00:00:00Z
- **Completed:** 2026-03-27T00:00:00Z
- **Tasks:** 2 (1 auto + 1 human-verify, approved)
- **Files modified:** 1

## Accomplishments

- ForgeView stat panel now shows hero title in archetype color (red/green/blue via BBCode) above the Offense section for heroes with an archetype
- "Passive:" label and formatted bonus lines (e.g., "+25% Attack Damage") displayed before Offense section
- Classless Adventurer (null archetype) shows no hero section — stat panel starts directly at Offense
- Stat comparison hover branches unchanged — hero section stays static during item/equip hover (D-05)
- Fulfills PASS-03, completing the v1.9 Heroes milestone

## Task Commits

Each task was committed atomically:

1. **Task 1: Add hero title and passive bonus block to stat panel** - `61babaa` (feat)
2. **Task 2: Verify hero bonus display in stat panel** - human-verify checkpoint, approved

## Files Created/Modified

- `scenes/forge_view.gd` - Modified `update_hero_stats_display()` to prepend hero archetype block (title + Passive label + bonus lines) before Offense section when `GameState.hero_archetype` is not null

## Decisions Made

- Hero title color uses BBCode `[color=#hex]` rather than `modulate` to allow per-text coloring within the single `hero_stats_label` RichTextLabel (modulate would color the entire label)
- Old `"Hero Stats:\n\nOffense:\n"` initializer removed entirely — hero title serves as header for heroes, classless Adventurer needs no header (per D-04)
- `HeroArchetype.format_bonuses()` called as static method, not instance call, per D-03

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PASS-03 fulfilled — ForgeView hero bonus display complete
- v1.9 Heroes milestone fully delivered: data foundation (Phase 50), spell-mode derivation (Phase 51), save persistence (Phase 52), selection UI (Phase 53), and polish display (Phase 54)
- No blockers or concerns for future phases

---
*Phase: 54-polish-balance*
*Completed: 2026-03-27*
