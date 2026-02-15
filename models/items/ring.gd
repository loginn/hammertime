class_name Ring extends Item

var base_damage: int
var base_damage_type: String
var base_speed: int
var dps: float
var crit_chance: float = 5.0
var crit_damage: float = 150.0


func update_value() -> void:
	var all_affixes := self.prefixes + self.suffixes
	all_affixes.append(self.implicit)
	self.dps = StatCalculator.calculate_dps(
		self.base_damage, self.base_speed, all_affixes, self.crit_chance, self.crit_damage
	)


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
