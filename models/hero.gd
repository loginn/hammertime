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
var total_chaos_resistance: int = 0
var current_energy_shield: float = 0.0
var total_crit_chance: float = 5.0
var total_crit_damage: float = 150.0

# DoT stats — aggregated from equipment
var total_bleed_chance: float = 0.0
var total_bleed_damage_min: float = 0.0
var total_bleed_damage_max: float = 0.0
var total_bleed_damage_pct: float = 0.0
var total_poison_chance: float = 0.0
var total_poison_damage_min: float = 0.0
var total_poison_damage_max: float = 0.0
var total_poison_damage_pct: float = 0.0
var total_burn_chance: float = 0.0
var total_burn_damage_min: float = 0.0
var total_burn_damage_max: float = 0.0
var total_burn_damage_pct: float = 0.0
var total_dot_dps: float = 0.0

# DoT tracking for pack-applied DoTs on hero
var active_dots: Array = []

# Per-element damage ranges -- populated from equipment, NOT serialized
# Keys: "physical", "fire", "cold", "lightning"
# Values: {"min": float, "max": float}
var damage_ranges: Dictionary = {
	"physical": {"min": 0.0, "max": 0.0},
	"fire": {"min": 0.0, "max": 0.0},
	"cold": {"min": 0.0, "max": 0.0},
	"lightning": {"min": 0.0, "max": 0.0},
}

# Spell damage tracking -- parallel to attack damage
var total_spell_dps: float = 0.0
var spell_damage_ranges: Dictionary = {
	"spell": {"min": 0.0, "max": 0.0},
	"spell_fire": {"min": 0.0, "max": 0.0},
	"spell_lightning": {"min": 0.0, "max": 0.0},
}

# Hero state
var is_alive: bool = true
var is_clearing: bool = false
var is_spell_user: bool = false


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
	is_spell_user = GameState.hero_archetype.spell_user if GameState.hero_archetype != null else false
	calculate_crit_stats()
	calculate_damage_ranges()
	calculate_spell_damage_ranges()
	calculate_dps()
	calculate_spell_dps()
	calculate_defense()
	calculate_dot_stats()
	current_energy_shield = float(total_energy_shield)
	# Sync health to new max_health after stat recalculation
	health = max_health


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
			var all_affixes: Array = weapon.prefixes.duplicate()
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
			var all_affixes: Array = ring.prefixes.duplicate()
			all_affixes.append_array(ring.suffixes)
			if ring.implicit:
				all_affixes.append(ring.implicit)
			var ring_ranges := StatCalculator.calculate_damage_range(
				ring.base_damage, ring.base_damage, all_affixes
			)
			for element in ring_ranges:
				damage_ranges[element]["min"] += ring_ranges[element]["min"]
				damage_ranges[element]["max"] += ring_ranges[element]["max"]

	# Apply archetype passive bonuses (Phase 51 — PASS-01)
	if GameState.hero_archetype != null:
		var bonuses: Dictionary = GameState.hero_archetype.passive_bonuses
		# Element-specific: physical_damage_more, fire_damage_more, cold_damage_more, lightning_damage_more
		for element in damage_ranges:
			var element_key: String = element + "_damage_more"
			if bonuses.has(element_key):
				damage_ranges[element]["min"] *= (1.0 + bonuses[element_key])
				damage_ranges[element]["max"] *= (1.0 + bonuses[element_key])
		# Channel bonus: attack_damage_more scales ALL attack elements (per D-06)
		if bonuses.has("attack_damage_more"):
			for element in damage_ranges:
				damage_ranges[element]["min"] *= (1.0 + bonuses["attack_damage_more"])
				damage_ranges[element]["max"] *= (1.0 + bonuses["attack_damage_more"])
		# General bonus: damage_more scales ALL attack elements (DEX, per D-07)
		if bonuses.has("damage_more"):
			for element in damage_ranges:
				damage_ranges[element]["min"] *= (1.0 + bonuses["damage_more"])
				damage_ranges[element]["max"] *= (1.0 + bonuses["damage_more"])


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
			var all_affixes: Array = weapon.prefixes.duplicate()
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


