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
var current_energy_shield: float = 0.0
var total_crit_chance: float = 5.0
var total_crit_damage: float = 150.0

# Per-element damage ranges -- populated from equipment, NOT serialized
# Keys: "physical", "fire", "cold", "lightning"
# Values: {"min": float, "max": float}
var damage_ranges: Dictionary = {
	"physical": {"min": 0.0, "max": 0.0},
	"fire": {"min": 0.0, "max": 0.0},
	"cold": {"min": 0.0, "max": 0.0},
	"lightning": {"min": 0.0, "max": 0.0},
}

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
	"""Revive the hero with full health and full ES"""
	health = max_health
	current_energy_shield = float(total_energy_shield)
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
	calculate_crit_stats()
	calculate_damage_ranges()
	calculate_dps()
	calculate_defense()
	current_energy_shield = float(total_energy_shield)


func calculate_damage_ranges() -> void:
	"""Populate per-element damage ranges from equipped weapon and ring affixes."""
	# Reset to zero
	for element in damage_ranges:
		damage_ranges[element]["min"] = 0.0
		damage_ranges[element]["max"] = 0.0

	# Weapon contribution: base damage + weapon affixes
	if "weapon" in equipped_items and equipped_items["weapon"] != null:
		var weapon = equipped_items["weapon"]
		if weapon is Weapon:
			var all_affixes := weapon.prefixes.duplicate()
			all_affixes.append_array(weapon.suffixes)
			if weapon.implicit:
				all_affixes.append(weapon.implicit)
			var weapon_ranges := StatCalculator.calculate_damage_range(
				weapon.base_damage_min, weapon.base_damage_max, all_affixes
			)
			for element in weapon_ranges:
				damage_ranges[element]["min"] += weapon_ranges[element]["min"]
				damage_ranges[element]["max"] += weapon_ranges[element]["max"]

	# Ring contribution: ring has base_damage but no base_damage_min/max
	# Pass base_damage as both min and max (deterministic base, affixes add variance)
	if "ring" in equipped_items and equipped_items["ring"] != null:
		var ring = equipped_items["ring"]
		if ring is Ring:
			var all_affixes := ring.prefixes.duplicate()
			all_affixes.append_array(ring.suffixes)
			if ring.implicit:
				all_affixes.append(ring.implicit)
			var ring_ranges := StatCalculator.calculate_damage_range(
				ring.base_damage, ring.base_damage, all_affixes
			)
			for element in ring_ranges:
				damage_ranges[element]["min"] += ring_ranges[element]["min"]
				damage_ranges[element]["max"] += ring_ranges[element]["max"]


func calculate_dps() -> float:
	"""Calculate total DPS from per-element damage range averages."""
	# Sum average damage across all elements
	var total_avg_damage := 0.0
	for element in damage_ranges:
		var el_min: float = damage_ranges[element]["min"]
		var el_max: float = damage_ranges[element]["max"]
		total_avg_damage += (el_min + el_max) / 2.0

	# Apply speed multiplier from weapon
	var speed := 1.0
	if "weapon" in equipped_items and equipped_items["weapon"] != null:
		var weapon = equipped_items["weapon"]
		if weapon is Weapon:
			speed = float(weapon.base_speed)
			# Apply speed modifiers from affixes
			var all_affixes := weapon.prefixes.duplicate()
			all_affixes.append_array(weapon.suffixes)
			if weapon.implicit:
				all_affixes.append(weapon.implicit)
			var additive_speed_mult := 0.0
			for affix: Affix in all_affixes:
				if Tag.StatType.INCREASED_SPEED in affix.stat_types:
					additive_speed_mult += affix.value / 100.0
			speed *= (1.0 + additive_speed_mult)

	# Apply crit multiplier (crit stats already calculated in update_stats order)
	var crit_multiplier := StatCalculator._calculate_crit_multiplier(
		total_crit_chance, total_crit_damage
	)

	total_dps = total_avg_damage * speed * crit_multiplier
	return total_dps


func calculate_defense() -> int:
	"""Calculate total defense from equipped armor"""
	total_armor = 0
	total_evasion = 0
	total_energy_shield = 0
	total_fire_resistance = 0
	total_cold_resistance = 0
	total_lightning_resistance = 0

	# Start with base health (100)
	var total_health: int = 100

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

			# Check for base_health property
			if "base_health" in armor_item:
				total_health += armor_item.base_health

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

	# Update max_health from equipment
	max_health = float(total_health)

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


func get_current_energy_shield() -> float:
	"""Get the hero's current energy shield"""
	return current_energy_shield


func apply_damage(life_damage: float, es_damage: float) -> void:
	"""Apply pre-calculated defense-aware damage split to hero.
	Called by gameplay_view after DefenseCalculator computes the split."""
	current_energy_shield = maxf(0.0, current_energy_shield - es_damage)
	health -= life_damage
	health = maxf(0.0, health)
	if health <= 0:
		die()


func recharge_energy_shield() -> void:
	"""Recharge 33% of max ES between pack fights.
	Called by combat system between area clears."""
	var recharge_amount := float(total_energy_shield) * 0.33
	current_energy_shield = minf(
		current_energy_shield + recharge_amount, float(total_energy_shield)
	)


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
