class_name LeatherVest extends Armor

const TIER_NAMES: Dictionary = {
	8: "Tattered Vest", 7: "Hide Vest", 6: "Studded Vest",
	5: "Hardened Vest", 4: "Shadow Vest", 3: "Phantom Vest",
	2: "Nightstalker Vest", 1: "Eclipse Vest",
}

const TIER_STATS: Dictionary = {
	8: {"evasion": 5}, 7: {"evasion": 10}, 6: {"evasion": 18},
	5: {"evasion": 28}, 4: {"evasion": 40}, 3: {"evasion": 55},
	2: {"evasion": 72}, 1: {"evasion": 92},
}


func get_item_type_string() -> String:
	return "LeatherVest"


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
	self.computed_armor = 0
	self.computed_evasion = 0
	self.computed_energy_shield = 0
	self.computed_health = 0
	self.implicit = null
	self.update_value()