func calculate_spell_damage_ranges() -> void:
	"""Populate spell damage ranges from equipped weapon and ring affixes."""
	# Reset all spell elements to zero
	for element in spell_damage_ranges:
		spell_damage_ranges[element]["min"] = 0.0
		spell_damage_ranges[element]["max"] = 0.0

	# Weapon contribution: base spell damage + weapon affixes
	if "weapon" in equipped_items and equipped_items["weapon"] != null:
		var weapon = equipped_items["weapon"]
		if weapon is Weapon:
			var all_affixes: Array = weapon.prefixes.duplicate()
			all_affixes.append_array(weapon.suffixes)
			if weapon.implicit:
				all_affixes.append(weapon.implicit)
			var weapon_spell_ranges := StatCalculator.calculate_spell_damage_range(
				weapon.base_spell_damage_min, weapon.base_spell_damage_max, all_affixes
			)
			for element in weapon_spell_ranges:
				spell_damage_ranges[element]["min"] += weapon_spell_ranges[element]["min"]
				spell_damage_ranges[element]["max"] += weapon_spell_ranges[element]["max"]

	# Ring contribution: ring has no base spell damage but may have spell damage affixes/implicit
	if "ring" in equipped_items and equipped_items["ring"] != null:
		var ring = equipped_items["ring"]
		if ring is Ring:
			var all_affixes: Array = ring.prefixes.duplicate()
			all_affixes.append_array(ring.suffixes)
			if ring.implicit:
				all_affixes.append(ring.implicit)
			var ring_spell_ranges := StatCalculator.calculate_spell_damage_range(
				0, 0, all_affixes
			)
			for element in ring_spell_ranges:
				spell_damage_ranges[element]["min"] += ring_spell_ranges[element]["min"]
				spell_damage_ranges[element]["max"] += ring_spell_ranges[element]["max"]

	# Apply archetype passive bonuses (Phase 51 — PASS-01)
	if GameState.hero_archetype != null:
		var bonuses: Dictionary = GameState.hero_archetype.passive_bonuses
		# Element-specific via spell element mapping:
		# bonus "physical_damage_more" -> spell_damage_ranges["spell"]
		# bonus "fire_damage_more" -> spell_damage_ranges["spell_fire"]
		# bonus "lightning_damage_more" -> spell_damage_ranges["spell_lightning"]
		var spell_element_map: Dictionary = {
			"physical": "spell",
			"fire": "spell_fire",
			"lightning": "spell_lightning",
		}
		for bonus_elem in spell_element_map:
			var bonus_key: String = bonus_elem + "_damage_more"
			var spell_key: String = spell_element_map[bonus_elem]
			if bonuses.has(bonus_key) and spell_key in spell_damage_ranges:
				spell_damage_ranges[spell_key]["min"] *= (1.0 + bonuses[bonus_key])
				spell_damage_ranges[spell_key]["max"] *= (1.0 + bonuses[bonus_key])
		# Channel bonus: spell_damage_more scales ALL spell elements (per D-06)
		if bonuses.has("spell_damage_more"):
			for element in spell_damage_ranges:
				spell_damage_ranges[element]["min"] *= (1.0 + bonuses["spell_damage_more"])
				spell_damage_ranges[element]["max"] *= (1.0 + bonuses["spell_damage_more"])
		# General bonus: damage_more scales ALL spell elements (DEX, per D-07)
		if bonuses.has("damage_more"):
			for element in spell_damage_ranges:
				spell_damage_ranges[element]["min"] *= (1.0 + bonuses["damage_more"])
				spell_damage_ranges[element]["max"] *= (1.0 + bonuses["damage_more"])


