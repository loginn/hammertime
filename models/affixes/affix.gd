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


func display() -> void:
	pass
