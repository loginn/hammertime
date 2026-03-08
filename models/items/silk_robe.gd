class_name SilkRobe extends Armor

const TIER_NAMES: Dictionary = {
	8: "Threadbare Robe", 7: "Linen Robe", 6: "Woven Robe",
	5: "Embroidered Robe", 4: "Mystic Robe", 3: "Arcane Robe",
	2: "Imbued Robe", 1: "Sovereign Robe",
}

const TIER_STATS: Dictionary = {
	8: {"energy_shield": 8}, 7: {"energy_shield": 15}, 6: {"energy_shield": 25},
	5: {"energy_shield": 40}, 4: {"energy_shield": 56}, 3: {"energy_shield": 77},
	2: {"energy_shield": 100}, 1: {"energy_shield": 128},
}


func get_item_type_string() -> String:
	return "SilkRobe"


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
	self.computed_armor = 0
	self.computed_evasion = 0
	self.computed_energy_shield = 0
	self.computed_health = 0
	self.implicit = null
	self.update_value()