func calculate_spell_dps() -> float:
	"""Calculate total spell DPS from spell damage ranges and cast speed."""
	# Sum average spell damage across ALL spell elements
	var avg_spell_damage := 0.0
	for element in spell_damage_ranges:
		var el_min: float = spell_damage_ranges[element]["min"]
		var el_max: float = spell_damage_ranges[element]["max"]
		avg_spell_damage += (el_min + el_max) / 2.0

	# Aggregate base_cast_speed from weapon + ring
	var total_base_cast_speed := 0.0
	if "weapon" in equipped_items and equipped_items["weapon"] != null:
		var weapon = equipped_items["weapon"]
		if weapon is Weapon:
			total_base_cast_speed += weapon.base_cast_speed
	if "ring" in equipped_items and equipped_items["ring"] != null:
		var ring = equipped_items["ring"]
		if ring is Ring:
			total_base_cast_speed += ring.base_cast_speed

	# No cast speed means no spell channel
	if total_base_cast_speed == 0.0:
		total_spell_dps = 0.0
		return total_spell_dps

	# Collect INCREASED_CAST_SPEED affixes from weapon + ring
	var cast_speed_affixes: Array = []
	for slot in ["weapon", "ring"]:
		if slot in equipped_items and equipped_items[slot] != null:
			var item = equipped_items[slot]
			if "prefixes" in item:
				cast_speed_affixes.append_array(item.prefixes)
			if "suffixes" in item:
				cast_speed_affixes.append_array(item.suffixes)
			if "implicit" in item and item.implicit != null:
				cast_speed_affixes.append(item.implicit)

	var additive_cast_speed_mult := 0.0
	for affix: Affix in cast_speed_affixes:
		if Tag.StatType.INCREASED_CAST_SPEED in affix.stat_types:
			additive_cast_speed_mult += affix.value / 100.0
	var effective_cast_speed := total_base_cast_speed * (1.0 + additive_cast_speed_mult)

	if effective_cast_speed == 0.0:
		total_spell_dps = 0.0
		return total_spell_dps

	# Apply shared crit multiplier (crit stats already calculated)
	var crit_multiplier := StatCalculator._calculate_crit_multiplier(
		total_crit_chance, total_crit_damage
	)

	total_spell_dps = avg_spell_damage * effective_cast_speed * crit_multiplier
	return total_spell_dps


func calculate_defense() -> int:
	"""Calculate total defense from equipped armor"""
	total_armor = 0
	total_evasion = 0
	total_energy_shield = 0
	total_fire_resistance = 0
	total_cold_resistance = 0
	total_lightning_resistance = 0
	total_chaos_resistance = 0

	# Start with base health (100)
	var total_health: int = 100

	# Add defense from armor pieces (computed stats from armor slots)
	for slot in ["helmet", "armor", "boots"]:
		if slot in equipped_items and equipped_items[slot] != null:
			var armor_item = equipped_items[slot]

			# Check for computed_armor property
			if "computed_armor" in armor_item:
				total_armor += armor_item.computed_armor

			# Check for computed_evasion property
			if "computed_evasion" in armor_item:
				total_evasion += armor_item.computed_evasion

			# Check for computed_energy_shield property
			if "computed_energy_shield" in armor_item:
				total_energy_shield += armor_item.computed_energy_shield

			# Check for computed_health property
			if "computed_health" in armor_item:
				total_health += armor_item.computed_health

	# Add resistance from suffixes on ALL equipment slots
	# (resistances are never baked into item base stats)
	for slot in ["helmet", "armor", "boots", "weapon", "ring"]:
		if slot in equipped_items and equipped_items[slot] != null:
			var item = equipped_items[slot]
			if "suffixes" in item:
				for suffix in item.suffixes:
					if Tag.StatType.FIRE_RESISTANCE in suffix.stat_types:
						total_fire_resistance += suffix.value
					if Tag.StatType.COLD_RESISTANCE in suffix.stat_types:
						total_cold_resistance += suffix.value
					if Tag.StatType.LIGHTNING_RESISTANCE in suffix.stat_types:
						total_lightning_resistance += suffix.value
					if Tag.StatType.CHAOS_RESISTANCE in suffix.stat_types:
						total_chaos_resistance += suffix.value
					if Tag.StatType.ALL_RESISTANCE in suffix.stat_types:
						total_fire_resistance += suffix.value
						total_cold_resistance += suffix.value
						total_lightning_resistance += suffix.value

	# Add FLAT_HEALTH and FLAT_ARMOR from weapon/ring suffixes ONLY.
	# Armor slots (helmet, armor, boots) already bake these into computed_health/computed_armor
	# via their update_value() -> StatCalculator.calculate_flat_stat() calls.
	for slot in ["weapon", "ring"]:
		if slot in equipped_items and equipped_items[slot] != null:
			var item = equipped_items[slot]
			if "suffixes" in item:
				for suffix in item.suffixes:
					if Tag.StatType.FLAT_HEALTH in suffix.stat_types:
						total_health += suffix.value
					if Tag.StatType.FLAT_ARMOR in suffix.stat_types:
						total_armor += suffix.value

	# Apply global PERCENT_HEALTH from prefixes on all equipment
	# Item-level update_value() applies PERCENT_HEALTH to individual item base_health,
	# but a global pass ensures the modifier scales the entire health pool.
	var all_percent_health_affixes: Array = []
	for slot in ["helmet", "armor", "boots", "weapon", "ring"]:
		if slot in equipped_items and equipped_items[slot] != null:
			var item = equipped_items[slot]
			if "prefixes" in item:
				all_percent_health_affixes.append_array(item.prefixes)
	total_health = int(StatCalculator.calculate_percentage_stat(
		float(total_health), all_percent_health_affixes, Tag.StatType.PERCENT_HEALTH
	))

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


