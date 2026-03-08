class_name StatCalculator extends RefCounted


## Calculates DPS using correct order of operations:
## base -> flat damage -> additive damage% -> speed -> crit multiplier
##
## Uses weighted-average crit formula: 1 + (crit_chance/100) * (crit_damage/100 - 1)
## This is the mathematically correct expected-value calculation.
static func calculate_dps(
	base_damage: float,
	base_speed: float,
	affixes: Array,
	base_crit_chance: float = 5.0,
	base_crit_damage: float = 150.0
) -> float:
	var damage := base_damage
	var speed := base_speed
	var crit_chance := base_crit_chance
	var crit_damage := base_crit_damage

	# Step 1: Flat damage additions
	for affix: Affix in affixes:
		if Tag.StatType.FLAT_DAMAGE in affix.stat_types:
			damage += affix.value

	# Step 2: Additive damage multipliers (sum all "increased" modifiers, apply once)
	var additive_damage_mult := 0.0
	for affix: Affix in affixes:
		if Tag.StatType.INCREASED_DAMAGE in affix.stat_types:
			additive_damage_mult += affix.value / 100.0
	damage *= (1.0 + additive_damage_mult)

	# Step 3: Attack speed (additive -- sum all speed modifiers, apply once)
	var additive_speed_mult := 0.0
	for affix: Affix in affixes:
		if Tag.StatType.INCREASED_SPEED in affix.stat_types:
			additive_speed_mult += affix.value / 100.0
	speed *= (1.0 + additive_speed_mult)

	# Step 4: Crit modifiers (flat additions to base crit values)
	for affix: Affix in affixes:
		if Tag.StatType.CRIT_CHANCE in affix.stat_types:
			crit_chance += affix.value
		if Tag.StatType.CRIT_DAMAGE in affix.stat_types:
			crit_damage += affix.value

	# Step 5: Final DPS = damage * speed * crit_multiplier
	var base_dps := damage * speed
	var crit_multiplier := _calculate_crit_multiplier(crit_chance, crit_damage)
	return base_dps * crit_multiplier


## Aggregates flat stat values from affixes for a given StatType.
## Used by defense items (armor, helmet, boots) to sum flat additions.
static func calculate_flat_stat(affixes: Array, stat_type: int) -> float:
	var total := 0.0
	for affix: Affix in affixes:
		if stat_type in affix.stat_types:
			total += affix.value
	return total


## Calculates percentage-based stat modifiers using additive stacking.
## All "increased X%" affixes for a stat type sum, then apply once to base value.
## Matches INCREASED_DAMAGE pattern from calculate_dps().
## Example: base=100, two +50% affixes -> 100 * (1.0 + 0.5 + 0.5) = 200
static func calculate_percentage_stat(base_value: float, affixes: Array, stat_type: int) -> float:
	var additive_mult := 0.0
	for affix: Affix in affixes:
		if stat_type in affix.stat_types:
			additive_mult += affix.value / 100.0
	return base_value * (1.0 + additive_mult)


## Calculates per-element damage ranges from weapon base damage and equipped affixes.
## Returns Dictionary of element -> {"min": float, "max": float} for each damage element.
## Percentage modifiers scale min and max independently (10-20 + 10% = 11-22, not 15-15).
##
## Element identification for flat damage affixes uses tags:
##   Tag.PHYSICAL -> physical, Tag.FIRE -> fire, Tag.COLD -> cold, Tag.LIGHTNING -> lightning
## Percentage modifier routing:
##   Tag.PHYSICAL in tags -> applies to physical only
##   Tag.ELEMENTAL in tags -> applies to fire, cold, lightning (all elemental)
static func calculate_damage_range(
	weapon_min: int,
	weapon_max: int,
	affixes: Array
) -> Dictionary:
	# Step 1: Accumulate per-element flat damage (min and max separately)
	var elements := {
		"physical": {"min": float(weapon_min), "max": float(weapon_max)},
		"fire": {"min": 0.0, "max": 0.0},
		"cold": {"min": 0.0, "max": 0.0},
		"lightning": {"min": 0.0, "max": 0.0},
	}

	for affix: Affix in affixes:
		if Tag.StatType.FLAT_DAMAGE not in affix.stat_types:
			continue
		var element := _get_damage_element(affix.tags)
		elements[element]["min"] += affix.add_min
		elements[element]["max"] += affix.add_max

	# Step 2: Accumulate percentage modifiers per group
	var physical_pct := 0.0
	var elemental_pct := 0.0

	for affix: Affix in affixes:
		if Tag.StatType.INCREASED_DAMAGE not in affix.stat_types:
			continue
		if Tag.PHYSICAL in affix.tags:
			physical_pct += affix.value / 100.0
		elif Tag.ELEMENTAL in affix.tags:
			elemental_pct += affix.value / 100.0

	# Step 3: Apply percentage modifiers -- scale min and max independently
	elements["physical"]["min"] *= (1.0 + physical_pct)
	elements["physical"]["max"] *= (1.0 + physical_pct)

	for el in ["fire", "cold", "lightning"]:
		elements[el]["min"] *= (1.0 + elemental_pct)
		elements[el]["max"] *= (1.0 + elemental_pct)

	return elements


