class_name Item extends Node

var item_name: String
var implicit: Implicit
var prefixes: Array[Affix] = []
var suffixes: Array[Affix] = []
var tier: int
var valid_tags: Array[String]

func display():
	print("\n----")
	print("name: %s" % self.item_name)
	print("dps: %d" % self.dps)
	print("implicit:\n	%s ~ value: %d ~ tier %d" %[self.implicit.affix_name, self.implicit.value, self.implicit.tier])
	print("prefixes:")
	for prefix in self.prefixes:
		print("	%s ~ value: %d ~ tier %d" %[prefix.affix_name, prefix.value, prefix.tier])
	print("suffixes:")
	for suffix in self.suffixes:
		print("	%s ~ value: %d ~ tier %d" %[suffix.affix_name, suffix.value, suffix.tier])
	print("----\n")

func get_display_text() -> String:
	var output = ""
	output += "----\n"
	output += ("name: %s\n" % self.item_name)
	output += "dps: %d\n" % self.dps
	output += ("implicit:\n	%s ~ value: %d ~ tier %d\n" %[self.implicit.affix_name, self.implicit.value, self.implicit.tier])
	output += "prefixes:\n"
	for prefix in self.prefixes:
		output += ("	%s ~ value: %d ~ tier %d\n" %[prefix.affix_name, prefix.value, prefix.tier])
	output += "suffixes:\n"
	for suffix in self.suffixes:
		output += ("	%s ~ value: %d ~ tier %d\n" %[suffix.affix_name, suffix.value, suffix.tier])
	output += "----\n"

	return output

func reroll_affix(affix: Affix):
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

func add_prefix():
	print("adding a prefix")
	var valid_prefixes: Array[Affix] = []
	if len(self.prefixes) < 3:
		#pick a random valid affix:
		for prefix: Affix in ItemAffixes.prefixes:
			if has_valid_tag(prefix) and not self.is_affix_on_item(prefix):
				valid_prefixes.append(prefix)
		print("valid: ", valid_prefixes)
	var new_prefix: Affix = valid_prefixes.pick_random()
	
	if new_prefix != null:
		self.prefixes.append(Affixes.from_affix(new_prefix))

func add_suffix():
	print("adding a suffix")
	var valid_suffixes: Array[Affix] = []
	if len(self.suffixes) < 3:
		#pick a random valid affix:
		for suffix: Affix in ItemAffixes.suffixes:
			if has_valid_tag(suffix) and not self.is_affix_on_item(suffix):
				valid_suffixes.append(suffix)
			print("valid: ", valid_suffixes)	
	var new_suffix = valid_suffixes.pick_random()
	
	if new_suffix != null:
		print(new_suffix.name)
		self.suffixes.append( Affixes.from_affix(new_suffix))
