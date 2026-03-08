class_name LeatherHood extends Helmet

const TIER_NAMES: Dictionary = {
	8: "Tattered Hood", 7: "Hide Hood", 6: "Studded Hood",
	5: "Hardened Hood", 4: "Shadow Hood", 3: "Phantom Hood",
	2: "Nightstalker Hood", 1: "Eclipse Hood",
}

const TIER_STATS: Dictionary = {
	8: {"evasion": 3}, 7: {"evasion": 6}, 6: {"evasion": 11},
	5: {"evasion": 17}, 4: {"evasion": 24}, 3: {"evasion": 33},
	2: {"evasion": 43}, 1: {"evasion": 55},
}


func get_item_type_string() -> String:
	return "LeatherHood"


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
	self.base_mana = 0
	self.computed_armor = 0
	self.computed_evasion = 0
	self.computed_energy_shield = 0
	self.computed_health = 0
	self.computed_mana = 0
	self.implicit = null
	self.update_value()
