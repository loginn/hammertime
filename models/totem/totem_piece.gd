class_name TotemPiece extends CraftableItem

# The deity whose tag appears most among rolled affixes (first affix's deity on tie).
var deity_tag: String = ""


func _get_prefix_pool() -> Array[Affix]:
	return TotemAffixes.prefixes


func _get_suffix_pool() -> Array[Affix]:
	return TotemAffixes.suffixes


## Recompute deity_tag from the current rolled affixes.
## Call after any add_prefix()/add_suffix() to keep the field current.
func recompute_deity_tag() -> void:
	var counts: Dictionary = {}
	var first_deity: String = ""
	for affix in prefixes + suffixes:
		for tag: String in affix.tags:
			if tag in [Tag.CTHULHU, Tag.NYARLATHOTEP, Tag.HASTUR,
					Tag.DAGON, Tag.YOG_SOTHOTH, Tag.SHUB_NIGGURATH]:
				if first_deity.is_empty():
					first_deity = tag
				counts[tag] = counts.get(tag, 0) + 1

	if counts.is_empty():
		deity_tag = ""
		return

	var best_tag: String = first_deity
	var best_count: int = 0
	for tag: String in counts:
		if counts[tag] > best_count:
			best_count = counts[tag]
			best_tag = tag

	deity_tag = best_tag


## Aggregate all rolled affix values into an expedition modifier dictionary.
## Keys: drop_quantity (flat int), drop_quality (% int), duration_reduction (% int),
##       hammer_chance (% int), steel_chance (% int), wood_chance (% int),
##       bonus_roll_chance (% int).
func get_expedition_modifiers() -> Dictionary:
	var mods: Dictionary = {
		"drop_quantity": 0,
		"drop_quality": 0,
		"duration_reduction": 0,
		"hammer_chance": 0,
		"steel_chance": 0,
		"wood_chance": 0,
		"bonus_roll_chance": 0,
	}

	for affix in prefixes + suffixes:
		var is_steel := Tag.DAGON in affix.tags and Tag.MATERIAL_CHANCE in affix.tags \
				and affix.type == Affix.AffixType.SUFFIX
		var is_wood := Tag.SHUB_NIGGURATH in affix.tags and Tag.MATERIAL_CHANCE in affix.tags \
				and affix.type == Affix.AffixType.SUFFIX

		if Tag.DROP_QUANTITY in affix.tags:
			mods["drop_quantity"] += affix.value
		elif Tag.DROP_QUALITY in affix.tags and affix.type == Affix.AffixType.PREFIX:
			mods["drop_quality"] += affix.value
		elif Tag.DROP_QUALITY in affix.tags and affix.type == Affix.AffixType.SUFFIX:
			mods["bonus_roll_chance"] += affix.value
		elif Tag.DURATION in affix.tags:
			mods["duration_reduction"] += affix.value
		elif Tag.HAMMER_CHANCE in affix.tags:
			mods["hammer_chance"] += affix.value
		elif is_steel:
			mods["steel_chance"] += affix.value
		elif is_wood:
			mods["wood_chance"] += affix.value
		elif Tag.MATERIAL_CHANCE in affix.tags:
			# Generic material chance split between steel and wood
			mods["steel_chance"] += affix.value / 2
			mods["wood_chance"] += affix.value / 2

	return mods
