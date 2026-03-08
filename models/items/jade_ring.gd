class_name JadeRing extends Ring

const TIER_NAMES: Dictionary = {
	8: "Dull Jade Ring", 7: "Pale Jade Ring", 6: "Polished Jade Ring",
	5: "Vivid Jade Ring", 4: "Deep Jade Ring", 3: "Royal Jade Ring",
	2: "Imperial Jade Ring", 1: "Sovereign Jade Ring",
}

const TIER_STATS: Dictionary = {
	8: {"base_damage": 3, "imp_min": 1, "imp_max": 2},
	7: {"base_damage": 5, "imp_min": 2, "imp_max": 4},
	6: {"base_damage": 8, "imp_min": 3, "imp_max": 6},
	5: {"base_damage": 12, "imp_min": 4, "imp_max": 8},
	4: {"base_damage": 17, "imp_min": 5, "imp_max": 10},
	3: {"base_damage": 23, "imp_min": 6, "imp_max": 12},
	2: {"base_damage": 30, "imp_min": 7, "imp_max": 14},
	1: {"base_damage": 38, "imp_min": 8, "imp_max": 16},
}


func get_item_type_string() -> String:
	return "JadeRing"


func _init(p_tier: int = 8) -> void:
	self.rarity = Rarity.NORMAL
	self.tier = p_tier
	self.item_name = TIER_NAMES[p_tier]
	self.valid_tags = [Tag.DEX, Tag.ATTACK, Tag.CRITICAL, Tag.SPEED, Tag.WEAPON, Tag.CHAOS]
	var s = TIER_STATS[p_tier]
	self.base_damage = s["base_damage"]
	self.base_damage_type = Tag.PHYSICAL
	self.base_speed = 1
	self.crit_chance = 5.0
	self.crit_damage = 150.0
	self.implicit = Implicit.new(
		"Crit Chance", Affix.AffixType.IMPLICIT,
		s["imp_min"], s["imp_max"],
		[Tag.CRITICAL, Tag.ATTACK], [Tag.StatType.CRIT_CHANCE]
	)
	self.update_value()
