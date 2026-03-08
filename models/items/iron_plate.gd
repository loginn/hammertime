class_name IronPlate extends Armor

const TIER_NAMES: Dictionary = {
	8: "Rusty Plate", 7: "Iron Plate", 6: "Steel Plate",
	5: "Tempered Plate", 4: "War Plate", 3: "Champion Plate",
	2: "Valiant Plate", 1: "Sovereign Plate",
}

const TIER_STATS: Dictionary = {
	8: {"armor": 5}, 7: {"armor": 10}, 6: {"armor": 18},
	5: {"armor": 28}, 4: {"armor": 40}, 3: {"armor": 55},
	2: {"armor": 72}, 1: {"armor": 92},
}


func get_item_type_string() -> String:
	return "IronPlate"


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
	self.computed_armor = 0
	self.computed_evasion = 0
	self.computed_energy_shield = 0
	self.computed_health = 0
	self.implicit = null
	self.update_value()
