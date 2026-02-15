class_name Armor extends Item

var base_armor: int
var base_energy_shield: int
var base_health: int
var total_defense: int
var original_base_armor: int
var original_base_energy_shield: int
var original_base_health: int


func update_value() -> void:
	var all_affixes := self.prefixes + self.suffixes
	all_affixes.append(self.implicit)

	self.base_armor = (
		self.original_base_armor
		+ int(StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_ARMOR))
	)
	self.base_energy_shield = (
		self.original_base_energy_shield
		+ int(StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_ENERGY_SHIELD))
	)
	self.base_health = (
		self.original_base_health
		+ int(StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_HEALTH))
	)
	self.total_defense = self.base_armor


func get_total_defense() -> int:
	# Return the stored total defense value
	return total_defense


func get_display_text() -> String:
	var output = ""
	output += "----\n"
	output += ("name: %s\n" % self.item_name)
	output += ("armor: %d\n" % self.base_armor)
	output += ("energy shield: %d\n" % self.base_energy_shield)
	output += ("health: %d\n" % self.base_health)
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
