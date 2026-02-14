class_name Affix extends Resource

enum AffixType { IMPLICIT, PREFIX, SUFFIX }

var affix_name: String
var type: AffixType
var min_value: int
var max_value: int
var value: int
var tier: int
var tags: Array[String]


func _init(
	p_name: String = "",
	p_type: AffixType = AffixType.PREFIX,
	p_min: int = 0,
	p_max: int = 0,
	p_tags: Array[String] = []
) -> void:
	self.affix_name = p_name
	self.type = p_type
	self.tier = randi_range(1, 8)
	self.tags = p_tags
	# Tier 1 is highest, so higher tier numbers = lower values
	self.min_value = p_min * (9 - tier)
	self.max_value = p_max * (9 - tier)
	self.value = randi_range(self.min_value, self.max_value)


func is_prefix() -> bool:
	return self.type == AffixType.PREFIX


func reroll() -> void:
	self.value = randi_range(self.min_value, self.max_value)
	print("reroll ", self.value)


func display() -> void:
	pass