## Determines which damage element a flat damage affix belongs to from its tags.
## Falls back to "physical" if no element tag found.
static func _get_damage_element(tags: Array) -> String:
	if Tag.FIRE in tags:
		return "fire"
	if Tag.COLD in tags:
		return "cold"
	if Tag.LIGHTNING in tags:
		return "lightning"
	return "physical"


## Calculates spell damage ranges from base spell damage and equipped affixes.
## Returns Dictionary with three elements: "spell", "spell_fire", "spell_lightning"
## Each element: {"min": float, "max": float}
## Routing by stat_type: FLAT_SPELL_DAMAGE -> "spell", FLAT_SPELL_FIRE_DAMAGE -> "spell_fire",
## FLAT_SPELL_LIGHTNING_DAMAGE -> "spell_lightning".
## INCREASED_SPELL_DAMAGE scales all three elements uniformly.
static func calculate_spell_damage_range(
	base_spell_min: int,
	base_spell_max: int,
	affixes: Array
) -> Dictionary:
	var elements := {
		"spell": {"min": float(base_spell_min), "max": float(base_spell_max)},
		"spell_fire": {"min": 0.0, "max": 0.0},
		"spell_lightning": {"min": 0.0, "max": 0.0},
	}

	# Step 1: Add flat spell damage from affixes, routed by stat_type
	for affix: Affix in affixes:
		if Tag.StatType.FLAT_SPELL_DAMAGE in affix.stat_types:
			elements["spell"]["min"] += affix.add_min
			elements["spell"]["max"] += affix.add_max
		if Tag.StatType.FLAT_SPELL_FIRE_DAMAGE in affix.stat_types:
			elements["spell_fire"]["min"] += affix.add_min
			elements["spell_fire"]["max"] += affix.add_max
		if Tag.StatType.FLAT_SPELL_LIGHTNING_DAMAGE in affix.stat_types:
			elements["spell_lightning"]["min"] += affix.add_min
			elements["spell_lightning"]["max"] += affix.add_max

	# Step 2: Apply %increased spell damage (additive stacking, scales ALL elements)
	var spell_pct := 0.0
	for affix: Affix in affixes:
		if Tag.StatType.INCREASED_SPELL_DAMAGE not in affix.stat_types:
			continue
		spell_pct += affix.value / 100.0

	for el in elements:
		elements[el]["min"] *= (1.0 + spell_pct)
		elements[el]["max"] *= (1.0 + spell_pct)

	return elements


## Calculates spell DPS using correct order of operations:
## base -> flat spell damage -> additive spell damage% -> cast speed -> crit multiplier
##
## If base_cast_speed == 0 and no INCREASED_CAST_SPEED affixes, returns 0.0 (no spell channel).
static func calculate_spell_dps(
	base_spell_damage: float,
	base_cast_speed: float,
	affixes: Array,
	base_crit_chance: float = 5.0,
	base_crit_damage: float = 150.0
) -> float:
	var damage := base_spell_damage
	var cast_speed := base_cast_speed
	var crit_chance := base_crit_chance
	var crit_damage := base_crit_damage

	# Step 1: Flat spell damage additions
	for affix: Affix in affixes:
		if Tag.StatType.FLAT_SPELL_DAMAGE in affix.stat_types:
			damage += affix.value

	# Step 2: Additive spell damage multipliers
	var additive_spell_mult := 0.0
	for affix: Affix in affixes:
		if Tag.StatType.INCREASED_SPELL_DAMAGE in affix.stat_types:
			additive_spell_mult += affix.value / 100.0
	damage *= (1.0 + additive_spell_mult)

	# Step 3: Cast speed (additive -- sum all cast speed modifiers, apply once)
	var additive_cast_speed_mult := 0.0
	for affix: Affix in affixes:
		if Tag.StatType.INCREASED_CAST_SPEED in affix.stat_types:
			additive_cast_speed_mult += affix.value / 100.0
	cast_speed *= (1.0 + additive_cast_speed_mult)

	# If no cast speed, no spell channel
	if cast_speed == 0.0:
		return 0.0

	# Step 4: Crit modifiers
	for affix: Affix in affixes:
		if Tag.StatType.CRIT_CHANCE in affix.stat_types:
			crit_chance += affix.value
		if Tag.StatType.CRIT_DAMAGE in affix.stat_types:
			crit_damage += affix.value

	# Step 5: Final Spell DPS = damage * cast_speed * crit_multiplier
	var base_dps := damage * cast_speed
	var crit_multiplier := _calculate_crit_multiplier(crit_chance, crit_damage)
	return base_dps * crit_multiplier


## Correct crit multiplier using weighted average formula:
## E[multiplier] = (1 - c) * 1.0 + c * d = 1 + c * (d - 1)
## Where c = crit_chance/100, d = crit_damage/100
##
## Test cases:
## - 0% crit, 150% damage -> 1.0 (no crit effect)
## - 100% crit, 150% damage -> 1.5 (always crits)
## - 5% crit, 150% damage -> 1.025 (2.5% DPS increase)
## - 50% crit, 200% damage -> 1.5 (50% DPS increase)
static func _calculate_crit_multiplier(crit_chance: float, crit_damage: float) -> float:
	var c := crit_chance / 100.0
	var d := crit_damage / 100.0
	return 1.0 + c * (d - 1.0)
