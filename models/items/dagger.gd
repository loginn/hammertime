class_name Dagger extends Weapon

const TIER_NAMES: Dictionary = {
	8: "Rusty Dagger", 7: "Iron Dagger", 6: "Steel Dagger",
	5: "Assassin Dagger", 4: "Shadow Dagger", 3: "Phantom Dagger",
	2: "Nightfall Dagger", 1: "Eclipse Dagger",
}

const TIER_STATS: Dictionary = {
	8: {"dmg_min": 6, "dmg_max": 10, "atk_speed": 2.2, "imp_min": 2, "imp_max": 5},
	7: {"dmg_min": 10, "dmg_max": 15, "atk_speed": 2.2, "imp_min": 4, "imp_max": 10},
	6: {"dmg_min": 15, "dmg_max": 22, "atk_speed": 2.2, "imp_min": 6, "imp_max": 15},
	5: {"dmg_min": 21, "dmg_max": 32, "atk_speed": 2.2, "imp_min": 8, "imp_max": 20},
	4: {"dmg_min": 30, "dmg_max": 45, "atk_speed": 2.2, "imp_min": 10, "imp_max": 25},
	3: {"dmg_min": 40, "dmg_max": 60, "atk_speed": 2.2, "imp_min": 12, "imp_max": 30},
	2: {"dmg_min": 52, "dmg_max": 78, "atk_speed": 2.2, "imp_min": 14, "imp_max": 35},
	1: {"dmg_min": 66, "dmg_max": 100, "atk_speed": 2.2, "imp_min": 16, "imp_max": 40},
}


func get_item_type_string() -> String:
	return "Dagger"


func _init(p_tier: int = 8) -> void:
	self.rarity = Rarity.NORMAL
	self.tier = p_tier
	self.item_name = TIER_NAMES[p_tier]
	self.valid_tags = [Tag.DEX, Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.EVASION, Tag.ELEMENTAL, Tag.WEAPON, Tag.CHAOS]
	self.base_damage_type = Tag.PHYSICAL
	var s = TIER_STATS[p_tier]
	self.base_damage_min = s["dmg_min"]
	self.base_damage_max = s["dmg_max"]
	self.base_speed = 1
	self.base_attack_speed = s["atk_speed"]
	self.implicit = Implicit.new(
		"Crit Chance", Affix.AffixType.IMPLICIT,
		s["imp_min"], s["imp_max"],
		[Tag.CRITICAL, Tag.ATTACK], [Tag.StatType.CRIT_CHANCE]
	)
	self.update_value()
