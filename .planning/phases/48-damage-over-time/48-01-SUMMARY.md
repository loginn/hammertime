---
phase: 48
plan: 01
title: "Core DoT Engine"
status: complete
started: 2026-03-08
completed: 2026-03-08
---

# Plan 01: Core DoT Engine — Summary

## What Was Built
Implemented the complete DoT (Damage over Time) runtime engine: effect tracking on monster packs and hero, proc logic for bleed/poison/burn in CombatEngine hit handlers, 1-second tick timer, stacking rules per DoT type, DPS calculation for hero stats display, and full lifecycle management (clear on kill/death/stop).

## Key Decisions
- Used inline resistance + ES split in `_on_dot_tick()` instead of waiting for Plan 02's `DefenseCalculator.calculate_dot_damage_taken()`, using existing `calculate_resistance_reduction()` and `apply_es_split()` static methods directly
- Pack DoTs on hero use single-stack refresh (simpler than hero-on-pack stacking) as specified
- Hero DoT `process_dot_tick()` returns element alongside type/damage to enable correct resistance application

## Key Files
### Modified
- `autoloads/game_events.gd`: Added dot_applied, dot_ticked, dot_expired signals
- `models/monsters/monster_pack.gd`: Added active_dots tracking, apply_dot (with bleed/poison/burn stacking rules), process_dot_tick, clear_dots, get_dot_count
- `models/hero.gd`: Added 13 DoT stat variables, calculate_dot_stats aggregation, calculate_dot_dps with per-archetype formulas, hero DoT tracking methods (apply_dot, process_dot_tick, clear_dots)
- `models/combat/combat_engine.gd`: Added dot_tick_timer, DoT proc rolls in _on_hero_attack (bleed+poison) and _on_hero_spell_hit (burn), _on_dot_tick processing, pack DoT proc in _on_pack_attack, lifecycle cleanup in all state transitions

## Self-Check
PASSED — All 6 verify commands pass (signal count, method presence, variable/function counts all meet expected thresholds).

## Issues
Task 6 cross-dependency on Plan 02's `DefenseCalculator.calculate_dot_damage_taken()` was resolved by using existing DefenseCalculator static methods directly (resistance reduction + ES split). Plan 02 may refactor this into a dedicated method later.
