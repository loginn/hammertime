class_name Battleaxe extends Weapon

const TIER_NAMES: Dictionary = {
	8: "Chipped Battleaxe", 7: "Iron Battleaxe", 6: "Steel Battleaxe",
	5: "Tempered Battleaxe", 4: "War Battleaxe", 3: "Champion Battleaxe",
	2: "Valiant Battleaxe", 1: "Sovereign Battleaxe",
}

const TIER_STATS: Dictionary = {
	8: {"dmg_min": 8, "dmg_max": 12, "atk_speed": 1.4, "imp_min": 2, "imp_max": 5},
	7: {"dmg_min": 12, "dmg_max": 18, "atk_speed": 1.4, "imp_min": 4, "imp_max": 10},
	6: {"dmg_min": 18, "dmg_max": 27, "atk_speed": 1.4, "imp_min": 6, "imp_max": 15},
	5: {"dmg_min": 26, "dmg_max": 39, "atk_speed": 1.4, "imp_min": 8, "imp_max": 20},
	4: {"dmg_min": 36, "dmg_max": 54, "atk_speed": 1.4, "imp_min": 10, "imp_max": 25},
	3: {"dmg_min": 48, "dmg_max": 72, "atk_speed": 1.4, "imp_min": 12, "imp_max": 30},
	2: {"dmg_min": 62, "dmg_max": 93, "atk_speed": 1.4, "imp_min": 14, "imp_max": 35},
	1: {"dmg_min": 80, "dmg_max": 120, "atk_speed": 1.4, "imp_min": 16, "imp_max": 40},
}


func get_item_type_string() -> String:
	return "Battleaxe"


func _init(p_tier: int = 8) -> void:
	self.rarity = Rarity.NORMAL
	self.tier = p_tier
	self.item_name = TIER_NAMES[p_tier]
	self.valid_tags = [Tag.STR, Tag.PHYSICAL, Tag.ATTACK, Tag.ARMOR, Tag.ELEMENTAL, Tag.WEAPON]
	self.base_damage_type = Tag.PHYSICAL
	var s = TIER_STATS[p_tier]
	self.base_damage_min = s["dmg_min"]
	self.base_damage_max = s["dmg_max"]
	self.base_speed = 1
	self.base_attack_speed = s["atk_speed"]
	self.implicit = Implicit.new(
		"Physical Damage", Affix.AffixType.IMPLICIT,
		s["imp_min"], s["imp_max"],
		[Tag.PHYSICAL, Tag.ATTACK], [Tag.StatType.INCREASED_DAMAGE]
	)
	self.update_value()
