# Phase 25: Per-Hit Combat Rolling -- Research

**Completed:** 2026-02-18
**Status:** Ready for planning

## Current Architecture

### CombatEngine (_on_hero_attack)
- Current formula: `damage_per_hit = hero.total_dps / hero_attack_speed`
- This removes the speed factor to get a flat per-hit damage
- Per-hit crit roll: `randf() < (crit_chance / 100.0)`, then multiply by `crit_damage / 100.0`
- Result passed to `pack.take_damage(damage_per_hit)`

### CombatEngine (_on_pack_attack)
- Current: passes `pack.damage` (single float) to `DefenseCalculator.calculate_damage_taken()`
- Phase 23 added `pack.damage_min` and `pack.damage_max` fields
- Backward compat: `pack.damage = (damage_min + damage_max) / 2.0` still exists

### Hero damage_ranges (from Phase 24)
- `hero.damage_ranges` Dictionary with keys: "physical", "fire", "cold", "lightning"
- Each value: `{"min": float, "max": float}`
- Already populated from equipped weapon + ring affixes
- Zero-range elements have min=0, max=0

### DefenseCalculator interface
- `calculate_damage_taken(raw_damage, damage_type, is_spell, ...)` -- takes single damage float
- damage_type: "physical", "fire", "cold", "lightning"
- NOT changing in this phase

### Key design questions resolved

**Hero damage rolling approach:**
The hero has per-element damage ranges. Each element should be rolled independently per hit. The total is the sum of all element rolls. Then crit is applied to the total (not per-element).

For a hero with physical 8-12 and fire 10-20:
- Roll physical: randf_range(8.0, 12.0) = 10.3
- Roll fire: randf_range(10.0, 20.0) = 14.7
- Total before crit: 25.0
- Crit roll: if crit, multiply 25.0 by crit_damage/100

This means the rolled damage naturally has variance from ALL element ranges combined.

**Zero-range handling:**
Elements with min=0.0 and max=0.0 produce 0.0 from randf_range(0.0, 0.0). No special handling needed.

**Pack damage rolling approach:**
Simply replace `pack.damage` with `randf_range(pack.damage_min, pack.damage_max)` in `_on_pack_attack()`.

## Risk Assessment

**Low risk:** Only `_on_hero_attack()` and `_on_pack_attack()` change. All interfaces remain the same. The signal emissions remain the same. The defense pipeline remains the same.

**Variance verification:** Success criteria #2 requires 10 consecutive hits to show nonzero variance. This is guaranteed as long as at least one element has a non-degenerate range (min != max). Physical base always has range (8-12 for LightSword), so this is always true with a weapon equipped.

**Lightning wider than Physical:** Success criteria #4 requires lightning packs to show wider variance. This is automatic -- lightning packs have damage_min/damage_max computed with wider ELEMENT_VARIANCE multipliers (0.40/1.60 vs 0.80/1.20).

---
*Research completed: 2026-02-18*
