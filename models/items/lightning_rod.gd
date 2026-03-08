class_name LightningRod extends Weapon

const TIER_NAMES: Dictionary = {
	8: "Copper Rod", 7: "Bronze Rod", 6: "Iron Rod",
	5: "Charged Rod", 4: "Storm Rod", 3: "Thunder Rod",
	2: "Tempest Rod", 1: "Lightning Rod",
}

const TIER_STATS: Dictionary = {
	8: {"dmg_min": 3, "dmg_max": 5, "atk_speed": 0.5, "spell_min": 8, "spell_max": 12, "cast_speed": 1.0, "imp_min": 2, "imp_max": 6},
	7: {"dmg_min": 5, "dmg_max": 7, "atk_speed": 0.5, "spell_min": 12, "spell_max": 20, "cast_speed": 1.0, "imp_min": 4, "imp_max": 12},
	6: {"dmg_min": 7, "dmg_max": 11, "atk_speed": 0.5, "spell_min": 18, "spell_max": 28, "cast_speed": 1.0, "imp_min": 6, "imp_max": 18},
	5: {"dmg_min": 10, "dmg_max": 16, "atk_speed": 0.5, "spell_min": 26, "spell_max": 40, "cast_speed": 1.0, "imp_min": 8, "imp_max": 24},
	4: {"dmg_min": 14, "dmg_max": 22, "atk_speed": 0.5, "spell_min": 36, "spell_max": 54, "cast_speed": 1.0, "imp_min": 10, "imp_max": 30},
	3: {"dmg_min": 19, "dmg_max": 29, "atk_speed": 0.5, "spell_min": 48, "spell_max": 72, "cast_speed": 1.0, "imp_min": 12, "imp_max": 36},
	2: {"dmg_min": 25, "dmg_max": 37, "atk_speed": 0.5, "spell_min": 62, "spell_max": 94, "cast_speed": 1.0, "imp_min": 14, "imp_max": 42},
	1: {"dmg_min": 32, "dmg_max": 48, "atk_speed": 0.5, "spell_min": 80, "spell_max": 120, "cast_speed": 1.0, "imp_min": 16, "imp_max": 48},
}


func get_item_type_string() -> String:
	return "LightningRod"


func _init(p_tier: int = 8) -> void:
	self.rarity = Rarity.NORMAL
	self.tier = p_tier
	self.item_name = TIER_NAMES[p_tier]
	self.valid_tags = [Tag.INT, Tag.SPELL, Tag.ELEMENTAL, Tag.ENERGY_SHIELD, Tag.WEAPON]
	self.base_damage_type = Tag.PHYSICAL
	var s = TIER_STATS[p_tier]
	self.base_damage_min = s["dmg_min"]
	self.base_damage_max = s["dmg_max"]
	self.base_speed = 1
	self.base_attack_speed = s["atk_speed"]
	self.base_spell_damage_min = s["spell_min"]
	self.base_spell_damage_max = s["spell_max"]
	self.base_cast_speed = s["cast_speed"]
	self.implicit = Implicit.new(
		"Lightning Spell Damage", Affix.AffixType.IMPLICIT,
		s["imp_min"], s["imp_max"],
		[Tag.SPELL, Tag.LIGHTNING, Tag.FLAT], [Tag.StatType.FLAT_SPELL_LIGHTNING_DAMAGE]
	)
	self.update_value()
