class_name Item extends Resource

enum Rarity { NORMAL, MAGIC, RARE }

const RARITY_LIMITS: Dictionary = {
	Rarity.NORMAL: { "prefixes": 0, "suffixes": 0 },
	Rarity.MAGIC: { "prefixes": 1, "suffixes": 1 },
	Rarity.RARE: { "prefixes": 3, "suffixes": 3 },
}

var item_name: String
var implicit: Implicit
var prefixes: Array[Affix] = []
var suffixes: Array[Affix] = []
var tier: int
var valid_tags: Array[String]
var rarity: Rarity = Rarity.NORMAL
var custom_max_prefixes = null
var custom_max_suffixes = null


func max_prefixes() -> int:
	if custom_max_prefixes != null:
		return custom_max_prefixes
	return RARITY_LIMITS[rarity]["prefixes"]


func max_suffixes() -> int:
	if custom_max_suffixes != null:
		return custom_max_suffixes
	return RARITY_LIMITS[rarity]["suffixes"]


func get_rarity_color() -> Color:
	match rarity:
		Rarity.NORMAL:
			return Color.WHITE
		Rarity.MAGIC:
			return Color("#6888F5")  # Soft blue, readable on dark
		Rarity.RARE:
			return Color("#FFD700")  # Gold yellow
		_:
			return Color.WHITE


## Returns the type string for serialization. Override in concrete subclasses.
func get_item_type_string() -> String:
	return ""


## Serializes this item to a dictionary for save/load.
func to_dict() -> Dictionary:
	var prefix_dicts: Array = []
	for p in prefixes:
		prefix_dicts.append(p.to_dict())

	var suffix_dicts: Array = []
	for s in suffixes:
		suffix_dicts.append(s.to_dict())

	return {
		"item_type": get_item_type_string(),
		"item_name": item_name,
		"tier": tier,
		"rarity": int(rarity),
		"valid_tags": Array(valid_tags),
		"implicit": implicit.to_dict() if implicit != null else {},
		"prefixes": prefix_dicts,
		"suffixes": suffix_dicts,
	}


## Registry of concrete item types for deserialization.
const ITEM_TYPE_STRINGS: PackedStringArray = [
	"LightSword", "BasicArmor", "BasicHelmet", "BasicBoots", "BasicRing"
]


## Creates an item from a serialized dictionary. Returns null if type unknown.
static func create_from_dict(data: Dictionary) -> Item:
	var item_type_str: String = data.get("item_type", "")

	var item: Item = null
	match item_type_str:
		"LightSword":
			item = LightSword.new()
		"BasicArmor":
			item = BasicArmor.new()
		"BasicHelmet":
			item = BasicHelmet.new()
		"BasicBoots":
			item = BasicBoots.new()
		"BasicRing":
			item = BasicRing.new()
		_:
			push_warning("Unknown item type for deserialization: " + item_type_str)
			return null

	# Restore rarity
	item.rarity = int(data.get("rarity", 0)) as Rarity

	# Restore implicit
	var implicit_data: Dictionary = data.get("implicit", {})
	if not implicit_data.is_empty():
		item.implicit = Implicit.from_dict(implicit_data)

	# Restore prefixes
	item.prefixes.clear()
	var prefix_dicts: Array = data.get("prefixes", [])
	for p_dict in prefix_dicts:
		item.prefixes.append(Affix.from_dict(p_dict))

	# Restore suffixes
	item.suffixes.clear()
	var suffix_dicts: Array = data.get("suffixes", [])
	for s_dict in suffix_dicts:
		item.suffixes.append(Affix.from_dict(s_dict))

	# Recalculate derived stats from restored affixes
	item.update_value()

	return item


## Recalculates item stats from current affixes.
## Override in subclasses. Called after any affix modification (reroll, add prefix/suffix).
## Implementations should delegate to StatCalculator for actual math.
func update_value() -> void:
	pass


func display() -> void:
	print("\n----")
	print("name: %s" % self.item_name)

	# Display DPS only if the item has it (weapons and rings)
	if self is Weapon or self is Ring:
		print("dps: %.1f" % self.dps)

	# Display defense stats for defense items
	if self is Armor or self is Helmet or self is Boots:
		var total_defense = self.total_defense
		if total_defense > 0:
			print("defense: %d" % total_defense)

	if self.implicit != null:
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
	if self is Weapon or self is Ring:
		output += "dps: %.1f\n" % self.dps

	# Display defense stats for defense items
	if self is Armor or self is Helmet or self is Boots:
		var total_defense = self.total_defense
		if total_defense > 0:
			output += "defense: %d\n" % total_defense

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


func add_prefix() -> bool:
	print("adding a prefix")
	if len(self.prefixes) >= max_prefixes():
		print("Cannot add more prefixes - at rarity limit (%d)" % max_prefixes())
		return false

	var valid_prefixes: Array[Affix] = []
	#pick a random valid affix:
	for prefix: Affix in ItemAffixes.prefixes:
		if has_valid_tag(prefix) and not self.is_affix_on_item(prefix):
			valid_prefixes.append(prefix)
	print("valid: ", valid_prefixes)

	if valid_prefixes.is_empty():
		print("No valid prefixes available for this item")
		return false

	var new_prefix: Affix = valid_prefixes.pick_random()
	if new_prefix != null:
		self.prefixes.append(Affixes.from_affix(new_prefix))
		print("Added prefix: ", new_prefix.affix_name)
		return true

	return false


func add_suffix() -> bool:
	print("adding a suffix")
	if len(self.suffixes) >= max_suffixes():
		print("Cannot add more suffixes - at rarity limit (%d)" % max_suffixes())
		return false

	var valid_suffixes: Array[Affix] = []
	#pick a random valid affix:
	for suffix: Affix in ItemAffixes.suffixes:
		if has_valid_tag(suffix) and not self.is_affix_on_item(suffix):
			valid_suffixes.append(suffix)
	print("valid: ", valid_suffixes)

	if valid_suffixes.is_empty():
		print("No valid suffixes available for this item")
		return false

	var new_suffix = valid_suffixes.pick_random()
	if new_suffix != null:
		print("Added suffix: ", new_suffix.affix_name)
		self.suffixes.append(Affixes.from_affix(new_suffix))
		return true

	return false
