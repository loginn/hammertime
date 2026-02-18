# Phase 24: Stat Calculation and Hero Range Caching - Context

**Gathered:** 2026-02-18 (updated: 2026-02-18)
**Status:** Updated with gap closure decisions

<domain>
## Phase Boundary

StatCalculator gains a new `calculate_damage_range()` method that accumulates per-element min and max totals independently from equipped weapon and affixes. Hero caches these range totals after equip/load for combat use. DPS display uses the range average. No UI format changes -- DPS still shows a single number.

</domain>

<decisions>
## Implementation Decisions

### Accumulation approach
- Dual-accumulator: separate min and max tracking per element throughout the calculation
- Percentage modifiers (e.g., +10% fire) scale both min and max independently -- a 10-20 fire affix with +10% fire mod produces 11-22, not 15-15
- Physical base damage range comes from Weapon.base_damage_min/max (Phase 23)
- Flat damage affix ranges come from Affix.add_min/add_max (Phase 23)
- Element identification uses existing tag system (Tag.PHYSICAL, Tag.FIRE, Tag.COLD, Tag.LIGHTNING)

### Hero range caching
- Hero exposes per-element total_damage_min and total_damage_max
- Populated after equip and recalculated on load -- NOT serialized (derived from equipment state)
- These cached values are what CombatEngine reads in Phase 25 for per-hit rolling

### DPS display formula
- DPS = average of all element ranges: sum of (element_min + element_max) / 2 across all elements
- Apply speed and crit multiplier as currently done
- Displayed number should be stable and comparable between items
- `is_item_better()` weapon comparison uses this same DPS formula

### Backward compatibility
- Existing `calculate_dps()` method signature unchanged -- it continues to work via computed base_damage property
- New `calculate_damage_range()` is additive, not replacing
- StatCalculator remains a static utility class (no state)

### Gap closure: Inventory rework (supersedes 24-03 defensive scoring)
- **Drop auto-replace mechanic** -- `is_item_better()` no longer decides what to keep
- **Multi-item inventory per slot** -- separate lists for weapon, armor, helmet, boots, ring
- **Limit: 10 items per slot** -- when full, new drops are discarded (no prompt, no auto-replace)
- **Crafting target: highest tier** -- auto-select the highest tier item in a slot for crafting
- **No manual discard** -- overflow-only cleanup, no delete button
- **No player selection** -- crafting always targets highest tier, not player's choice

### Claude's Discretion
- Internal data structure for per-element range breakdown (Dictionary, custom class, or Array)
- Whether to refactor existing calculate_dps() to call calculate_damage_range() internally or keep them separate
- Method naming and parameter design for the new API
- How Hero triggers recalculation (signal vs direct call after equip)
- Data model for multi-item inventory (Array per slot in Dictionary, or separate arrays)
- UI layout for showing item lists per slot

</decisions>

<specifics>
## Specific Ideas

- The per-element breakdown must handle the case where a hero has NO affixes for a given element -- that element's contribution is 0-0
- Physical base damage always comes from the weapon; elemental damage only comes from affixes (no elemental base weapons in current design)
- The locked element variance ratios from Phase 23 (Physical 1:1.5, Cold 1:2, Fire 1:2.5, Lightning 1:4) affect affix ranges, NOT the stat calculation itself -- StatCalculator just sums what it receives
- Items are fairly limited at the start -- players want to keep everything they find and craft on multiple items

</specifics>

<deferred>
## Deferred Ideas

- Per-defensive-stat comparison scoring (Evasion, HP, Armor, ES, Resistances) -- may not be needed if auto-replace is removed, but could be useful for sort/display in inventory list
- Manual item discard/management -- future UX enhancement if overflow-only feels limiting

</deferred>

---

*Phase: 24-stat-calculation-and-hero-range-caching*
*Context gathered: 2026-02-18*