func get_total_spell_dps() -> float:
	"""Get the hero's total spell DPS"""
	return total_spell_dps


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


func get_total_chaos_resistance() -> int:
	"""Get the hero's total chaos resistance"""
	return total_chaos_resistance


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


func calculate_dot_stats() -> void:
	"""Aggregate DoT stats (chance, flat damage, percentage) from all equipment."""
	total_bleed_chance = 0.0
	total_bleed_damage_min = 0.0
	total_bleed_damage_max = 0.0
	total_bleed_damage_pct = 0.0
	total_poison_chance = 0.0
	total_poison_damage_min = 0.0
	total_poison_damage_max = 0.0
	total_poison_damage_pct = 0.0
	total_burn_chance = 0.0
	total_burn_damage_min = 0.0
	total_burn_damage_max = 0.0
	total_burn_damage_pct = 0.0

	for slot in ["weapon", "ring", "helmet", "armor", "boots"]:
		if slot not in equipped_items or equipped_items[slot] == null:
			continue
		var item = equipped_items[slot]
		var all_affixes: Array = []
		if "prefixes" in item:
			all_affixes.append_array(item.prefixes)
		if "suffixes" in item:
			all_affixes.append_array(item.suffixes)
		if "implicit" in item and item.implicit != null:
			all_affixes.append(item.implicit)

		for affix: Affix in all_affixes:
			# Bleed chance
			if Tag.StatType.BLEED_CHANCE in affix.stat_types:
				total_bleed_chance += affix.value
			# Bleed damage: flat (add_min > 0) or percentage (add_min == 0 and value > 0)
			if Tag.StatType.BLEED_DAMAGE in affix.stat_types:
				if affix.add_min > 0:
					total_bleed_damage_min += affix.add_min
					total_bleed_damage_max += affix.add_max
				elif affix.value > 0:
					total_bleed_damage_pct += affix.value
			# Poison chance
			if Tag.StatType.POISON_CHANCE in affix.stat_types:
				total_poison_chance += affix.value
			# Poison damage: flat or percentage
			if Tag.StatType.POISON_DAMAGE in affix.stat_types:
				if affix.add_min > 0:
					total_poison_damage_min += affix.add_min
					total_poison_damage_max += affix.add_max
				elif affix.value > 0:
					total_poison_damage_pct += affix.value
			# Burn chance
			if Tag.StatType.BURN_CHANCE in affix.stat_types:
				total_burn_chance += affix.value
			# Burn damage: flat or percentage
			if Tag.StatType.BURN_DAMAGE in affix.stat_types:
				if affix.add_min > 0:
					total_burn_damage_min += affix.add_min
					total_burn_damage_max += affix.add_max
				elif affix.value > 0:
					total_burn_damage_pct += affix.value

	# Apply archetype passive bonuses to DoT stats (Phase 51 — PASS-01, PASS-02)
	if GameState.hero_archetype != null:
		var bonuses: Dictionary = GameState.hero_archetype.passive_bonuses
		# Chance bonuses: multiply total (per D-08). Values are decimals (0.20 = 20%)
		if bonuses.has("bleed_chance_more"):
			total_bleed_chance *= (1.0 + bonuses["bleed_chance_more"])
		if bonuses.has("poison_chance_more"):
			total_poison_chance *= (1.0 + bonuses["poison_chance_more"])
		if bonuses.has("burn_chance_more"):
			total_burn_chance *= (1.0 + bonuses["burn_chance_more"])
		# Damage bonuses: convert decimal to percentage then add (per D-08, Pitfall 6)
		# 0.15 decimal -> 15.0 percentage points added to total_X_damage_pct
		if bonuses.has("bleed_damage_more"):
			total_bleed_damage_pct += bonuses["bleed_damage_more"] * 100.0
		if bonuses.has("poison_damage_more"):
			total_poison_damage_pct += bonuses["poison_damage_more"] * 100.0
		if bonuses.has("burn_damage_more"):
			total_burn_damage_pct += bonuses["burn_damage_more"] * 100.0

	calculate_dot_dps()


