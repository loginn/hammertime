class_name Circlet extends Helmet

const TIER_NAMES: Dictionary = {
	8: "Copper Circlet", 7: "Tin Circlet", 6: "Silver Circlet",
	5: "Gilt Circlet", 4: "Mystic Circlet", 3: "Arcane Circlet",
	2: "Imbued Circlet", 1: "Sovereign Circlet",
}

const TIER_STATS: Dictionary = {
	8: {"energy_shield": 5}, 7: {"energy_shield": 9}, 6: {"energy_shield": 15},
	5: {"energy_shield": 24}, 4: {"energy_shield": 34}, 3: {"energy_shield": 46},
	2: {"energy_shield": 60}, 1: {"energy_shield": 77},
}


func get_item_type_string() -> String:
	return "Circlet"


func _init(p_tier: int = 8) -> void:
	self.rarity = Rarity.NORMAL
	self.tier = p_tier
	self.item_name = TIER_NAMES[p_tier]
	self.valid_tags = [Tag.INT, Tag.DEFENSE, Tag.ENERGY_SHIELD]
	var s = TIER_STATS[p_tier]
	self.base_armor = 0
	self.base_evasion = 0
	self.base_energy_shield = s["energy_shield"]
	self.base_health = 0
	self.base_mana = 0
	self.computed_armor = 0
	self.computed_evasion = 0
	self.computed_energy_shield = 0
	self.computed_health = 0
	self.computed_mana = 0
	self.implicit = null
	self.update_value()
