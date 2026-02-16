class_name Hero extends Resource

# Hero stats
var health: float = 100.0
var max_health: float = 100.0
var hero_name: String = "Adventurer"

# Hero equipment and stats
var equipped_items: Dictionary = {}
var total_dps: float = 0.0
var total_defense: int = 0
var total_armor: int = 0
var total_evasion: int = 0
var total_energy_shield: int = 0
var total_fire_resistance: int = 0
var total_cold_resistance: int = 0
var total_lightning_resistance: int = 0
var total_crit_chance: float = 5.0
var total_crit_damage: float = 150.0

# Hero state
var is_alive: bool = true
var is_clearing: bool = false


func _init() -> void:
	# Initialize hero with default stats
	update_stats()


func take_damage(damage: float) -> void:
	"""Hero takes damage and updates health"""
	health -= damage
	health = max(0, health)  # Don't go below 0

	print("Hero took ", damage, " damage! Health: ", health, "/", max_health)

	if health <= 0:
		die()


func heal(amount: float) -> void:
	"""Heal the hero by the specified amount"""
	health += amount
	health = min(health, max_health)  # Don't exceed max health
	print("Hero healed for ", amount, "! Health: ", health, "/", max_health)


func die() -> void:
	"""Hero dies and stops all activities"""
	is_alive = false
	is_clearing = false
	print("Hero died!")


func revive() -> void:
	"""Revive the hero with full health"""
	health = max_health
	is_alive = true
	print("Hero revived with full health!")


func equip_item(item: Item, slot: String) -> void:
	"""Equip an item to the specified slot"""
	equipped_items[slot] = item
	update_stats()
	print("Equipped ", item.item_name, " to ", slot)


func unequip_item(slot: String) -> void:
	"""Unequip an item from the specified slot"""
	if slot in equipped_items:
		var item = equipped_items[slot]
		equipped_items.erase(slot)
		update_stats()
		print("Unequipped ", item.item_name, " from ", slot)


func update_stats() -> void:
	"""Recalculate all hero stats based on equipped items"""
	calculate_dps()
	calculate_defense()
	calculate_crit_stats()


func calculate_dps() -> float:
	"""Calculate total DPS from equipped weapon and rings"""
	total_dps = 0.0

	# Add DPS from weapon
	if "weapon" in equipped_items and equipped_items["weapon"] != null:
		var weapon = equipped_items["weapon"]
		if weapon is Weapon:
			total_dps += weapon.dps

	# Add DPS from rings (damage slots)
	if "ring" in equipped_items and equipped_items["ring"] != null:
		var ring = equipped_items["ring"]
		if ring is Ring:
			total_dps += ring.dps

	return total_dps


func calculate_defense() -> int:
	"""Calculate total defense from equipped armor"""
	total_armor = 0
	total_evasion = 0
	total_energy_shield = 0
	total_fire_resistance = 0
	total_cold_resistance = 0
	total_lightning_resistance = 0

	# Add defense from armor pieces (base stats only from armor slots)
	for slot in ["helmet", "armor", "boots"]:
		if slot in equipped_items and equipped_items[slot] != null:
			var armor_item = equipped_items[slot]

			# Check for base_armor property
			if "base_armor" in armor_item:
				total_armor += armor_item.base_armor

			# Check for base_evasion property
			if "base_evasion" in armor_item:
				total_evasion += armor_item.base_evasion

			# Check for base_energy_shield property
			if "base_energy_shield" in armor_item:
				total_energy_shield += armor_item.base_energy_shield

	# Add resistance from suffixes on ALL equipment slots
	for slot in ["helmet", "armor", "boots", "weapon", "ring"]:
		if slot in equipped_items and equipped_items[slot] != null:
			var item = equipped_items[slot]

			# Process suffixes for resistance stats
			if "suffixes" in item:
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

	# Backward compatibility - total_defense equals total_armor
	total_defense = total_armor

	return total_defense


func calculate_crit_stats() -> void:
	"""Calculate crit chance and damage from equipped items"""
	total_crit_chance = 5.0  # Base crit chance
	total_crit_damage = 150.0  # Base crit damage

	# Add crit stats from weapons
	if "weapon" in equipped_items and equipped_items["weapon"] != null:
		var weapon = equipped_items["weapon"]
		if weapon is Weapon:
			total_crit_chance += weapon.crit_chance - 5.0  # Subtract base to avoid double counting
			total_crit_damage += weapon.crit_damage - 150.0

	# Add crit stats from rings (damage slots)
	if "ring" in equipped_items and equipped_items["ring"] != null:
		var ring = equipped_items["ring"]
		if ring is Ring:
			total_crit_chance += ring.crit_chance - 5.0  # Subtract base to avoid double counting
			total_crit_damage += ring.crit_damage - 150.0


func get_total_dps() -> float:
	"""Get the hero's total DPS"""
	return total_dps


func get_total_defense() -> int:
	"""Get the hero's total defense"""
	return total_defense


func get_total_crit_chance() -> float:
	"""Get the hero's total crit chance"""
	return total_crit_chance


func get_total_crit_damage() -> float:
	"""Get the hero's total crit damage"""
	return total_crit_damage


func get_total_armor() -> int:
	"""Get the hero's total armor"""
	return total_armor


func get_total_evasion() -> int:
	"""Get the hero's total evasion"""
	return total_evasion


func get_total_energy_shield() -> int:
	"""Get the hero's total energy shield"""
	return total_energy_shield


func get_total_fire_resistance() -> int:
	"""Get the hero's total fire resistance"""
	return total_fire_resistance


func get_total_cold_resistance() -> int:
	"""Get the hero's total cold resistance"""
	return total_cold_resistance


func get_total_lightning_resistance() -> int:
	"""Get the hero's total lightning resistance"""
	return total_lightning_resistance


func get_health_percentage() -> float:
	"""Get health as a percentage (0.0 to 1.0)"""
	return health / max_health


func is_healthy() -> bool:
	"""Check if hero is alive and has health"""
	return is_alive and health > 0


func get_status_text() -> String:
	"""Get a text description of the hero's current status"""
	if not is_alive:
		return "Dead"
	elif is_clearing:
		return "Clearing areas"
	else:
		return "Resting"
