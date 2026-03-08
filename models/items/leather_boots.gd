class_name LeatherBoots extends Boots

const TIER_NAMES: Dictionary = {
	8: "Tattered Boots", 7: "Hide Boots", 6: "Studded Boots",
	5: "Hardened Boots", 4: "Shadow Boots", 3: "Phantom Boots",
	2: "Nightstalker Boots", 1: "Eclipse Boots",
}

const TIER_STATS: Dictionary = {
	8: {"evasion": 3}, 7: {"evasion": 5}, 6: {"evasion": 9},
	5: {"evasion": 14}, 4: {"evasion": 20}, 3: {"evasion": 28},
	2: {"evasion": 36}, 1: {"evasion": 46},
}


func get_item_type_string() -> String:
	return "LeatherBoots"


func _init(p_tier: int = 8) -> void:
	self.rarity = Rarity.NORMAL
	self.tier = p_tier
	self.item_name = TIER_NAMES[p_tier]
	self.valid_tags = [Tag.DEX, Tag.DEFENSE, Tag.EVASION]
	var s = TIER_STATS[p_tier]
	self.base_armor = 0
	self.base_evasion = s["evasion"]
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
