class_name Weapon extends Item

var base_damage: int
var base_damage_type: String
var base_speed: int
var dps: float
var phys_dps: int
var bleed_dps: int
var lightning_dps: int
var cold_dps: int
var fire_dps: int
var crit_chance: float = 5.0  # Base 5% crit chance
var crit_damage: float = 150.0  # Base 150% crit damage


func update_value() -> void:
	self.dps = self.compute_dps()


func compute_dps() -> float:
	var affixes = self.prefixes + self.suffixes
	affixes.append(self.implicit)

	var new_spd = self.base_speed
	var new_dps = self.base_damage
	var current_crit_chance = self.crit_chance
	var current_crit_damage = self.crit_damage

	print("Computing DPS - Base damage: ", new_dps, " Base speed: ", new_spd)
	print(
		"Base crit chance: ", current_crit_chance, "% Base crit damage: ", current_crit_damage, "%"
	)

	for affix: Affix in affixes:
		print(
			"Processing affix: ", affix.affix_name, " Value: ", affix.value, " Tags: ", affix.tags
		)
		# compute base damage
		if Tag.PHYSICAL in affix.tags and Tag.FLAT in affix.tags:
			new_dps += affix.value
			print("Added flat physical damage: ", affix.value, " New DPS: ", new_dps)
		if Tag.PHYSICAL in affix.tags and Tag.PERCENTAGE in affix.tags:
			var multiplier = 1.0 + (affix.value / 100.0)
			new_dps *= multiplier
			print(
				"Applied physical % damage: ",
				affix.value,
				"% Multiplier: ",
				multiplier,
				" New DPS: ",
				new_dps
			)
		# compute attack speed
		if Tag.SPEED in affix.tags:
			var speed_multiplier = 1.0 + affix.value / 100.0
			new_spd *= speed_multiplier
			print(
				"Applied speed: ",
				affix.value,
				"% Speed multiplier: ",
				speed_multiplier,
				" New speed: ",
				new_spd
			)
		# compute critical strike chance
		if Tag.CRITICAL in affix.tags and "Chance" in affix.affix_name:
			current_crit_chance += affix.value
			print(
				"Added crit chance: ", affix.value, "% New crit chance: ", current_crit_chance, "%"
			)
		# compute critical strike damage
		if Tag.CRITICAL in affix.tags and "Damage" in affix.affix_name:
			current_crit_damage += affix.value
			print(
				"Added crit damage: ", affix.value, "% New crit damage: ", current_crit_damage, "%"
			)

	# Apply attack speed
	new_dps *= new_spd

	# Apply critical strike calculation
	# DPS = (Base DPS * (1 - crit_chance/100)) + (Base DPS * crit_damage/100 * crit_chance/100)
	var non_crit_dps = new_dps * (1.0 - current_crit_chance / 100.0)
	var crit_dps = new_dps * (current_crit_damage / 100.0) * (current_crit_chance / 100.0)
	new_dps = non_crit_dps + crit_dps

	print(
		"Final DPS (with crit): ",
		new_dps,
		" Crit chance: ",
		current_crit_chance,
		"% Crit damage: ",
		current_crit_damage,
		"%"
	)
	return new_dps
