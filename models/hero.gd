class_name Hero extends Resource

var health: float = BalanceConfig.BASE_HEALTH
var max_health: float = BalanceConfig.BASE_HEALTH
var hero_name: String = "Hero"

var equipped_items: Dictionary = {}
var total_dps: float = 0.0
var defensive_score: float = 0.0
var total_armor: int = 0
var total_evasion: int = 0
var total_energy_shield: int = 0
var total_fire_resistance: int = 0
var total_cold_resistance: int = 0
var total_lightning_resistance: int = 0
var current_energy_shield: float = 0.0
var total_crit_chance: float = BalanceConfig.BASE_CRIT_CHANCE
var total_crit_damage: float = BalanceConfig.BASE_CRIT_DAMAGE

var damage_ranges: Dictionary = {}

var is_alive: bool = true
var is_on_expedition: bool = false


func _init() -> void:
	damage_ranges = {
		Tag.Element.PHYSICAL: {"min": 0.0, "max": 0.0},
		Tag.Element.FIRE: {"min": 0.0, "max": 0.0},
		Tag.Element.COLD: {"min": 0.0, "max": 0.0},
		Tag.Element.LIGHTNING: {"min": 0.0, "max": 0.0},
	}
	for slot_val in Tag.ALL_SLOTS:
		equipped_items[slot_val] = null
	update_stats()


func equip_item(item: HeroItem) -> void:
	equipped_items[item.slot] = item
	update_stats()


func unequip_item(slot: Tag_List.ItemSlot) -> void:
	equipped_items[slot] = null
	update_stats()


func get_equipped(slot: Tag_List.ItemSlot) -> HeroItem:
	return equipped_items.get(slot)


func update_stats() -> void:
	calculate_crit_stats()
	calculate_damage_ranges()
	calculate_dps()
	calculate_defense()
	current_energy_shield = float(total_energy_shield)
	health = max_health


func calculate_damage_ranges() -> void:
	for element in damage_ranges:
		damage_ranges[element]["min"] = 0.0
		damage_ranges[element]["max"] = 0.0

	for slot_val in [Tag.ItemSlot.WEAPON, Tag.ItemSlot.RING]:
		var item: HeroItem = equipped_items.get(slot_val)
		if item == null:
			continue
		var all_affixes: Array = item.prefixes.duplicate()
		all_affixes.append_array(item.suffixes)
		if item.implicit:
			all_affixes.append(item.implicit)
		var ranges := StatCalculator.calculate_damage_range(
			item.base_damage_min, item.base_damage_max, all_affixes
		)
		for element in ranges:
			damage_ranges[element]["min"] += ranges[element]["min"]
			damage_ranges[element]["max"] += ranges[element]["max"]


func calculate_dps() -> float:
	var total_avg_damage := 0.0
	for element in damage_ranges:
		var el_min: float = damage_ranges[element]["min"]
		var el_max: float = damage_ranges[element]["max"]
		total_avg_damage += (el_min + el_max) / 2.0

	var speed := 1.0
	var weapon: HeroItem = equipped_items.get(Tag.ItemSlot.WEAPON)
	if weapon != null:
		speed = float(weapon.base_speed)
		var all_affixes: Array = weapon.prefixes.duplicate()
		all_affixes.append_array(weapon.suffixes)
		if weapon.implicit:
			all_affixes.append(weapon.implicit)
		var additive_speed_mult := 0.0
		for affix: Affix in all_affixes:
			if Tag.StatType.INCREASED_SPEED in affix.stat_types:
				additive_speed_mult += affix.value / 100.0
		speed *= (1.0 + additive_speed_mult)

	var crit_multiplier := StatCalculator._calculate_crit_multiplier(
		total_crit_chance, total_crit_damage
	)

	total_dps = total_avg_damage * speed * crit_multiplier
	return total_dps


