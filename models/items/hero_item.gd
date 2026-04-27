class_name HeroItem extends CraftableItem

var slot: Tag_List.ItemSlot

# Base stats (set from base definition)
var base_damage_min: int = 0
var base_damage_max: int = 0
var base_speed: int = 1
var base_attack_speed: float = 1.0
var base_armor: int = 0
var base_evasion: int = 0
var base_energy_shield: int = 0
var base_health: int = 0
var base_movement_speed: int = 0
var base_mana: int = 0

# Computed stats (recalculated by update_value)
var dps: float = 0.0
var crit_chance: float = BalanceConfig.BASE_CRIT_CHANCE
var crit_damage: float = BalanceConfig.BASE_CRIT_DAMAGE
var computed_armor: int = 0
var computed_evasion: int = 0
var computed_energy_shield: int = 0
var computed_health: int = 0
var computed_movement_speed: int = 0
var computed_mana: int = 0
var total_defense: int = 0


func is_weapon_slot() -> bool:
	return slot == Tag_List.ItemSlot.WEAPON or slot == Tag_List.ItemSlot.RING


func is_defense_slot() -> bool:
	return slot in [Tag_List.ItemSlot.ARMOR, Tag_List.ItemSlot.HELMET, Tag_List.ItemSlot.BOOTS]


func update_value() -> void:
	if is_weapon_slot():
		_update_weapon_value()
	elif is_defense_slot():
		_update_defense_value()


func _update_weapon_value() -> void:
	var all_affixes: Array = prefixes.duplicate()
	all_affixes.append_array(suffixes)
	if implicit != null:
		all_affixes.append(implicit)

	var base_dmg: float
	if base_damage_min > 0 and base_damage_max > 0:
		base_dmg = float(base_damage_min + base_damage_max) / 2.0
	else:
		base_dmg = 0.0

	dps = StatCalculator.calculate_dps(
		base_dmg, float(base_speed), all_affixes, crit_chance, crit_damage
	)


func _update_defense_value() -> void:
	var all_affixes: Array = prefixes.duplicate()
	all_affixes.append_array(suffixes)
	if implicit != null:
		all_affixes.append(implicit)

	var flat_armor := base_armor + int(
		StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_ARMOR)
	)
	var flat_evasion := base_evasion + int(
		StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_EVASION)
	)
	var flat_energy_shield := base_energy_shield + int(
		StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_ENERGY_SHIELD)
	)
	var flat_health := base_health + int(
		StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_HEALTH)
	)

	computed_armor = int(
		StatCalculator.calculate_percentage_stat(float(flat_armor), all_affixes, Tag.StatType.PERCENT_ARMOR)
	)
	computed_evasion = int(
		StatCalculator.calculate_percentage_stat(float(flat_evasion), all_affixes, Tag.StatType.PERCENT_EVASION)
	)
	computed_energy_shield = int(
		StatCalculator.calculate_percentage_stat(float(flat_energy_shield), all_affixes, Tag.StatType.PERCENT_ENERGY_SHIELD)
	)
	computed_health = int(
		StatCalculator.calculate_percentage_stat(float(flat_health), all_affixes, Tag.StatType.PERCENT_HEALTH)
	)

	if slot == Tag_List.ItemSlot.BOOTS:
		computed_movement_speed = (
			base_movement_speed
			+ int(StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.MOVEMENT_SPEED))
		)

	if slot == Tag_List.ItemSlot.HELMET:
		computed_mana = (
			base_mana
			+ int(StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_MANA))
		)

	total_defense = computed_armor


func get_display_text() -> String:
	var output := "----\n"
	output += "name: %s\n" % item_name

	if is_weapon_slot():
		output += "dps: %.1f\n" % dps
		if base_damage_min > 0:
			output += "damage: %d-%d\n" % [base_damage_min, base_damage_max]

	if is_defense_slot():
		if computed_armor > 0:
			output += "armor: %d\n" % computed_armor
		if computed_evasion > 0:
			output += "evasion: %d\n" % computed_evasion
		if computed_energy_shield > 0:
			output += "energy shield: %d\n" % computed_energy_shield
		if computed_health > 0:
			output += "health: %d\n" % computed_health

	if implicit != null:
		output += "implicit:\n\t%s ~ value: %d ~ tier %d\n" % [
			implicit.affix_name, implicit.value, implicit.tier
		]

	output += "prefixes:\n"
	for prefix in prefixes:
		output += "\t%s ~ value: %d ~ tier %d\n" % [prefix.affix_name, prefix.value, prefix.tier]

	output += "suffixes:\n"
	for suffix in suffixes:
		output += "\t%s ~ value: %d ~ tier %d\n" % [suffix.affix_name, suffix.value, suffix.tier]

	output += "----\n"
	return output
