class_name CraftableItem extends Resource

enum Rarity { NORMAL, MAGIC, RARE }

const RARITY_LIMITS: Dictionary = {
	Rarity.NORMAL: { "prefixes": 0, "suffixes": 0 },
	Rarity.MAGIC: { "prefixes": 1, "suffixes": 1 },
	Rarity.RARE: { "prefixes": 3, "suffixes": 3 },
}

var item_name: String
var material_tier: Tag_List.MaterialTier
var base_id: String

var implicit: Implicit
var prefixes: Array[Affix] = []
var suffixes: Array[Affix] = []
var valid_tags: Array[String] = []
var rarity: Rarity = Rarity.NORMAL


func update_value() -> void:
	pass


func max_prefixes() -> int:
	return RARITY_LIMITS[rarity]["prefixes"]

func max_suffixes() -> int:
	return RARITY_LIMITS[rarity]["suffixes"]


func get_rarity_color() -> Color:
	match rarity:
		Rarity.NORMAL:
			return Color.WHITE
		Rarity.MAGIC:
			return Color("#6888F5")
		Rarity.RARE:
			return Color("#FFD700")
		_:
			return Color.WHITE


func is_affix_on_item(affix: Affix) -> bool:
	for prefix in prefixes:
		if affix.affix_name == prefix.affix_name:
			return true
	for suffix in suffixes:
		if affix.affix_name == suffix.affix_name:
			return true
	return false


func has_valid_tag(affix: Affix) -> bool:
	for tag in valid_tags:
		if tag in affix.tags:
			return true
	return false


func _get_material_tier_bounds() -> Vector2i:
	var config: Dictionary = Tag_List.MATERIAL_TIER_CONFIG[material_tier]
	return Vector2i(config["min_affix_tier"], config["max_affix_tier"])


func _get_prefix_pool() -> Array[Affix]:
	return ItemAffixes.prefixes

func _get_suffix_pool() -> Array[Affix]:
	return ItemAffixes.suffixes


func add_prefix() -> bool:
	if prefixes.size() >= max_prefixes():
		return false

	var bounds := _get_material_tier_bounds()
	var valid_prefixes: Array[Affix] = []
	for prefix: Affix in _get_prefix_pool():
		if has_valid_tag(prefix) and not is_affix_on_item(prefix) \
				and Affixes.can_roll_in_tier_range(prefix, bounds.x, bounds.y):
			valid_prefixes.append(prefix)

	if valid_prefixes.is_empty():
		return false

	var new_prefix: Affix = valid_prefixes.pick_random()
	if new_prefix != null:
		prefixes.append(Affixes.from_affix_gated(new_prefix, bounds.x, bounds.y))
		return true

	return false


func add_suffix() -> bool:
	if suffixes.size() >= max_suffixes():
		return false

	var bounds := _get_material_tier_bounds()
	var valid_suffixes: Array[Affix] = []
	for suffix: Affix in _get_suffix_pool():
		if has_valid_tag(suffix) and not is_affix_on_item(suffix) \
				and Affixes.can_roll_in_tier_range(suffix, bounds.x, bounds.y):
			valid_suffixes.append(suffix)

	if valid_suffixes.is_empty():
		return false

	var new_suffix = valid_suffixes.pick_random()
	if new_suffix != null:
		suffixes.append(Affixes.from_affix_gated(new_suffix, bounds.x, bounds.y))
		return true

	return false
