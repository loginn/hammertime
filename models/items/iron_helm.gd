class_name IronHelm extends Helmet

const TIER_NAMES: Dictionary = {
	8: "Rusty Helm", 7: "Iron Helm", 6: "Steel Helm",
	5: "Tempered Helm", 4: "War Helm", 3: "Champion Helm",
	2: "Valiant Helm", 1: "Sovereign Helm",
}

const TIER_STATS: Dictionary = {
	8: {"armor": 3}, 7: {"armor": 6}, 6: {"armor": 11},
	5: {"armor": 17}, 4: {"armor": 24}, 3: {"armor": 33},
	2: {"armor": 43}, 1: {"armor": 55},
}


func get_item_type_string() -> String:
	return "IronHelm"


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
	self.base_mana = 0
	self.computed_armor = 0
	self.computed_evasion = 0
	self.computed_energy_shield = 0
	self.computed_health = 0
	self.computed_mana = 0
	self.implicit = null
	self.update_value()
