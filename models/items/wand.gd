class_name Wand extends Weapon

const TIER_NAMES: Dictionary = {
	8: "Twig Wand", 7: "Bone Wand", 6: "Crystal Wand",
	5: "Runed Wand", 4: "Arcane Wand", 3: "Mystic Wand",
	2: "Ethereal Wand", 1: "Void Wand",
}

const TIER_STATS: Dictionary = {
	8: {"dmg_min": 3, "dmg_max": 5, "atk_speed": 0.5, "spell_min": 6, "spell_max": 10, "cast_speed": 1.2, "imp_min": 2, "imp_max": 5},
	7: {"dmg_min": 5, "dmg_max": 7, "atk_speed": 0.5, "spell_min": 10, "spell_max": 16, "cast_speed": 1.2, "imp_min": 4, "imp_max": 10},
	6: {"dmg_min": 7, "dmg_max": 11, "atk_speed": 0.5, "spell_min": 15, "spell_max": 24, "cast_speed": 1.2, "imp_min": 6, "imp_max": 15},
	5: {"dmg_min": 10, "dmg_max": 16, "atk_speed": 0.5, "spell_min": 22, "spell_max": 34, "cast_speed": 1.2, "imp_min": 8, "imp_max": 20},
	4: {"dmg_min": 14, "dmg_max": 22, "atk_speed": 0.5, "spell_min": 30, "spell_max": 46, "cast_speed": 1.2, "imp_min": 10, "imp_max": 25},
	3: {"dmg_min": 19, "dmg_max": 29, "atk_speed": 0.5, "spell_min": 40, "spell_max": 62, "cast_speed": 1.2, "imp_min": 12, "imp_max": 30},
	2: {"dmg_min": 25, "dmg_max": 37, "atk_speed": 0.5, "spell_min": 52, "spell_max": 80, "cast_speed": 1.2, "imp_min": 14, "imp_max": 35},
	1: {"dmg_min": 32, "dmg_max": 48, "atk_speed": 0.5, "spell_min": 66, "spell_max": 100, "cast_speed": 1.2, "imp_min": 16, "imp_max": 40},
}


func get_item_type_string() -> String:
	return "Wand"


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
		"Spell Damage", Affix.AffixType.IMPLICIT,
		s["imp_min"], s["imp_max"],
		[Tag.SPELL, Tag.FLAT], [Tag.StatType.FLAT_SPELL_DAMAGE]
	)
	self.update_value()
