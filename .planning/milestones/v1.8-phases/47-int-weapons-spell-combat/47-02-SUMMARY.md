---
phase: 47-int-weapons-spell-combat
plan: 02
subsystem: combat
tags: [spell-combat, combat-engine, timers, floating-text, save-system]

requires:
  - phase: 47-int-weapons-spell-combat
    provides: INT weapon bases with base_cast_speed and spell damage ranges
provides:
  - CombatEngine spell timer branching on is_spell_user
  - hero_spell_hit signal for spell combat feedback
  - Purple floating text for spell damage display
  - is_spell_user persistence in save system
  - Dev toggle for spell mode in settings
affects: [47-int-weapons-spell-combat]

tech-stack:
  added: []
  patterns: [dual-timer-branching, spell-vs-attack-mode]

key-files:
  created: []
  modified:
    - models/hero.gd
    - models/combat/combat_engine.gd
    - autoloads/game_events.gd
    - scenes/gameplay_view.gd
    - scenes/floating_label.gd
    - autoloads/save_manager.gd
    - scenes/settings_view.gd

key-decisions:
  - "Programmatic CheckButton for spell toggle instead of .tscn edit for simpler maintenance"

patterns-established:
  - "Spell timer parallel to attack timer with is_spell_user branch in _start_pack_fight"

requirements-completed: [SPELL-06]

duration: 2min
completed: 2026-03-07
---

# Phase 47 Plan 02: CombatEngine Spell Timer & Combat Feedback Summary

**Spell combat loop with dedicated spell timer, purple floating damage text, save persistence, and dev toggle**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-07T18:37:54Z
- **Completed:** 2026-03-07T18:40:24Z
- **Tasks:** 7
- **Files modified:** 7

## Accomplishments
- Hero has `is_spell_user` boolean controlling combat mode
- CombatEngine branches between attack and spell timers based on is_spell_user
- Spell hits roll from `spell_damage_ranges`, apply shared crit, emit `hero_spell_hit` signal
- Purple floating text distinguishes spell damage from physical attacks
- is_spell_user persisted in save system with backward-compatible default
- Dev toggle in settings view for testing spell mode

## Task Commits

Each task was committed atomically:

1. **Task 1: Add is_spell_user to Hero** - `5f91b3d` (feat)
2. **Task 2: Add hero_spell_hit signal to GameEvents** - `dbb9fc0` (feat)
3. **Task 3: Wire CombatEngine spell timer** - `196e98c` (feat)
4. **Task 4: Add spell hit floating text in gameplay_view** - `b0af063` (feat)
5. **Task 5: Add spell damage display to floating_label** - `9afd79a` (feat)
6. **Task 6: Persist is_spell_user in save system** - `b22adaf` (feat)
7. **Task 7: Add dev toggle in settings view** - `849102b` (feat)

## Files Created/Modified
- `models/hero.gd` - Added is_spell_user boolean property
- `models/combat/combat_engine.gd` - Added hero_spell_timer, _on_hero_spell_hit(), _get_hero_cast_speed(), updated _start_pack_fight() and _stop_timers()
- `autoloads/game_events.gd` - Added hero_spell_hit signal
- `scenes/gameplay_view.gd` - Connected hero_spell_hit, added handler, extended _spawn_floating_text with is_spell param
- `scenes/floating_label.gd` - Added show_spell_damage() with purple color theme
- `autoloads/save_manager.gd` - Added is_spell_user to save/load with false default
- `scenes/settings_view.gd` - Added programmatic CheckButton dev toggle for spell mode

## Decisions Made
- Used programmatic CheckButton creation instead of .tscn edit for the dev toggle, as recommended by the plan for simpler maintenance

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Spell combat loop fully wired and testable via dev toggle
- Ready for Plan 03 (final plan for Phase 47)

---
*Phase: 47-int-weapons-spell-combat*
*Completed: 2026-03-07*
