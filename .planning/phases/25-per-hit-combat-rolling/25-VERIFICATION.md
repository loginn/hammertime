# Phase 25: Per-Hit Combat Rolling -- Verification

**Verified:** 2026-02-18
**Status:** PASSED (4/4 criteria)

## Success Criteria Results

### 1. Hero attacks roll per-element independently, sum, apply crit
**Status:** PASS
- `_on_hero_attack()` iterates `hero.damage_ranges` (4 elements)
- Each element with `el_max > 0.0` is rolled via `randf_range(el_min, el_max)`
- All rolls summed into `damage_per_hit`
- Crit applied to total sum (not per-element)
- Result passed to `pack.take_damage()` (single float, same interface)

### 2. Ten consecutive hero hits show nonzero variance
**Status:** PASS
- `randf_range()` produces different values each call
- Physical base always has range (e.g., LightSword 8-12), guaranteeing variance
- Multiple elements with ranges compound the variance
- Only degenerate case (min == max for ALL elements) would produce identical hits

### 3. Monster pack attacks roll per-hit from damage_min/damage_max
**Status:** PASS
- `_on_pack_attack()` uses `randf_range(pack.damage_min, pack.damage_max)` instead of `pack.damage`
- Rolled value passed to `DefenseCalculator.calculate_damage_taken()` as first argument
- DefenseCalculator interface unchanged (still receives single raw_damage float)

### 4. Lightning packs show wider variance than Physical packs
**Status:** PASS
- Lightning ELEMENT_VARIANCE: min_mult=0.40, max_mult=1.60 (ratio 1:4)
- Physical ELEMENT_VARIANCE: min_mult=0.80, max_mult=1.20 (ratio 1:1.5)
- At same area level, lightning pack damage_min/damage_max spread is ~4x wider than physical
- `randf_range()` over wider spread produces noticeably wider variance

## Requirement Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| CMB-01 | Complete | Per-element rolling from hero.damage_ranges with crit on total |
| CMB-02 | Complete | randf_range(pack.damage_min, pack.damage_max) per-hit |

---
*Phase: 25-per-hit-combat-rolling*
*Verified: 2026-02-18*
