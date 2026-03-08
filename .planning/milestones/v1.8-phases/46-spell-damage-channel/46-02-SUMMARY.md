---
phase: 46-spell-damage-channel
plan: 02
subsystem: ui, models
tags: [godot, gdscript, spell-damage, dps, hero-stats, forge-view]

# Dependency graph
requires:
  - phase: 46-01
    provides: Weapon/Ring spell fields, StatCalculator spell methods, SapphireRing base_cast_speed
provides:
  - Hero tracks spell_damage_ranges and total_spell_dps parallel to attack stats
  - ForgeView displays Attack DPS and Spell DPS separately with hide-zero logic
  - Stat comparison shows both DPS channels for weapon and ring
  - Weapon/Ring tooltips show spell damage, cast speed, spell DPS when applicable
affects: [46-03-spell-combat, 47-int-weapons, 48-dot]

# Tech tracking
tech-stack:
  added: []
  patterns: [dual-dps-channel-display, hide-zero-stat-lines]

key-files:
  created: []
  modified:
    - models/hero.gd
    - scenes/forge_view.gd
    - tools/test/integration_test.gd

key-decisions:
  - "total_dps field NOT renamed in data model — too many references. UI shows 'Attack DPS' label instead."
  - "Spell DPS hidden when zero, Attack DPS always shown as fallback when both are zero."
  - "Hero aggregates base_cast_speed from both weapon and ring — SapphireRing alone enables spell channel."

patterns-established:
  - "Dual DPS channel: Attack DPS and Spell DPS tracked independently through Hero"
  - "Hide-zero display: stat lines hidden when value is zero, at least one always shown"

requirements-completed: [SPELL-05, SPELL-07]

# Metrics
duration: 8min
completed: 2026-03-06
---

# Plan 02: Hero Spell Stats + UI Display Summary

**Hero tracks spell_damage_ranges/total_spell_dps and ForgeView shows dual Attack DPS / Spell DPS channels with hide-zero logic**

## Performance

- **Duration:** 8 min
- **Tasks:** 4
- **Files modified:** 3

## Accomplishments
- Hero.update_stats() now calls calculate_spell_damage_ranges() and calculate_spell_dps() in correct order
- ForgeView hero stats panel shows "Attack DPS" (renamed from "Total DPS") and "Spell DPS" with hide-zero logic
- Stat comparison for weapon/ring shows both Attack DPS and Spell DPS deltas when relevant
- Weapon/Ring tooltips display spell damage, cast speed, and spell DPS when non-zero
- Integration test group 23 validates Hero spell stat tracking with SapphireRing and attack-only equipment

## Task Commits

Each task was committed atomically:

1. **Task 1: Add spell damage tracking to Hero** - `e38a142` (feat)
2. **Task 2: Update ForgeView hero stats display** - `9274713` (feat)
3. **Task 3: Update stat comparison for spell DPS channel** - `425d14c` (feat)
4. **Task 4: Update weapon tooltip for spell damage display** - `60a794d` (feat)

## Files Created/Modified
- `models/hero.gd` - Added spell_damage_ranges, total_spell_dps, calculate_spell_damage_ranges(), calculate_spell_dps(), get_total_spell_dps()
- `scenes/forge_view.gd` - Renamed Total DPS to Attack DPS, added Spell DPS display, updated stat comparison and tooltips
- `tools/test/integration_test.gd` - Added group 23 for Hero spell stat tracking

## Decisions Made
- total_dps field NOT renamed in data model (too many references); UI handles the "Attack DPS" label rename
- Hero aggregates base_cast_speed from both weapon and ring, so SapphireRing alone can enable the spell channel
- When both attack and spell DPS are zero, "Attack DPS: 0.0" is always shown as fallback

## Deviations from Plan
None - plan executed exactly as written

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Hero spell stat pipeline fully wired — ready for CombatEngine spell timer in phase 47
- ForgeView displays both DPS channels — ready for INT weapon bases
- Test group 23 validates the pipeline end-to-end

---
*Phase: 46-spell-damage-channel*
*Completed: 2026-03-06*
