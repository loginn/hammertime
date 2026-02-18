# Phase 24: Stat Calculation and Hero Range Caching — Research

**Completed:** 2026-02-18
**Status:** Ready for planning

## Current Architecture

### StatCalculator (models/stats/stat_calculator.gd)
- Static utility class (`extends RefCounted`)
- `calculate_dps(base_damage, base_speed, affixes, crit_chance, crit_damage)` -- current DPS formula
- Order: base -> flat damage (affix.value) -> additive damage% -> speed -> crit multiplier
- `calculate_flat_stat(affixes, stat_type)` -- sums affix values for a given StatType
- `calculate_percentage_stat(base_value, affixes, stat_type)` -- applies additive percentage modifiers
- `_calculate_crit_multiplier(crit_chance, crit_damage)` -- weighted average formula

### Hero (models/hero.gd)
- `equipped_items: Dictionary` with slots: weapon, helmet, armor, boots, ring
- `total_dps: float` -- set in `calculate_dps()` by summing `weapon.dps + ring.dps`
- `update_stats()` calls `calculate_dps()`, `calculate_defense()`, `calculate_crit_stats()`
- Called on: equip, unequip, and after load (GameState._ready -> load_game -> hero.update_stats)
- Defensive stats: total_armor, total_evasion, total_energy_shield, resistances
- Crit stats: total_crit_chance, total_crit_damage

### Tag System (autoloads/tag.gd)
- Element tags: Tag.PHYSICAL, Tag.FIRE, Tag.COLD, Tag.LIGHTNING (string constants)
- StatType enum: FLAT_DAMAGE, INCREASED_DAMAGE, INCREASED_SPEED, etc.
- **Key finding:** All flat damage affixes share `Tag.StatType.FLAT_DAMAGE` -- element identification is via tags array (Tag.PHYSICAL, Tag.FIRE, etc.), not via separate stat types
- Percentage damage affixes share `Tag.StatType.INCREASED_DAMAGE` -- element identification also via tags

### Affix Fields (from Phase 23)
- `add_min: int` -- rolled minimum damage per hit
- `add_max: int` -- rolled maximum damage per hit
- `tags: Array[String]` -- contains element tag (e.g., Tag.PHYSICAL, Tag.FIRE)
- `stat_types: Array[int]` -- contains FLAT_DAMAGE for flat, INCREASED_DAMAGE for percentage

### Weapon Fields (from Phase 23)
- `base_damage_min: int`, `base_damage_max: int` -- range fields
- `base_damage: int` (computed getter, returns average)
- `base_damage_type: String` -- element type (e.g., Tag.PHYSICAL)

### Item Affixes Definitions (autoloads/item_affixes.gd)
- Physical Damage: tags [Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON], stat_types [FLAT_DAMAGE]
- Lightning Damage: tags [Tag.ELEMENTAL, Tag.LIGHTNING, Tag.WEAPON], stat_types [FLAT_DAMAGE]
- Fire Damage: tags [Tag.ELEMENTAL, Tag.FIRE, Tag.WEAPON], stat_types [FLAT_DAMAGE]
- Cold Damage: tags [Tag.ELEMENTAL, Tag.COLD, Tag.WEAPON], stat_types [FLAT_DAMAGE]
- %Physical Damage: tags [Tag.PHYSICAL, Tag.PERCENTAGE, Tag.WEAPON], stat_types [INCREASED_DAMAGE]
- %Elemental Damage: tags [Tag.ELEMENTAL, Tag.WEAPON], stat_types [INCREASED_DAMAGE]
- %Cold/Fire/Lightning Damage: tags [Tag.ELEMENTAL, Tag.WEAPON], stat_types [INCREASED_DAMAGE]

### Element Identification Strategy
To determine which element a flat damage affix belongs to, check tags:
- `Tag.PHYSICAL in tags` -> physical
- `Tag.LIGHTNING in tags` -> lightning
- `Tag.FIRE in tags` -> fire
- `Tag.COLD in tags` -> cold
Falls back to physical if no element tag found.

For percentage damage modifiers:
- `Tag.PHYSICAL in tags` -> applies to physical only
- `Tag.ELEMENTAL in tags` -> applies to all elemental (fire, cold, lightning)
- Element-specific `%Cold/%Fire/%Lightning` have Tag.ELEMENTAL but NOT the specific element tag -- they're generic "elemental" modifiers

**Critical finding:** The current `%Cold Damage`, `%Fire Damage`, `%Lightning Damage` prefixes all share identical tags `[Tag.ELEMENTAL, Tag.WEAPON]` -- they cannot be distinguished from `%Elemental Damage` by tags alone. This means all percentage elemental modifiers apply to ALL elemental damage equally (additive stacking), which is correct for an ARPG. Physical percentage (`%Physical Damage`) has `Tag.PHYSICAL` so it applies only to physical.

### DPS Display Flow
1. Weapon.update_value() calls StatCalculator.calculate_dps(base_damage, base_speed, all_affixes, crit_chance, crit_damage)
2. Result stored as weapon.dps
3. Hero.calculate_dps() sums weapon.dps + ring.dps into hero.total_dps
4. ForgeView reads hero.total_dps for display

### is_item_better (scenes/forge_view.gd)
- Currently: `return new_item.tier > existing_item.tier` (tier comparison only)
- Success criteria says: use DPS for weapon comparison

## Key Design Decisions for Planning

### 1. Per-element range accumulation
New `calculate_damage_range()` needs to:
- Accept weapon base_damage_min/max and all affixes
- Accumulate per-element: physical_min/max, fire_min/max, cold_min/max, lightning_min/max
- Physical base comes from weapon; elemental from affixes only
- Apply percentage modifiers per-element group (physical % to physical, elemental % to fire/cold/lightning)
- Return a dictionary of element -> {min, max}

### 2. DPS from ranges
- For each element: element_avg = (element_min + element_max) / 2.0
- Sum all element averages = total_damage
- DPS = total_damage * speed * crit_multiplier
- This should produce the same DPS as current formula when there are no flat damage affixes (backward compat)

### 3. Hero caching
- Hero needs per-element min/max (4 elements x 2 values = 8 new fields)
- Populated in update_stats() from weapon + affixes via new StatCalculator method
- NOT serialized (recalculated from equipment on load)
- CombatEngine reads these in Phase 25

### 4. Backward compatibility concern
- Current Weapon.update_value() stores a single `dps` float
- Ring.update_value() also stores a single `dps` float
- Hero.calculate_dps() sums them
- The new calculate_damage_range() should be called FROM Hero.update_stats(), operating on raw weapon/affix data, not on pre-calculated DPS
- Weapon.dps and Ring.dps should continue to be populated (for UI display in Phase 26)

## Risk Assessment

**Low risk:** This is pure math/data -- no UI changes, no save format changes, no combat behavior changes. The new method is additive. Existing calculate_dps() continues to work.

**Edge case:** Hero with no weapon equipped should produce all-zero ranges. Hero with weapon but no affixes should produce physical range only.

---
*Research completed: 2026-02-18*
