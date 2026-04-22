class_name DefenseCalculator extends RefCounted


static func calculate_armor_reduction(armor: int, raw_physical_damage: float) -> float:
	if armor <= 0 or raw_physical_damage <= 0.0:
		return 0.0
	return float(armor) / (float(armor) + BalanceConfig.ARMOR_DIVISOR * raw_physical_damage)


static func calculate_dodge_chance(evasion: int) -> float:
	if evasion <= 0:
		return 0.0
	var raw_chance := float(evasion) / (float(evasion) + BalanceConfig.EVASION_DIVISOR)
	return minf(raw_chance, BalanceConfig.DODGE_CAP)


static func calculate_resistance_reduction(resistance: int) -> float:
	var effective := mini(resistance, BalanceConfig.RESISTANCE_CAP)
	if effective <= 0:
		return 0.0
	return float(effective) / 100.0


static func apply_es_split(
	mitigated_damage: float, current_es: float
) -> Dictionary:
	if current_es <= 0.0:
		return { "es_damage": 0.0, "life_damage": mitigated_damage }

	var es_portion := mitigated_damage * BalanceConfig.ES_SPLIT_RATIO
	var life_portion := mitigated_damage * (1.0 - BalanceConfig.ES_SPLIT_RATIO)

	if es_portion > current_es:
		var overflow := es_portion - current_es
		es_portion = current_es
		life_portion += overflow

	return { "es_damage": es_portion, "life_damage": life_portion }


static func calculate_damage_taken(
	raw_damage: float,
	damage_element: Tag_List.Element,
	is_spell: bool,
	hero_armor: int,
	hero_evasion: int,
	hero_energy_shield: int,
	hero_fire_res: int,
	hero_cold_res: int,
	hero_lightning_res: int,
	current_es: float
) -> Dictionary:
	var result := {
		"dodged": false,
		"life_damage": 0.0,
		"es_damage": 0.0,
	}

	if not is_spell and hero_evasion > 0:
		var dodge_chance := calculate_dodge_chance(hero_evasion)
		if randf() < dodge_chance:
			result["dodged"] = true
			return result

	var damage := raw_damage

	if damage_element in [Tag_List.Element.FIRE, Tag_List.Element.COLD, Tag_List.Element.LIGHTNING]:
		var resistance := 0
		match damage_element:
			Tag_List.Element.FIRE:
				resistance = hero_fire_res
			Tag_List.Element.COLD:
				resistance = hero_cold_res
			Tag_List.Element.LIGHTNING:
				resistance = hero_lightning_res
		var reduction := calculate_resistance_reduction(resistance)
		damage *= (1.0 - reduction)

	if damage_element == Tag_List.Element.PHYSICAL and hero_armor > 0:
		var armor_reduction := calculate_armor_reduction(hero_armor, damage)
		damage *= (1.0 - armor_reduction)

	damage = maxf(0.0, damage)

	if current_es > 0.0 and hero_energy_shield > 0:
		var split := apply_es_split(damage, current_es)
		result["life_damage"] = split["life_damage"]
		result["es_damage"] = split["es_damage"]
	else:
		result["life_damage"] = damage

	return result
