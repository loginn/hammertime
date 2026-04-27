class_name TotemAffixes extends Node

# Expedition-modifying affix pool for TotemPiece crafting.
# Each affix carries exactly one deity tag enabling synergy builds.
# Tier range 1–8 shared for both ASH (5-8) and OAK (1-4) gating.
# stat_types is empty — values are read via get_expedition_modifiers() by tag.

var prefixes: Array[Affix] = [
	# Cthulhu — drop quantity (flat bonus rolls)
	Affix.new(
		"Dreaming One's Bounty",
		Affix.AffixType.PREFIX,
		1, 3,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUANTITY, Tag.CTHULHU],
		[],
		Vector2i(1, 8)
	),
	# Nyarlathotep — drop quality (% chance to upgrade tier on drop)
	Affix.new(
		"Crawling Chaos's Gift",
		Affix.AffixType.PREFIX,
		2, 8,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUALITY, Tag.NYARLATHOTEP],
		[],
		Vector2i(1, 8)
	),
	# Hastur — expedition duration reduction (%)
	Affix.new(
		"King's Haste",
		Affix.AffixType.PREFIX,
		3, 10,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DURATION, Tag.HASTUR],
		[],
		Vector2i(1, 8)
	),
	# Dagon — hammer chance bonus (%)
	Affix.new(
		"Deep One's Craft",
		Affix.AffixType.PREFIX,
		2, 6,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.HAMMER_CHANCE, Tag.DAGON],
		[],
		Vector2i(1, 8)
	),
	# Yog-Sothoth — second drop quantity (flat, shares deity with Cthulhu-adjacent)
	Affix.new(
		"Gate of Worlds' Yield",
		Affix.AffixType.PREFIX,
		1, 2,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUANTITY, Tag.YOG_SOTHOTH],
		[],
		Vector2i(1, 8)
	),
	# Shub-Niggurath — material chance bonus (%)
	Affix.new(
		"Black Goat's Abundance",
		Affix.AffixType.PREFIX,
		3, 10,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.MATERIAL_CHANCE, Tag.SHUB_NIGGURATH],
		[],
		Vector2i(1, 8)
	),
]

var suffixes: Array[Affix] = [
	# Dagon — steel chance bonus (%)
	Affix.new(
		"of the Depths",
		Affix.AffixType.SUFFIX,
		2, 8,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.MATERIAL_CHANCE, Tag.DAGON],
		[],
		Vector2i(1, 8)
	),
	# Shub-Niggurath — wood chance bonus (%)
	Affix.new(
		"of the Black Wood",
		Affix.AffixType.SUFFIX,
		2, 8,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.MATERIAL_CHANCE, Tag.SHUB_NIGGURATH],
		[],
		Vector2i(1, 8)
	),
	# Nyarlathotep — bonus drop roll (%)
	Affix.new(
		"of Endless Masks",
		Affix.AffixType.SUFFIX,
		3, 10,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUALITY, Tag.NYARLATHOTEP],
		[],
		Vector2i(1, 8)
	),
	# Hastur — additional expedition duration reduction (%)
	Affix.new(
		"of Yellow Signs",
		Affix.AffixType.SUFFIX,
		2, 6,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DURATION, Tag.HASTUR],
		[],
		Vector2i(1, 8)
	),
	# Cthulhu — bonus drop roll (flat)
	Affix.new(
		"of Sunken Dreams",
		Affix.AffixType.SUFFIX,
		1, 2,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUANTITY, Tag.CTHULHU],
		[],
		Vector2i(1, 8)
	),
	# Yog-Sothoth — hammer chance bonus (%)
	Affix.new(
		"of Outer Gates",
		Affix.AffixType.SUFFIX,
		2, 7,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.HAMMER_CHANCE, Tag.YOG_SOTHOTH],
		[],
		Vector2i(1, 8)
	),
]
