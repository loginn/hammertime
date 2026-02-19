class_name Helmet extends Item

var computed_armor: int
var computed_energy_shield: int
var computed_mana: int
var computed_evasion: int
var computed_health: int
var total_defense: int
var base_armor: int
var base_energy_shield: int
var base_mana: int
var base_evasion: int
var base_health: int


func update_value() -> void:
	var all_affixes := self.prefixes + self.suffixes
	if self.implicit != null:
		all_affixes.append(self.implicit)

	# Apply flat additions first
	var flat_armor := self.base_armor + int(
		StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_ARMOR)
	)
	var flat_evasion := self.base_evasion + int(
		StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_EVASION)
	)
	var flat_energy_shield := self.base_energy_shield + int(
		StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_ENERGY_SHIELD)
	)
	var flat_health := self.base_health + int(
		StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_HEALTH)
	)

	# Then apply percentage modifiers to (base + flat)
	self.computed_armor = int(
		StatCalculator.calculate_percentage_stat(flat_armor, all_affixes, Tag.StatType.PERCENT_ARMOR)
	)
	self.computed_evasion = int(
		StatCalculator.calculate_percentage_stat(
			flat_evasion, all_affixes, Tag.StatType.PERCENT_EVASION
		)
	)
	self.computed_energy_shield = int(
		StatCalculator.calculate_percentage_stat(
			flat_energy_shield, all_affixes, Tag.StatType.PERCENT_ENERGY_SHIELD
		)
	)
	self.computed_health = int(
		StatCalculator.calculate_percentage_stat(flat_health, all_affixes, Tag.StatType.PERCENT_HEALTH)
	)

	# Mana (no percentage modifier currently)
	self.computed_mana = (
		self.base_mana
		+ int(StatCalculator.calculate_flat_stat(all_affixes, Tag.StatType.FLAT_MANA))
	)

	self.total_defense = self.computed_armor


func get_total_defense() -> int:
	# Return the stored total defense value
	return total_defense


func get_display_text() -> String:
	var output = ""
	output += "----\n"
	output += ("name: %s\n" % self.item_name)
	output += ("armor: %d\n" % self.computed_armor)
	if self.computed_evasion > 0:
		output += ("evasion: %d\n" % self.computed_evasion)
	output += ("energy shield: %d\n" % self.computed_energy_shield)
	if self.computed_health > 0:
		output += ("health: %d\n" % self.computed_health)
	output += ("mana: %d\n" % self.computed_mana)
	if self.implicit != null:
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
