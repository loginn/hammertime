class_name StatCalculator extends RefCounted


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

	for affix: Affix in affixes:
		if Tag.StatType.FLAT_DAMAGE in affix.stat_types:
			damage += affix.value

	var additive_damage_mult := 0.0
	for affix: Affix in affixes:
		if Tag.StatType.INCREASED_DAMAGE in affix.stat_types:
			additive_damage_mult += affix.value / 100.0
	damage *= (1.0 + additive_damage_mult)

	var additive_speed_mult := 0.0
	for affix: Affix in affixes:
		if Tag.StatType.INCREASED_SPEED in affix.stat_types:
			additive_speed_mult += affix.value / 100.0
	speed *= (1.0 + additive_speed_mult)

	for affix: Affix in affixes:
		if Tag.StatType.CRIT_CHANCE in affix.stat_types:
			crit_chance += affix.value
		if Tag.StatType.CRIT_DAMAGE in affix.stat_types:
			crit_damage += affix.value

	var base_dps := damage * speed
	var crit_multiplier := _calculate_crit_multiplier(crit_chance, crit_damage)
	return base_dps * crit_multiplier


static func calculate_flat_stat(affixes: Array, stat_type: int) -> float:
	var total := 0.0
	for affix: Affix in affixes:
		if stat_type in affix.stat_types:
			total += affix.value
	return total


static func calculate_percentage_stat(base_value: float, affixes: Array, stat_type: int) -> float:
	var additive_mult := 0.0
	for affix: Affix in affixes:
		if stat_type in affix.stat_types:
			additive_mult += affix.value / 100.0
	return base_value * (1.0 + additive_mult)


static func calculate_damage_range(
	weapon_min: int,
	weapon_max: int,
	affixes: Array
) -> Dictionary:
	var elements := {
		Tag.Element.PHYSICAL: {"min": float(weapon_min), "max": float(weapon_max)},
		Tag.Element.FIRE: {"min": 0.0, "max": 0.0},
		Tag.Element.COLD: {"min": 0.0, "max": 0.0},
		Tag.Element.LIGHTNING: {"min": 0.0, "max": 0.0},
	}

	for affix: Affix in affixes:
		if Tag.StatType.FLAT_DAMAGE not in affix.stat_types:
			continue
		var element := _get_damage_element(affix.tags)
		elements[element]["min"] += affix.add_min
		elements[element]["max"] += affix.add_max

	var physical_pct := 0.0
	var elemental_pct := 0.0

	for affix: Affix in affixes:
		if Tag.StatType.INCREASED_DAMAGE not in affix.stat_types:
			continue
		if Tag.PHYSICAL in affix.tags:
			physical_pct += affix.value / 100.0
		elif Tag.ELEMENTAL in affix.tags:
			elemental_pct += affix.value / 100.0

	elements[Tag.Element.PHYSICAL]["min"] *= (1.0 + physical_pct)
	elements[Tag.Element.PHYSICAL]["max"] *= (1.0 + physical_pct)

	for el in [Tag.Element.FIRE, Tag.Element.COLD, Tag.Element.LIGHTNING]:
		elements[el]["min"] *= (1.0 + elemental_pct)
		elements[el]["max"] *= (1.0 + elemental_pct)

	return elements


static func _get_damage_element(tags: Array) -> Tag_List.Element:
	if Tag.FIRE in tags:
		return Tag.Element.FIRE
	if Tag.COLD in tags:
		return Tag.Element.COLD
	if Tag.LIGHTNING in tags:
		return Tag.Element.LIGHTNING
	return Tag.Element.PHYSICAL


static func _calculate_crit_multiplier(crit_chance: float, crit_damage: float) -> float:
	var c := crit_chance / 100.0
	var d := crit_damage / 100.0
	return 1.0 + c * (d - 1.0)
