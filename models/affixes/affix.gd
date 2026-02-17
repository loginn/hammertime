class_name Affix extends Resource

enum AffixType { IMPLICIT, PREFIX, SUFFIX }

var affix_name: String
var type: AffixType
var min_value: int
var max_value: int
var value: int
var tier: int
var tags: Array[String]
var stat_types: Array[int] = []
var tier_range: Vector2i = Vector2i(1, 8)
var base_min: int = 0
var base_max: int = 0


func _init(
	p_name: String = "",
	p_type: AffixType = AffixType.PREFIX,
	p_min: int = 0,
	p_max: int = 0,
	p_tags: Array[String] = [],
	p_stat_types: Array[int] = [],
	p_tier_range: Vector2i = Vector2i(1, 8)
) -> void:
	self.affix_name = p_name
	self.type = p_type
	self.tier_range = p_tier_range
	self.base_min = p_min
	self.base_max = p_max
	self.tier = randi_range(tier_range.x, tier_range.y)
	self.tags = p_tags
	self.stat_types = p_stat_types
	# Tier 1 is highest, so higher tier numbers = lower values
	self.min_value = p_min * (tier_range.y + 1 - tier)
	self.max_value = p_max * (tier_range.y + 1 - tier)
	self.value = randi_range(self.min_value, self.max_value)


func is_prefix() -> bool:
	return self.type == AffixType.PREFIX


func reroll() -> void:
	self.value = randi_range(self.min_value, self.max_value)
	print("reroll ", self.value)


func to_dict() -> Dictionary:
	return {
		"affix_name": affix_name,
		"type": int(type),
		"value": value,
		"tier": tier,
		"tags": Array(tags),
		"stat_types": Array(stat_types),
		"tier_range_x": tier_range.x,
		"tier_range_y": tier_range.y,
		"base_min": base_min,
		"base_max": base_max,
		"min_value": min_value,
		"max_value": max_value,
	}


static func from_dict(data: Dictionary) -> Affix:
	var tags_array: Array[String] = []
	for t in data.get("tags", []):
		tags_array.append(str(t))

	var stat_types_array: Array[int] = []
	for s in data.get("stat_types", []):
		stat_types_array.append(int(s))

	var tier_range_vec := Vector2i(
		int(data.get("tier_range_x", 1)),
		int(data.get("tier_range_y", 8))
	)

	var affix := Affix.new(
		str(data.get("affix_name", "")),
		int(data.get("type", 0)) as AffixType,
		int(data.get("base_min", 0)),
		int(data.get("base_max", 0)),
		tags_array,
		stat_types_array,
		tier_range_vec
	)

	# Overwrite randomized fields with saved values
	affix.tier = int(data.get("tier", affix.tier))
	affix.value = int(data.get("value", affix.value))
	affix.min_value = int(data.get("min_value", affix.min_value))
	affix.max_value = int(data.get("max_value", affix.max_value))

	return affix


func display() -> void:
	pass
