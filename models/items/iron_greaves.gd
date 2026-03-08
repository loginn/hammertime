class_name IronGreaves extends Boots

const TIER_NAMES: Dictionary = {
	8: "Rusty Greaves", 7: "Iron Greaves", 6: "Steel Greaves",
	5: "Tempered Greaves", 4: "War Greaves", 3: "Champion Greaves",
	2: "Valiant Greaves", 1: "Sovereign Greaves",
}

const TIER_STATS: Dictionary = {
	8: {"armor": 3}, 7: {"armor": 5}, 6: {"armor": 9},
	5: {"armor": 14}, 4: {"armor": 20}, 3: {"armor": 28},
	2: {"armor": 36}, 1: {"armor": 46},
}


func get_item_type_string() -> String:
	return "IronGreaves"


func _init(p_tier: int = 8) -> void:
	self.rarity = Rarity.NORMAL
	self.tier = p_tier
	self.item_name = TIER_NAMES[p_tier]
	self.valid_tags = [Tag.STR, Tag.DEFENSE, Tag.ARMOR]
	var s = TIER_STATS[p_tier]
	self.base_armor = s["armor"]
	self.base_evasion = 0
	self.base_energy_shield = 0
	self.base_health = 0
	self.base_movement_speed = 0
	self.computed_armor = 0
	self.computed_evasion = 0
	self.computed_energy_shield = 0
	self.computed_health = 0
	self.computed_movement_speed = 0
	self.implicit = null
	self.update_value()