func calculate_dot_dps() -> void:
	"""Calculate expected DoT DPS for hero stats display."""
	total_dot_dps = 0.0

	if not is_spell_user:
		# Attack-mode: bleed + poison
		var attack_speed := 1.0
		if "weapon" in equipped_items and equipped_items["weapon"] != null:
			var weapon = equipped_items["weapon"]
			if weapon is Weapon:
				attack_speed = weapon.base_attack_speed

		# Bleed DPS
		if total_bleed_chance > 0.0:
			var avg_hit_damage := 0.0
			for element in damage_ranges:
				var el_min: float = damage_ranges[element]["min"]
				var el_max: float = damage_ranges[element]["max"]
				avg_hit_damage += (el_min + el_max) / 2.0

			var bleed_base_pct := 0.15
			var avg_flat_bleed := (total_bleed_damage_min + total_bleed_damage_max) / 2.0
			var bleed_scaling := avg_flat_bleed / maxf(avg_hit_damage, 1.0)
			var tick_damage := avg_hit_damage * (bleed_base_pct + bleed_scaling) * (1.0 + total_bleed_damage_pct / 100.0)
			var effective_stacks := minf(attack_speed * (total_bleed_chance / 100.0) * 4.0, 8.0)
			total_dot_dps += tick_damage * effective_stacks

		# Poison DPS
		if total_poison_chance > 0.0:
			var avg_flat_poison := (total_poison_damage_min + total_poison_damage_max) / 2.0
			var tick_per_stack := avg_flat_poison * (1.0 + total_poison_damage_pct / 100.0)
			var effective_stacks := attack_speed * (total_poison_chance / 100.0) * 4.0
			total_dot_dps += tick_per_stack * effective_stacks
	else:
		# Spell-mode: burn only
		if total_burn_chance > 0.0:
			var avg_spell_hit_damage := 0.0
			for element in spell_damage_ranges:
				var el_min: float = spell_damage_ranges[element]["min"]
				var el_max: float = spell_damage_ranges[element]["max"]
				avg_spell_hit_damage += (el_min + el_max) / 2.0

			var burn_base_pct := 0.25
			var avg_flat_burn := (total_burn_damage_min + total_burn_damage_max) / 2.0
			var burn_scaling := avg_flat_burn / maxf(avg_spell_hit_damage, 1.0)
			var tick_damage := avg_spell_hit_damage * (burn_base_pct + burn_scaling) * (1.0 + total_burn_damage_pct / 100.0)
			total_dot_dps += tick_damage * (total_burn_chance / 100.0)


func get_total_dot_dps() -> float:
	"""Get the hero's total DoT DPS"""
	return total_dot_dps


## Applies a pack DoT on the hero. Single stack refresh for pack DoTs.
## Returns the current stack count for this dot_type after application.
func apply_dot(dot_type: String, damage_per_tick: float, dot_element: String) -> int:
	var duration := 4
	# Single stack refresh: replace existing or add new
	var existing := active_dots.filter(func(d): return d["type"] == dot_type)
	if existing.size() > 0:
		existing[0]["damage_per_tick"] = damage_per_tick
		existing[0]["ticks_remaining"] = duration
		existing[0]["element"] = dot_element
	else:
		active_dots.append({
			"type": dot_type,
			"damage_per_tick": damage_per_tick,
			"ticks_remaining": duration,
			"element": dot_element,
		})
	return active_dots.filter(func(d): return d["type"] == dot_type).size()


## Processes all active DoTs on hero: accumulates damage per type, decrements ticks, removes expired.
## Returns array of {"type": String, "damage": float, "element": String} for each type that ticked.
func process_dot_tick() -> Array:
	var damage_by_type: Dictionary = {}
	var element_by_type: Dictionary = {}
	for dot in active_dots:
		var t: String = dot["type"]
		if t not in damage_by_type:
			damage_by_type[t] = 0.0
			element_by_type[t] = dot["element"]
		damage_by_type[t] += dot["damage_per_tick"]
		dot["ticks_remaining"] -= 1

	# Remove expired entries
	active_dots = active_dots.filter(func(d): return d["ticks_remaining"] > 0)

	# Build result array
	var results: Array = []
	for t in damage_by_type:
		results.append({"type": t, "damage": damage_by_type[t], "element": element_by_type[t]})
	return results


## Removes all active DoT effects on hero.
func clear_dots() -> void:
	active_dots.clear()
