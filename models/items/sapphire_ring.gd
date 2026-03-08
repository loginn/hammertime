class_name SapphireRing extends Ring

const TIER_NAMES: Dictionary = {
	8: "Clouded Sapphire Ring", 7: "Dim Sapphire Ring", 6: "Clear Sapphire Ring",
	5: "Bright Sapphire Ring", 4: "Lustrous Sapphire Ring", 3: "Radiant Sapphire Ring",
	2: "Brilliant Sapphire Ring", 1: "Sovereign Sapphire Ring",
}

const TIER_STATS: Dictionary = {
	8: {"base_damage": 3, "imp_min": 1, "imp_max": 3, "base_cast_speed": 0.5},
	7: {"base_damage": 5, "imp_min": 2, "imp_max": 6, "base_cast_speed": 0.6},
	6: {"base_damage": 8, "imp_min": 3, "imp_max": 9, "base_cast_speed": 0.7},
	5: {"base_damage": 12, "imp_min": 4, "imp_max": 12, "base_cast_speed": 0.8},
	4: {"base_damage": 17, "imp_min": 5, "imp_max": 15, "base_cast_speed": 0.9},
	3: {"base_damage": 23, "imp_min": 6, "imp_max": 18, "base_cast_speed": 1.0},
	2: {"base_damage": 30, "imp_min": 7, "imp_max": 21, "base_cast_speed": 1.1},
	1: {"base_damage": 38, "imp_min": 8, "imp_max": 24, "base_cast_speed": 1.2},
}


func get_item_type_string() -> String:
	return "SapphireRing"


func _init(p_tier: int = 8) -> void:
	self.rarity = Rarity.NORMAL
	self.tier = p_tier
	self.item_name = TIER_NAMES[p_tier]
	self.valid_tags = [Tag.INT, Tag.SPELL, Tag.SPEED, Tag.WEAPON]
	var s = TIER_STATS[p_tier]
	self.base_damage = s["base_damage"]
	self.base_damage_type = Tag.PHYSICAL
	self.base_speed = 1
	self.base_cast_speed = s["base_cast_speed"]
	self.crit_chance = 5.0
	self.crit_damage = 150.0
	self.implicit = Implicit.new(
		"Spell Damage", Affix.AffixType.IMPLICIT,
		s["imp_min"], s["imp_max"],
		[Tag.SPELL, Tag.MAGIC], [Tag.StatType.FLAT_SPELL_DAMAGE]
	)
	self.update_value()
