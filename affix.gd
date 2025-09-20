class_name Affix extends Node

enum AffixType {IMPLICIT, PREFIX, SUFFIX}

var affix_name: String
var type: AffixType
var min_value: int
var max_value: int
var value: int
var tier: int
var tags: Array[String]

func _init(affix_name: String, type: AffixType, min_value: int, max_value: int, tags: Array[String]) -> void:
	self.affix_name = affix_name
	self.type = type
	self.tier = randi_range(1, 8)
	self.tags = tags
	self.min_value = min_value * (100/tier)
	self.max_value = max_value * (100/tier)
	self.value = randi_range(self.min_value, self.max_value)

func is_prefix() -> bool:
	return self.type == AffixType.PREFIX

func reroll():
	self.value = randi_range(self.min_value, self.max_value)
	print("reroll ", self.value)
	

func display():
	pass
