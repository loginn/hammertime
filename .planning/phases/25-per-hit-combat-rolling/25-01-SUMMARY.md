# Plan 25-01: Per-Element Hero Rolling and Per-Hit Pack Rolling -- Summary

**Completed:** 2026-02-18
**Status:** Complete
**Commits:** fe43224

## What Changed

### models/combat/combat_engine.gd

**_on_hero_attack():**
- Replaced `hero.total_dps / hero_attack_speed` with per-element rolling from `hero.damage_ranges`
- Iterates all 4 elements (physical, fire, cold, lightning)
- Each element with max > 0 is rolled via `randf_range(el_min, el_max)`
- All element rolls summed into single `damage_per_hit`
- Crit applied to the total sum (unchanged behavior -- one crit roll per attack)
- Signal emission `GameEvents.hero_attacked.emit(damage_per_hit, is_crit)` unchanged
- `pack.take_damage(damage_per_hit)` interface unchanged

**_on_pack_attack():**
- Replaced `pack.damage` with `randf_range(pack.damage_min, pack.damage_max)`
- Rolled value passed to `DefenseCalculator.calculate_damage_taken()` as first argument
- All other DefenseCalculator parameters unchanged
- Lightning packs naturally show wider variance than Physical packs (wider min/max spread)

## Requirements Addressed
- CMB-01: Hero attacks roll each element independently, sum, apply crit
- CMB-02: Monster pack attacks roll per-hit from damage range

## Verification
- [x] Hero rolls per-element from damage_ranges
- [x] Crit applied to total after element sum
- [x] Pack uses randf_range(damage_min, damage_max)
- [x] DefenseCalculator interface unchanged
- [x] Signal emissions unchanged

---
*Plan: 25-01 | Phase: 25-per-hit-combat-rolling*
