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
