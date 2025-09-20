class_name Affixes extends Node

var prefixes: Array[Affix] = [
	Affix.new("Physical Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.PHYSICAL, Tag.FLAT]),
	Affix.new("Elemental Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL]),
	Affix.new("Lightning Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.LIGHTNING]),
	Affix.new("Fire Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.FIRE]),
	Affix.new("Cold Damage", Affix.AffixType.PREFIX, 2, 10, [Tag.ELEMENTAL, Tag.COLD]),
]
var suffixes: Array[Affix] = [
	Affix.new("Attack Speed", Affix.AffixType.SUFFIX, 2, 10, [Tag.ATTACK, Tag.SPEED]),
	Affix.new("Cast Speed", Affix.AffixType.SUFFIX, 2, 10, [Tag.MAGIC, Tag.SPEED]),
	Affix.new("Damage over time", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT]),
	Affix.new("Bleed Damage", Affix.AffixType.SUFFIX, 2, 10, [Tag.DOT, Tag.PHYSICAL]),
	Affix.new("Life", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE]),
	Affix.new("Sigil", Affix.AffixType.SUFFIX, 2, 10, [Tag.DEFENSE, Tag.MAGIC]),
]

static func from_affix(template: Affix) -> Affix:
	var affix_copy = Affix.new(template.affix_name, template.type, template.min_value, template.max_value, template.tags)
	return affix_copy
