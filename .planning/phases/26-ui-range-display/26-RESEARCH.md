# Phase 26: UI Range Display -- Research

**Completed:** 2026-02-18
**Status:** Ready for planning

## Current UI Architecture

### forge_view.gd get_item_stats_text()
- Weapon section shows: DPS, Base Damage, Base Speed, Crit Chance, Crit Damage
- Then implicit, prefixes, suffixes with "Name: value" format
- Line: `stats_text += "Base Damage: %d\n" % weapon.base_damage`
- Need to change to: `stats_text += "Damage: %d to %d\n" % [weapon.base_damage_min, weapon.base_damage_max]`

### forge_view.gd get_stat_comparison_text()
- Weapon comparison shows: DPS, Base Damage, Crit Chance, Crit Damage
- Uses format_stat_delta_int("Base Damage", eq_base_dmg, crafted.base_damage)
- Need to update to show range comparison instead of single value

### Affix display in forge_view.gd
- Currently: `prefix.affix_name + ": " + str(prefix.value)`
- For flat damage affixes (FLAT_DAMAGE in stat_types): change to "Adds X to Y [Element] Damage"
- For all other affixes: keep existing "Name: value" format

### gameplay_view.gd combat display
- Pack HP bar shows `pack.hp` / `pack.max_hp`
- pack_hp_label: `"%.0f/%.0f" % [pack.hp, pack.max_hp]`
- No pack name or element displayed currently
- Need to add pack info (name and element) somewhere near the pack HP area

### DPS display (already correct)
- hero.total_dps already uses range-based formula from Phase 24
- ForgeView reads hero.get_total_dps() -- no change needed
- is_item_better() already uses DPS for weapons/rings -- no change needed

## Key findings

### Affix element identification
The same logic as StatCalculator._get_damage_element() is needed in forge_view to determine which element name to display:
- Tag.PHYSICAL in tags -> "Physical"
- Tag.FIRE in tags -> "Fire"
- Tag.COLD in tags -> "Cold"
- Tag.LIGHTNING in tags -> "Lightning"

### Longest realistic string at font size 11
- "Adds 8 to 128 Lightning Damage" = 30 chars (at tier 1, Lightning prefix with max scaling)
- Should fit in the stats panel at font size 11 within 1280x720 viewport

### Pack info display
- pack_hp_label currently shows "HP/MaxHP" format
- Can add pack name and element to pack_hp_label text or add a separate label
- MonsterPack has pack_name (String) and element (String) fields

## Risk Assessment

**Low risk:** Pure UI text changes. No data model, combat, or save format changes.

---
*Research completed: 2026-02-18*
