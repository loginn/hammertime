class_name IronBand extends Ring

const TIER_NAMES: Dictionary = {
	8: "Crude Band", 7: "Iron Band", 6: "Steel Band",
	5: "Tempered Band", 4: "War Band", 3: "Champion Band",
	2: "Valiant Band", 1: "Sovereign Band",
}

const TIER_STATS: Dictionary = {
	8: {"base_damage": 3, "imp_min": 2, "imp_max": 5},
	7: {"base_damage": 5, "imp_min": 4, "imp_max": 10},
	6: {"base_damage": 8, "imp_min": 6, "imp_max": 15},
	5: {"base_damage": 12, "imp_min": 8, "imp_max": 20},
	4: {"base_damage": 17, "imp_min": 10, "imp_max": 25},
	3: {"base_damage": 23, "imp_min": 12, "imp_max": 30},
	2: {"base_damage": 30, "imp_min": 14, "imp_max": 35},
	1: {"base_damage": 38, "imp_min": 16, "imp_max": 40},
}


func get_item_type_string() -> String:
	return "IronBand"


func _init(p_tier: int = 8) -> void:
	self.rarity = Rarity.NORMAL
	self.tier = p_tier
	self.item_name = TIER_NAMES[p_tier]
	self.valid_tags = [Tag.STR, Tag.ATTACK, Tag.CRITICAL, Tag.SPEED, Tag.WEAPON]
	var s = TIER_STATS[p_tier]
	self.base_damage = s["base_damage"]
	self.base_damage_type = Tag.PHYSICAL
	self.base_speed = 1
	self.crit_chance = 5.0
	self.crit_damage = 150.0
	self.implicit = Implicit.new(
		"Attack Damage", Affix.AffixType.IMPLICIT,
		s["imp_min"], s["imp_max"],
		[Tag.PHYSICAL, Tag.ATTACK], [Tag.StatType.FLAT_DAMAGE]
	)
	self.update_value()
