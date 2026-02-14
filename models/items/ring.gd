class_name Ring extends Item

var base_damage: int
var base_damage_type: String
var base_speed: int
var dps: float
var crit_chance: float = 5.0
var crit_damage: float = 150.0


func update_value() -> void:
	self.dps = self.compute_dps()


func compute_dps() -> float:
	var affixes = self.prefixes + self.suffixes
	affixes.append(self.implicit)

	var new_spd = self.base_speed
	var new_dps = self.base_damage
	var current_crit_chance = self.crit_chance
	var current_crit_damage = self.crit_damage

	for affix: Affix in affixes:
		if Tag.ATTACK in affix.tags:
			new_dps += affix.value
		elif Tag.SPEED in affix.tags:
			new_spd += affix.value
		elif Tag.CRITICAL in affix.tags:
			if "Chance" in affix.affix_name:
				current_crit_chance += affix.value
			elif "Damage" in affix.affix_name:
				current_crit_damage += affix.value

	# Calculate DPS with crit
	var crit_multiplier = 1.0 + (current_crit_chance / 100.0) * (current_crit_damage / 100.0)
	return new_dps * new_spd * crit_multiplier


func get_display_text() -> String:
	var output = ""
	output += "----\n"
	output += ("name: %s\n" % self.item_name)
	output += "dps: %.1f\n" % self.dps
	output += ("base damage: %d\n" % self.base_damage)
	output += ("base speed: %.1f\n" % self.base_speed)
	output += ("crit chance: %.1f%%\n" % self.crit_chance)
	output += ("crit damage: %.1f%%\n" % self.crit_damage)
	output += (
		"implicit:\n	%s ~ value: %d ~ tier %d\n"
		% [self.implicit.affix_name, self.implicit.value, self.implicit.tier]
	)
	output += "prefixes:\n"
	for prefix in self.prefixes:
		output += (
			"	%s ~ value: %d ~ tier %d\n" % [prefix.affix_name, prefix.value, prefix.tier]
		)
	output += "suffixes:\n"
	for suffix in self.suffixes:
		output += (
			"	%s ~ value: %d ~ tier %d\n" % [suffix.affix_name, suffix.value, suffix.tier]
		)
	output += "----\n"
	return output
