class_name Affixes extends Node

var prefixes: Array[Affix] = [
	Affix.new("Physical Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON]),
	Affix.new("%Physical Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.PHYSICAL, Tag.PERCENTAGE, Tag.WEAPON]),
	Affix.new("%Elemental Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.WEAPON]),
	Affix.new("%Cold Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.WEAPON]),
	Affix.new("%Fire Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.WEAPON]),
	Affix.new("%Lightning Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.WEAPON]),
	Affix.new("Lightning Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.LIGHTNING, Tag.WEAPON]),
	Affix.new("Fire Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.FIRE, Tag.WEAPON]),
	Affix.new("Cold Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.COLD, Tag.WEAPON]),
]
var suffixes: Array[Affix] = [
	Affix.new("Attack Speed", Affix.AffixType.SUFFIX, 2, 10, [Tag.SPEED, Tag.ATTACK, Tag.WEAPON]),
	Affix.new("Cast Speed", Affix.AffixType.SUFFIX, 2, 10, [Tag.MAGIC, Tag.WEAPON]),
	Affix.new("Damage over time", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT, Tag.WEAPON]),
	Affix.new("Bleed Damage", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT, Tag.PHYSICAL, Tag.WEAPON]),
	Affix.new("Life", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE]),
	Affix.new("Sigil", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.MAGIC]),
	Affix.new("Evade", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE]),
	Affix.new("Armor", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE]),
	Affix.new("Physical Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE]),
	Affix.new("Magical Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE]),
	Affix.new("Elemental Reduction", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE]),
	Affix.new("Dodge Chance", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE]),
	Affix.new("Dmg Suppression Chance", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE]),
	Affix.new("Critical Strike Chance", Affix.AffixType.SUFFIX, 2, 10, [Tag.CRITICAL]),
	Affix.new("Critical Strike Damage", Affix.AffixType.SUFFIX, 2, 10, [Tag.CRITICAL]),
]

static func from_affix(template: Affix) -> Affix:
	var affix_copy = Affix.new(template.affix_name, template.type, template.min_value, template.max_value, template.tags)
	return affix_copy
