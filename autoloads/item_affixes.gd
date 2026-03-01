class_name Affixes extends Node

var prefixes: Array[Affix] = [
	# Physical Damage — tight 1:1.5 ratio
	Affix.new(
		"Physical Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON],
		[Tag.StatType.FLAT_DAMAGE],
		Vector2i(1, 32),
		3, 5, 7, 10  # dmg_min_lo=3, dmg_min_hi=5, dmg_max_lo=7, dmg_max_hi=10
	),
	Affix.new(
		"%Physical Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.PHYSICAL, Tag.PERCENTAGE, Tag.WEAPON],
		[Tag.StatType.INCREASED_DAMAGE],
		Vector2i(1, 32)
	),
	Affix.new(
		"%Elemental Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.ELEMENTAL, Tag.WEAPON],
		[Tag.StatType.INCREASED_DAMAGE],
		Vector2i(1, 32)
	),
	Affix.new(
		"%Cold Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.ELEMENTAL, Tag.WEAPON],
		[Tag.StatType.INCREASED_DAMAGE],
		Vector2i(1, 32)
	),
	Affix.new(
		"%Fire Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.ELEMENTAL, Tag.WEAPON],
		[Tag.StatType.INCREASED_DAMAGE],
		Vector2i(1, 32)
	),
	Affix.new(
		"%Lightning Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.ELEMENTAL, Tag.WEAPON],
		[Tag.StatType.INCREASED_DAMAGE],
		Vector2i(1, 32)
	),
	# Lightning Damage — extreme 1:4 ratio (widest spread)
	Affix.new(
		"Lightning Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.ELEMENTAL, Tag.LIGHTNING, Tag.WEAPON],
		[Tag.StatType.FLAT_DAMAGE],
		Vector2i(1, 32),
		1, 3, 8, 16  # dmg_min_lo=1, dmg_min_hi=3, dmg_max_lo=8, dmg_max_hi=16
	),
	# Fire Damage — wide 1:2.5 ratio
	Affix.new(
		"Fire Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.ELEMENTAL, Tag.FIRE, Tag.WEAPON],
		[Tag.StatType.FLAT_DAMAGE],
		Vector2i(1, 32),
		2, 4, 8, 14  # dmg_min_lo=2, dmg_min_hi=4, dmg_max_lo=8, dmg_max_hi=14
	),
	# Cold Damage — moderate 1:2 ratio
	Affix.new(
		"Cold Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.ELEMENTAL, Tag.COLD, Tag.WEAPON],
		[Tag.StatType.FLAT_DAMAGE],
		Vector2i(1, 32),
		2, 5, 7, 12  # dmg_min_lo=2, dmg_min_hi=5, dmg_max_lo=7, dmg_max_hi=12
	),
	# Defensive prefixes (32-tier range)
	Affix.new(
		"Flat Armor",
		Affix.AffixType.PREFIX,
		2,
		5,
		[Tag.DEFENSE, Tag.ARMOR],
		[Tag.StatType.FLAT_ARMOR],
		Vector2i(1, 32)
	),
	Affix.new(
		"%Armor",
		Affix.AffixType.PREFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.ARMOR],
		[Tag.StatType.PERCENT_ARMOR],
		Vector2i(1, 32)
	),
	Affix.new(
		"Evasion",
		Affix.AffixType.PREFIX,
		2,
		5,
		[Tag.DEFENSE, Tag.EVASION],
		[Tag.StatType.FLAT_EVASION],
		Vector2i(1, 32)
	),
	Affix.new(
		"%Evasion",
		Affix.AffixType.PREFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.EVASION],
		[Tag.StatType.PERCENT_EVASION],
		Vector2i(1, 32)
	),
	Affix.new(
		"Energy Shield",
		Affix.AffixType.PREFIX,
		3,
		6,
		[Tag.DEFENSE, Tag.ENERGY_SHIELD],
		[Tag.StatType.FLAT_ENERGY_SHIELD],
		Vector2i(1, 32)
	),
	Affix.new(
		"%Energy Shield",
		Affix.AffixType.PREFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.ENERGY_SHIELD],
		[Tag.StatType.PERCENT_ENERGY_SHIELD],
		Vector2i(1, 32)
	),
	# Utility prefixes (32-tier range)
	Affix.new(
		"Health",
		Affix.AffixType.PREFIX,
		3,
		8,
		[Tag.DEFENSE, Tag.UTILITY],
		[Tag.StatType.FLAT_HEALTH],
		Vector2i(1, 32)
	),
	Affix.new(
		"%Health",
		Affix.AffixType.PREFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.UTILITY],
		[Tag.StatType.PERCENT_HEALTH],
		Vector2i(1, 32)
	),
	Affix.new(
		"Mana",
		Affix.AffixType.PREFIX,
		2,
		6,
		[Tag.DEFENSE, Tag.MANA, Tag.UTILITY],
		[Tag.StatType.FLAT_MANA],
		Vector2i(1, 32)
	),
]
var suffixes: Array[Affix] = [
	Affix.new(
		"Attack Speed",
		Affix.AffixType.SUFFIX,
		2,
		10,
		[Tag.SPEED, Tag.ATTACK, Tag.WEAPON],
		[Tag.StatType.INCREASED_SPEED],
		Vector2i(1, 32)
	),
	Affix.new("Life", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], [Tag.StatType.FLAT_HEALTH], Vector2i(1, 32)),
	Affix.new("Armor", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], [Tag.StatType.FLAT_ARMOR], Vector2i(1, 32)),
	Affix.new(
		"Fire Resistance",
		Affix.AffixType.SUFFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.WEAPON],
		[Tag.StatType.FIRE_RESISTANCE],
		Vector2i(1, 32)
	),
	Affix.new(
		"Cold Resistance",
		Affix.AffixType.SUFFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.WEAPON],
		[Tag.StatType.COLD_RESISTANCE],
		Vector2i(1, 32)
	),
	Affix.new(
		"Lightning Resistance",
		Affix.AffixType.SUFFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.WEAPON],
		[Tag.StatType.LIGHTNING_RESISTANCE],
		Vector2i(1, 32)
	),
	Affix.new(
		"All Resistances",
		Affix.AffixType.SUFFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.WEAPON],
		[Tag.StatType.ALL_RESISTANCE],
		Vector2i(1, 32)
	),
	Affix.new(
		"Critical Strike Chance",
		Affix.AffixType.SUFFIX,
		2,
		10,
		[Tag.CRITICAL],
		[Tag.StatType.CRIT_CHANCE],
		Vector2i(1, 32)
	),
	Affix.new(
		"Critical Strike Damage",
		Affix.AffixType.SUFFIX,
		2,
		10,
		[Tag.CRITICAL],
		[Tag.StatType.CRIT_DAMAGE],
		Vector2i(1, 32)
	),
	# DISABLED: These suffixes have no stat_type implementation yet.
	# Re-enable when the corresponding mechanics (DoT, cast speed, dodge, suppression,
	# evasion from suffix, physical/magical reduction, sigil) are added to Tag.StatType
	# and hero.gd stat aggregation.
	#Affix.new("Cast Speed", Affix.AffixType.SUFFIX, 2, 10, [Tag.MAGIC], []),
	#Affix.new("Damage over time", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT, Tag.WEAPON], []),
	#Affix.new("Bleed Damage", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT, Tag.PHYSICAL, Tag.WEAPON], []),
	#Affix.new("Sigil", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.MAGIC], []),
	#Affix.new("Evade", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
	#Affix.new("Physical Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
	#Affix.new("Magical Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
	#Affix.new("Dodge Chance", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
	#Affix.new("Dmg Suppression Chance", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.WEAPON], []),
]


static func from_affix(template: Affix, affix_tier_floor: int = 1) -> Affix:
	var effective_range := Vector2i(
		maxi(template.tier_range.x, affix_tier_floor),
		template.tier_range.y
	)
	var affix_copy = Affix.new(
		template.affix_name,
		template.type,
		template.base_min,
		template.base_max,
		template.tags,
		template.stat_types,
		effective_range,
		template.base_dmg_min_lo,
		template.base_dmg_min_hi,
		template.base_dmg_max_lo,
		template.base_dmg_max_hi
	)
	return affix_copy
