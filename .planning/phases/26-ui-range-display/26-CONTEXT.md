# Phase 26: UI Range Display - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

UI updates to show damage ranges on weapon tooltips and affix descriptions, plus pack info display during combat. No data model or combat logic changes. DPS formula already correct from Phase 24.

</domain>

<decisions>
## Implementation Decisions

### Weapon tooltip format
- Show "Damage: X to Y" where X = base_damage_min, Y = base_damage_max
- Replaces the single "Base Damage: N" line in get_item_stats_text()

### Affix description format
- Flat damage affixes show "Adds X to Y [Element] Damage" using add_min/add_max
- Non-flat-damage affixes continue showing "Name: value" format unchanged
- Element name derived from affix tags (same logic as _get_damage_element)

### DPS display
- Already uses range-based formula from Phase 24 (hero.total_dps computed from range averages)
- Item-level DPS (weapon.dps, ring.dps) still uses StatCalculator.calculate_dps() with base_damage average
- is_item_better() already updated in Phase 24 to use DPS for weapons/rings

### Pack info display
- Show pack name and element type in the gameplay view combat UI
- Display near the pack HP bar or in the combat state label area

### Claude's Discretion
- Exact label text formatting and positioning
- Whether to add a dedicated pack info label or reuse existing labels
- Prefix display format for flat damage affixes vs existing "Name: value" pattern

</decisions>

<specifics>
## Specific Ideas

- The pack_hp_label could show pack name and element alongside HP
- Or a separate label above/below the pack HP bar
- Element names should be capitalized for display: "Physical", "Fire", "Cold", "Lightning"

</specifics>

<deferred>
## Deferred Ideas

None.

</deferred>

---

*Phase: 26-ui-range-display*
*Context gathered: 2026-02-18*
