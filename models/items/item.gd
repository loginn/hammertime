class_name Item extends Node

var item_name: String
var implicit: Implicit
var prefixes: Array[Affix] = []
var suffixes: Array[Affix] = []
var tier: int
var valid_tags: Array[String]


func display() -> void:
	print("\n----")
	print("name: %s" % self.item_name)

	# Display DPS only if the item has it (weapons and rings)
	if has_method("get_dps") or "dps" in self:
		print("dps: %.1f" % self.dps)

	# Display defense stats for defense items
	if has_method("get_total_defense"):
		var total_defense = self.total_defense
		if total_defense > 0:
			print("defense: %d" % total_defense)

	print(
		(
			"implicit:\n	%s ~ value: %d ~ tier %d"
			% [self.implicit.affix_name, self.implicit.value, self.implicit.tier]
		)
	)
	print("prefixes:")
	for prefix in self.prefixes:
		print("	%s ~ value: %d ~ tier %d" % [prefix.affix_name, prefix.value, prefix.tier])
	print("suffixes:")
	for suffix in self.suffixes:
		print("	%s ~ value: %d ~ tier %d" % [suffix.affix_name, suffix.value, suffix.tier])
	print("----\n")


func get_display_text() -> String:
	var output = ""
	output += "----\n"
	output += ("name: %s\n" % self.item_name)

	# Display DPS only if the item has it (weapons and rings)
	if has_method("get_dps") or "dps" in self:
		output += "dps: %.1f\n" % self.dps

	# Display defense stats for defense items
	if has_method("get_total_defense"):
		var total_defense = self.total_defense
		if total_defense > 0:
			output += "defense: %d\n" % total_defense

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


func reroll_affix(affix: Affix) -> void:
	affix.reroll()


func is_affix_on_item(affix: Affix) -> bool:
	print(self.prefixes)
	for prefix in self.prefixes:
		if affix.affix_name == prefix.affix_name:
			print("affix ", affix.affix_name, " is already on item")
			return true
	for suffix in self.suffixes:
		if affix.affix_name == suffix.affix_name:
			print("affix ", affix.affix_name, " is already on item")
			return true
	return false


func has_valid_tag(affix: Affix) -> bool:
	for tag in self.valid_tags:
		if tag in affix.tags:
			return true
	return false


func add_prefix() -> void:
	print("adding a prefix")
	if len(self.prefixes) >= 3:
		print("Cannot add more prefixes - item already has 3")
		return

	var valid_prefixes: Array[Affix] = []
	#pick a random valid affix:
	for prefix: Affix in ItemAffixes.prefixes:
		if has_valid_tag(prefix) and not self.is_affix_on_item(prefix):
			valid_prefixes.append(prefix)
	print("valid: ", valid_prefixes)

	if valid_prefixes.is_empty():
		print("No valid prefixes available for this item")
		return

	var new_prefix: Affix = valid_prefixes.pick_random()
	if new_prefix != null:
		self.prefixes.append(Affixes.from_affix(new_prefix))
		print("Added prefix: ", new_prefix.affix_name)


func add_suffix() -> void:
	print("adding a suffix")
	if len(self.suffixes) >= 3:
		print("Cannot add more suffixes - item already has 3")
		return

	var valid_suffixes: Array[Affix] = []
	#pick a random valid affix:
	for suffix: Affix in ItemAffixes.suffixes:
		if has_valid_tag(suffix) and not self.is_affix_on_item(suffix):
			valid_suffixes.append(suffix)
	print("valid: ", valid_suffixes)

	if valid_suffixes.is_empty():
		print("No valid suffixes available for this item")
		return

	var new_suffix = valid_suffixes.pick_random()
	if new_suffix != null:
		print("Added suffix: ", new_suffix.affix_name)
		self.suffixes.append(Affixes.from_affix(new_suffix))
