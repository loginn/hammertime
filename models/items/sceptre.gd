class_name Sceptre extends Weapon

const TIER_NAMES: Dictionary = {
	8: "Wooden Sceptre", 7: "Stone Sceptre", 6: "Iron Sceptre",
	5: "Ember Sceptre", 4: "Flame Sceptre", 3: "Inferno Sceptre",
	2: "Blazing Sceptre", 1: "Cataclysm Sceptre",
}

const TIER_STATS: Dictionary = {
	8: {"dmg_min": 4, "dmg_max": 6, "atk_speed": 0.5, "spell_min": 10, "spell_max": 14, "cast_speed": 0.8, "imp_min": 3, "imp_max": 7},
	7: {"dmg_min": 6, "dmg_max": 8, "atk_speed": 0.5, "spell_min": 16, "spell_max": 24, "cast_speed": 0.8, "imp_min": 5, "imp_max": 14},
	6: {"dmg_min": 8, "dmg_max": 12, "atk_speed": 0.5, "spell_min": 24, "spell_max": 34, "cast_speed": 0.8, "imp_min": 8, "imp_max": 21},
	5: {"dmg_min": 12, "dmg_max": 18, "atk_speed": 0.5, "spell_min": 34, "spell_max": 48, "cast_speed": 0.8, "imp_min": 10, "imp_max": 28},
	4: {"dmg_min": 16, "dmg_max": 24, "atk_speed": 0.5, "spell_min": 46, "spell_max": 66, "cast_speed": 0.8, "imp_min": 12, "imp_max": 35},
	3: {"dmg_min": 22, "dmg_max": 32, "atk_speed": 0.5, "spell_min": 60, "spell_max": 86, "cast_speed": 0.8, "imp_min": 15, "imp_max": 42},
	2: {"dmg_min": 28, "dmg_max": 42, "atk_speed": 0.5, "spell_min": 78, "spell_max": 112, "cast_speed": 0.8, "imp_min": 18, "imp_max": 49},
	1: {"dmg_min": 36, "dmg_max": 54, "atk_speed": 0.5, "spell_min": 100, "spell_max": 144, "cast_speed": 0.8, "imp_min": 20, "imp_max": 56},
}


func get_item_type_string() -> String:
	return "Sceptre"


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
		"Fire Spell Damage", Affix.AffixType.IMPLICIT,
		s["imp_min"], s["imp_max"],
		[Tag.SPELL, Tag.FIRE, Tag.FLAT], [Tag.StatType.FLAT_SPELL_FIRE_DAMAGE]
	)
	self.update_value()
