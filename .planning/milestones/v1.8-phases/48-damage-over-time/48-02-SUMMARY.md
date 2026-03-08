---
phase: 48
plan: 02
title: "DoT Defense & Stat Integration"
status: complete
started: 2026-03-08
completed: 2026-03-08
---

# Plan 02: DoT Defense & Stat Integration — Summary

## What Was Built
Added the defense-side DoT mechanics: a resistance-only damage calculation path in DefenseCalculator for DoT ticks (bypasses evasion and armor), chaos resistance aggregation in hero.gd, and DoT DPS / chaos resistance display in the hero stats panel.

## Key Decisions
- Bleed (physical) DoT passes through at full damage with no resistance reduction, matching PoE convention
- ALL_RESISTANCE does not include chaos resistance (elemental-only, per PoE convention)
- DoT DPS and chaos resistance lines are hidden when zero to avoid clutter

## Key Files
### Modified
- `models/stats/defense_calculator.gd`: Added `calculate_dot_damage_taken()` static method for resistance-only DoT mitigation
- `models/hero.gd`: Added `total_chaos_resistance` variable, aggregation in `calculate_defense()`, and `get_total_chaos_resistance()` getter
- `scenes/forge_view.gd`: Added DoT DPS display in offense section and chaos resistance in defense section

## Self-Check
PASSED — All three verify commands confirmed: DefenseCalculator has the new method (1 match), Hero has chaos resistance tracking (5 matches), ForgeView shows DoT DPS and chaos resistance (6 matches).

## Issues
None
