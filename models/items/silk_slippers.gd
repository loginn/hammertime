class_name SilkSlippers extends Boots

const TIER_NAMES: Dictionary = {
	8: "Threadbare Slippers", 7: "Linen Slippers", 6: "Woven Slippers",
	5: "Embroidered Slippers", 4: "Mystic Slippers", 3: "Arcane Slippers",
	2: "Imbued Slippers", 1: "Sovereign Slippers",
}

const TIER_STATS: Dictionary = {
	8: {"energy_shield": 4}, 7: {"energy_shield": 8}, 6: {"energy_shield": 13},
	5: {"energy_shield": 20}, 4: {"energy_shield": 28}, 3: {"energy_shield": 39},
	2: {"energy_shield": 50}, 1: {"energy_shield": 64},
}


func get_item_type_string() -> String:
	return "SilkSlippers"


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
	self.base_movement_speed = 0
	self.computed_armor = 0
	self.computed_evasion = 0
	self.computed_energy_shield = 0
	self.computed_health = 0
	self.computed_movement_speed = 0
	self.implicit = null
	self.update_value()
