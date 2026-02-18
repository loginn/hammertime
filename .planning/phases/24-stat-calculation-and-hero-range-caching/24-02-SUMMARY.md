# Plan 24-02: Hero Range Caching, Range-Based DPS, DPS Item Comparison -- Summary

**Completed:** 2026-02-18
**Status:** Complete
**Commits:** 6a34c89

## What Changed

### models/hero.gd
- Added `damage_ranges` Dictionary field with per-element min/max (physical, fire, cold, lightning)
- Added `calculate_damage_ranges()` method that populates damage_ranges from equipped weapon and ring via `StatCalculator.calculate_damage_range()`
- Weapon contribution uses `weapon.base_damage_min/max` for physical base + all affixes
- Ring contribution uses `ring.base_damage` as both min and max (no range fields on Ring yet)
- Rewrote `calculate_dps()` to use per-element range averages: sum of `(el_min + el_max) / 2.0` across all elements, then multiply by speed and crit
- Speed calculation in `calculate_dps()` reads weapon base_speed and applies speed modifiers from affixes
- Crit multiplier uses hero-level `total_crit_chance` and `total_crit_damage`
- Reordered `update_stats()` to: `calculate_crit_stats()` -> `calculate_damage_ranges()` -> `calculate_dps()` -> `calculate_defense()` (crit and ranges must be ready before DPS)
- `damage_ranges` is NOT serialized -- recalculated from equipment on load via `update_stats()`

### scenes/forge_view.gd
- Updated `is_item_better()` to use DPS comparison for Weapon and Ring types
- Armor/Helmet/Boots still use tier comparison (no DPS field on those types)

## Requirements Addressed
- STAT-01 (complete): Hero tracks per-element min/max damage totals for independent rolling

## Verification
- [x] damage_ranges Dictionary exists with 4 element keys
- [x] calculate_damage_ranges() populates from weapon + ring via StatCalculator
- [x] calculate_dps() uses range averages * speed * crit
- [x] update_stats() order: crit -> ranges -> dps -> defense
- [x] damage_ranges not serialized
- [x] is_item_better() uses DPS for weapon/ring, tier for others

---
*Plan: 24-02 | Phase: 24-stat-calculation-and-hero-range-caching*
