# Phase 25: Per-Hit Combat Rolling - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

CombatEngine switches from deterministic per-hit damage (DPS / attack_speed) to per-element range rolling for hero attacks, and from flat pack.damage to randf_range(damage_min, damage_max) for monster attacks. DefenseCalculator interface is unchanged. No UI changes.

</domain>

<decisions>
## Implementation Decisions

### Hero damage rolling
- Roll each element independently: for each element in hero.damage_ranges, roll randf_range(min, max)
- Sum all element rolls into a single total_damage value
- Apply per-hit crit roll to the total (same as current -- randf() < crit_chance, then multiply)
- The result is a single float passed to pack.take_damage() (same interface as current)

### Monster damage rolling
- Replace `pack.damage` with `randf_range(pack.damage_min, pack.damage_max)` in _on_pack_attack()
- The rolled value is passed to DefenseCalculator.calculate_damage_taken() (same interface)

### Crit interaction
- Crit is applied AFTER summing all element rolls (not per-element)
- This matches the current behavior: one crit roll per hero attack, one damage multiplier

### Speed unchanged
- hero_attack_timer cadence stays the same (1.0 / weapon.base_attack_speed)
- pack_attack_timer cadence stays the same (1.0 / pack.attack_speed)
- Speed is NOT removed from DPS for per-hit calculation anymore -- we use raw rolled damage

### Claude's Discretion
- Whether to skip elements with zero range (optimization) or always roll all 4
- How to handle the edge case where hero has no weapon (all ranges zero)
- Whether to extract the rolling logic into a helper method or inline it

</decisions>

<specifics>
## Specific Ideas

- Hero.damage_ranges already populated by Phase 24 -- CombatEngine just reads it
- The old formula `hero.total_dps / hero_attack_speed` is replaced by the per-element roll sum
- The DPS display (hero.total_dps) is NOT changed -- it still shows the expected-value average
- Lightning elements should show wider variance than physical (this is automatic from the range data)

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope.

</deferred>

---

*Phase: 25-per-hit-combat-rolling*
*Context gathered: 2026-02-18*
