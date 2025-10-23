class_name Helmet extends Item

var base_armor: int
var base_energy_shield: int
var base_mana: int
var total_defense: int
var original_base_armor: int
var original_base_energy_shield: int
var original_base_mana: int

func update_value():
	# Calculate total armor, energy shield, and mana from affixes
	var total_armor = original_base_armor
	var total_energy_shield = original_base_energy_shield
	var total_mana = original_base_mana
	
	var affixes = self.prefixes + self.suffixes
	affixes.append(self.implicit)
	
	for affix: Affix in affixes:
		if Tag.ARMOR in affix.tags:
			total_armor += affix.value
		elif Tag.ENERGY_SHIELD in affix.tags:
			total_energy_shield += affix.value
		elif Tag.MANA in affix.tags:
			total_mana += affix.value
	
	# Store calculated values
	self.base_armor = total_armor
	self.base_energy_shield = total_energy_shield
	self.base_mana = total_mana
	self.total_defense = total_armor

func get_total_defense() -> int:
	# Return the stored total defense value
	return total_defense

func get_display_text() -> String:
	var output = ""
	output += "----\n"
	output += ("name: %s\n" % self.item_name)
	output += ("armor: %d\n" % self.base_armor)
	output += ("energy shield: %d\n" % self.base_energy_shield)
	output += ("mana: %d\n" % self.base_mana)
	output += ("implicit:\n	%s ~ value: %d ~ tier %d\n" %[self.implicit.affix_name, self.implicit.value, self.implicit.tier])
	output += "prefixes:\n"
	for prefix in self.prefixes:
		output += ("	%s ~ value: %d ~ tier %d\n" %[prefix.affix_name, prefix.value, prefix.tier])
	output += "suffixes:\n"
	for suffix in self.suffixes:
		output += ("	%s ~ value: %d ~ tier %d\n" %[suffix.affix_name, suffix.value, suffix.tier])
	output += "----\n"
	return output
