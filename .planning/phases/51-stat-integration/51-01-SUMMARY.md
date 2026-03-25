---
phase: 51-stat-integration
plan: 01
subsystem: hero-stats
tags: [passive-bonuses, archetype, hero, stat-integration, dot, spell-mode]
dependency_graph:
  requires: [50-01]
  provides: [archetype-bonus-injection, is-spell-user-derivation, group-37-tests]
  affects: [models/hero.gd, scenes/settings_view.gd, autoloads/save_manager.gd, tools/test/integration_test.gd]
tech_stack:
  added: []
  patterns: [null-guarded-bonus-injection, derived-property-over-stored, element-map-for-spell-routing]
key_files:
  created: []
  modified:
    - models/hero.gd
    - scenes/settings_view.gd
    - autoloads/save_manager.gd
    - tools/test/integration_test.gd
decisions:
  - is_spell_user derived from archetype at top of update_stats() — no manual toggle anywhere
  - Bonus application order: element-specific first, then channel-wide, then general
  - Spell element map: physical->spell, fire->spell_fire, lightning->spell_lightning
  - DoT damage bonuses converted from decimal to percentage (0.15 -> +15.0 pct)
  - Old saves with is_spell_user field are harmlessly ignored (value derived on load)
metrics:
  duration: "~20 minutes"
  completed: "2026-03-25"
  tasks_completed: 3
  files_modified: 4
---

# Phase 51 Plan 01: Stat Integration Summary

Wire archetype passive bonuses into Hero.update_stats() as multiplicative "more" modifiers, derive is_spell_user from archetype, and remove the obsolete spell mode toggle and save field.

## What Was Built

Three targeted changes across four files:

**models/hero.gd** — Three bonus injection blocks added:
1. `is_spell_user` derivation as the first statement of `update_stats()`: reads `GameState.hero_archetype.spell_user` if archetype is non-null, else false.
2. `calculate_damage_ranges()`: after ring contribution, applies element-specific bonuses (physical/fire/cold/lightning_damage_more), then channel bonus (attack_damage_more on all elements), then general (damage_more on all elements).
3. `calculate_spell_damage_ranges()`: after ring contribution, applies element bonuses via spell_element_map (physical->spell, fire->spell_fire, lightning->spell_lightning), then channel (spell_damage_more), then general (damage_more). Note: attack_damage_more is NOT applied here.
4. `calculate_dot_stats()`: before `calculate_dot_dps()` call, multiplies total_X_chance by (1 + X_chance_more) and adds X_damage_more * 100.0 to total_X_damage_pct.

**scenes/settings_view.gd** — Removed all 4 sites of spell_mode_toggle:
- Field declaration (`var spell_mode_toggle: CheckButton`)
- 6-line block in `_ready()` creating and connecting the CheckButton
- `_on_spell_mode_toggled()` function (3 lines)
- `reset_state()` assignment line

**autoloads/save_manager.gd** — Removed `is_spell_user` from both:
- `_build_save_data()`: removed `"is_spell_user": GameState.hero.is_spell_user` from return dict
- `_restore_state()`: removed `GameState.hero.is_spell_user = bool(data.get(...))` restore line

**tools/test/integration_test.gd** — Added `_group_37_stat_integration()` (Group 37) with 12 test cases covering all PASS-01, PASS-02, and D-02 requirements.

## Commits

| Hash | Message |
|------|---------|
| e127fef | feat(51-01): derive is_spell_user from archetype; remove spell mode toggle and save field |
| 2ab77ba | feat(51-01): inject archetype passive bonuses into hero calculate_* functions |
| fc909d6 | test(51-01): add Group 37 integration tests for stat integration |

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None — all archetype bonus paths are fully wired. Group 37 tests will produce non-trivial assertions when a hero archetype is set in GameState.

## Verification Results

1. `grep "spell_mode_toggle" scenes/settings_view.gd` — 0 matches (toggle fully removed)
2. `grep "is_spell_user" autoloads/save_manager.gd` — 0 matches (save field removed)
3. `grep -c "GameState.hero_archetype" models/hero.gd` — 7 lines (1 derivation line with 2 refs + 2 lines per 3 injection blocks)
4. `grep "stat_calculator" models/hero.gd` — 0 new references (StatCalculator untouched)
5. `grep -c "_group_37_stat_integration" tools/test/integration_test.gd` — 2 (1 call + 1 definition)
6. Group 37 contains 18+ `_check()` calls covering all required test scenarios

## Self-Check: PASSED

All modified files exist, all commits recorded, all acceptance criteria verified via grep.