func calculate_defense() -> int:
	total_armor = 0
	total_evasion = 0
	total_energy_shield = 0
	total_fire_resistance = 0
	total_cold_resistance = 0
	total_lightning_resistance = 0

	var total_health: int = int(BalanceConfig.BASE_HEALTH)

	for slot_val in [Tag.ItemSlot.HELMET, Tag.ItemSlot.ARMOR, Tag.ItemSlot.BOOTS]:
		var item: HeroItem = equipped_items.get(slot_val)
		if item == null:
			continue
		total_armor += item.computed_armor
		total_evasion += item.computed_evasion
		total_energy_shield += item.computed_energy_shield
		total_health += item.computed_health

	for slot_val in Tag.ALL_SLOTS:
		var item: HeroItem = equipped_items.get(slot_val)
		if item == null:
			continue
		for suffix in item.suffixes:
			if Tag.StatType.FIRE_RESISTANCE in suffix.stat_types:
				total_fire_resistance += suffix.value
			if Tag.StatType.COLD_RESISTANCE in suffix.stat_types:
				total_cold_resistance += suffix.value
			if Tag.StatType.LIGHTNING_RESISTANCE in suffix.stat_types:
				total_lightning_resistance += suffix.value
			if Tag.StatType.ALL_RESISTANCE in suffix.stat_types:
				total_fire_resistance += suffix.value
				total_cold_resistance += suffix.value
				total_lightning_resistance += suffix.value

	for slot_val in [Tag.ItemSlot.WEAPON, Tag.ItemSlot.RING]:
		var item: HeroItem = equipped_items.get(slot_val)
		if item == null:
			continue
		for suffix in item.suffixes:
			if Tag.StatType.FLAT_HEALTH in suffix.stat_types:
				total_health += suffix.value
			if Tag.StatType.FLAT_ARMOR in suffix.stat_types:
				total_armor += suffix.value

	var all_percent_health_affixes: Array = []
	for slot_val in Tag.ALL_SLOTS:
		var item: HeroItem = equipped_items.get(slot_val)
		if item == null:
			continue
		all_percent_health_affixes.append_array(item.prefixes)

	total_health = int(StatCalculator.calculate_percentage_stat(
		float(total_health), all_percent_health_affixes, Tag.StatType.PERCENT_HEALTH
	))

	max_health = float(total_health)

	var effective_hp := (max_health + float(total_energy_shield)) * (
		1.0 + float(total_armor) / BalanceConfig.ARMOR_SCALING
	)
	var avg_res := (
		minf(float(total_fire_resistance), float(BalanceConfig.RESISTANCE_CAP)) +
		minf(float(total_cold_resistance), float(BalanceConfig.RESISTANCE_CAP)) +
		minf(float(total_lightning_resistance), float(BalanceConfig.RESISTANCE_CAP))
	) / 3.0
	var res_factor := 1.0 + avg_res / 100.0
	var evasion_factor := 1.0 + float(total_evasion) / BalanceConfig.EVASION_SCALING
	defensive_score = effective_hp * res_factor * evasion_factor
	return int(defensive_score)


func calculate_crit_stats() -> void:
	total_crit_chance = BalanceConfig.BASE_CRIT_CHANCE
	total_crit_damage = BalanceConfig.BASE_CRIT_DAMAGE

	for slot_val in [Tag.ItemSlot.WEAPON, Tag.ItemSlot.RING]:
		var item: HeroItem = equipped_items.get(slot_val)
		if item == null:
			continue
		total_crit_chance += item.crit_chance - BalanceConfig.BASE_CRIT_CHANCE
		total_crit_damage += item.crit_damage - BalanceConfig.BASE_CRIT_DAMAGE


func get_hero_power() -> float:
	return total_dps + defensive_score * BalanceConfig.DEFENSE_WEIGHT


func take_damage(damage: float) -> void:
	health -= damage
	health = max(0, health)
	if health <= 0:
		die()


func heal(amount: float) -> void:
	health += amount
	health = min(health, max_health)


func die() -> void:
	is_alive = false


func revive() -> void:
	health = max_health
	current_energy_shield = float(total_energy_shield)
	is_alive = true


func apply_damage(life_damage: float, es_damage: float) -> void:
	current_energy_shield = maxf(0.0, current_energy_shield - es_damage)
	health -= life_damage
	health = maxf(0.0, health)
	if health <= 0:
		die()


func recharge_energy_shield() -> void:
	var recharge_amount := float(total_energy_shield) * BalanceConfig.ES_RECHARGE_RATE
	current_energy_shield = minf(
		current_energy_shield + recharge_amount, float(total_energy_shield)
	)


func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return health / max_health
