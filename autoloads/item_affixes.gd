class_name Affixes extends Node

var prefixes: Array[Affix] = [
	Affix.new(
		"Physical Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON],
		[Tag.StatType.FLAT_DAMAGE]
	),
	Affix.new(
		"%Physical Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.PHYSICAL, Tag.PERCENTAGE, Tag.WEAPON],
		[Tag.StatType.INCREASED_DAMAGE]
	),
	Affix.new("%Elemental Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.WEAPON], []),
	Affix.new("%Cold Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.WEAPON], []),
	Affix.new("%Fire Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.WEAPON], []),
	Affix.new("%Lightning Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.WEAPON], []),
	Affix.new(
		"Lightning Damage",
		Affix.AffixType.PREFIX,
		2,
		10,
		[Tag.ELEMENTAL, Tag.LIGHTNING, Tag.WEAPON],
		[]
	),
	Affix.new(
		"Fire Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.FIRE, Tag.WEAPON], []
	),
	Affix.new(
		"Cold Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.COLD, Tag.WEAPON], []
	),
	# Defensive prefixes (30-tier range)
	Affix.new(
		"Flat Armor",
		Affix.AffixType.PREFIX,
		2,
		5,
		[Tag.DEFENSE, Tag.ARMOR],
		[Tag.StatType.FLAT_ARMOR],
		Vector2i(1, 30)
	),
	Affix.new(
		"%Armor",
		Affix.AffixType.PREFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.ARMOR],
		[Tag.StatType.PERCENT_ARMOR],
		Vector2i(1, 30)
	),
	Affix.new(
		"Evasion",
		Affix.AffixType.PREFIX,
		2,
		5,
		[Tag.DEFENSE, Tag.EVASION],
		[Tag.StatType.FLAT_EVASION],
		Vector2i(1, 30)
	),
	Affix.new(
		"%Evasion",
		Affix.AffixType.PREFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.EVASION],
		[Tag.StatType.PERCENT_EVASION],
		Vector2i(1, 30)
	),
	Affix.new(
		"Energy Shield",
		Affix.AffixType.PREFIX,
		3,
		6,
		[Tag.DEFENSE, Tag.ENERGY_SHIELD],
		[Tag.StatType.FLAT_ENERGY_SHIELD],
		Vector2i(1, 30)
	),
	Affix.new(
		"%Energy Shield",
		Affix.AffixType.PREFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.ENERGY_SHIELD],
		[Tag.StatType.PERCENT_ENERGY_SHIELD],
		Vector2i(1, 30)
	),
	# Utility prefixes (30-tier range)
	Affix.new(
		"Health",
		Affix.AffixType.PREFIX,
		3,
		8,
		[Tag.DEFENSE, Tag.UTILITY],
		[Tag.StatType.FLAT_HEALTH],
		Vector2i(1, 30)
	),
	Affix.new(
		"%Health",
		Affix.AffixType.PREFIX,
		1,
		3,
		[Tag.DEFENSE, Tag.UTILITY],
		[Tag.StatType.PERCENT_HEALTH],
		Vector2i(1, 30)
	),
	Affix.new(
		"Mana",
		Affix.AffixType.PREFIX,
		2,
		6,
		[Tag.DEFENSE, Tag.MANA, Tag.UTILITY],
		[Tag.StatType.FLAT_MANA],
		Vector2i(1, 30)
	),
]
var suffixes: Array[Affix] = [
	Affix.new(
		"Attack Speed",
		Affix.AffixType.SUFFIX,
		2,
		10,
		[Tag.SPEED, Tag.ATTACK, Tag.WEAPON],
		[Tag.StatType.INCREASED_SPEED]
	),
	Affix.new("Cast Speed", Affix.AffixType.SUFFIX, 2, 10, [Tag.MAGIC, Tag.WEAPON], []),
	Affix.new("Damage over time", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT, Tag.WEAPON], []),
	Affix.new(
		"Bleed Damage", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT, Tag.PHYSICAL, Tag.WEAPON], []
	),
	Affix.new("Life", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], [Tag.StatType.FLAT_HEALTH]),
	Affix.new("Sigil", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.MAGIC], []),
	Affix.new("Evade", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], []),
	Affix.new("Armor", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], [Tag.StatType.FLAT_ARMOR]),
	Affix.new("Physical Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], []),
	Affix.new("Magical Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], []),
	Affix.new(
		"Fire Resistance",
		Affix.AffixType.SUFFIX,
		5,
		12,
		[Tag.DEFENSE],
		[Tag.StatType.FIRE_RESISTANCE],
		Vector2i(1, 8)
	),
	Affix.new(
		"Cold Resistance",
		Affix.AffixType.SUFFIX,
		5,
		12,
		[Tag.DEFENSE],
		[Tag.StatType.COLD_RESISTANCE],
		Vector2i(1, 8)
	),
	Affix.new(
		"Lightning Resistance",
		Affix.AffixType.SUFFIX,
		5,
		12,
		[Tag.DEFENSE],
		[Tag.StatType.LIGHTNING_RESISTANCE],
		Vector2i(1, 8)
	),
	Affix.new(
		"All Resistances",
		Affix.AffixType.SUFFIX,
		3,
		8,
		[Tag.DEFENSE],
		[Tag.StatType.ALL_RESISTANCE],
		Vector2i(1, 5)
	),
	Affix.new("Dodge Chance", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], []),
	Affix.new("Dmg Suppression Chance", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE], []),
	Affix.new(
		"Critical Strike Chance",
		Affix.AffixType.SUFFIX,
		2,
		10,
		[Tag.CRITICAL],
		[Tag.StatType.CRIT_CHANCE]
	),
	Affix.new(
		"Critical Strike Damage",
		Affix.AffixType.SUFFIX,
		2,
		10,
		[Tag.CRITICAL],
		[Tag.StatType.CRIT_DAMAGE]
	),
]


static func from_affix(template: Affix) -> Affix:
	var affix_copy = Affix.new(
		template.affix_name,
		template.type,
		template.base_min,
		template.base_max,
		template.tags,
		template.stat_types,
		template.tier_range
	)
	return affix_copy
