class_name TagHammer extends Currency

var required_tag: String


func _init(p_tag: String, p_name: String) -> void:
	required_tag = p_tag
	currency_name = p_name


## Returns true if the item is Normal rarity AND has at least one matching-tag affix available.
func can_apply(item: Item) -> bool:
	if item.rarity != Item.Rarity.NORMAL:
		return false
	return _has_any_matching_affix(item)


## Returns contextual error message for each failure mode.
func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.NORMAL:
		return "%s can only be used on Normal items" % currency_name
	if not _has_any_matching_affix(item):
		return "No %s-tagged mods available for this item" % required_tag.to_lower()
	return ""


## Rolls 4-6 mods (50/50 prefix/suffix pattern), then guarantees at least one tagged affix.
func _do_apply(item: Item) -> void:
	# Set rarity to RARE before adding mods (required for affix limit enforcement)
	item.rarity = Item.Rarity.RARE

	# Add 4-6 random mods total
	var mod_count = randi_range(4, 6)
	for i in range(mod_count):
		# Randomly choose prefix or suffix (50/50)
		var choose_prefix = randi_range(0, 1) == 0

		if choose_prefix:
			# Try prefix first, if it fails try suffix
			if not item.add_prefix():
				# If suffix also fails, stop (pool exhausted)
				if not item.add_suffix():
					break
		else:
			# Try suffix first, if it fails try prefix
			if not item.add_suffix():
				# If prefix also fails, stop (pool exhausted)
				if not item.add_prefix():
					break

	# Guarantee at least one tagged affix
	if not _has_matching_affix_on_item(item):
		_replace_random_affix_with_tagged(item)

	# Update item value after all mods added
	item.update_value()


## Pre-application check: returns true if any affix in the pool matches both item tags and required_tag.
func _has_any_matching_affix(item: Item) -> bool:
	for template: Affix in ItemAffixes.prefixes:
		if item.has_valid_tag(template) and required_tag in template.tags:
			return true
	for template: Affix in ItemAffixes.suffixes:
		if item.has_valid_tag(template) and required_tag in template.tags:
			return true
	return false


## Post-application check: returns true if any affix already on the item has the required tag.
func _has_matching_affix_on_item(item: Item) -> bool:
	for affix: Affix in item.prefixes:
		if required_tag in affix.tags:
			return true
	for affix: Affix in item.suffixes:
		if required_tag in affix.tags:
			return true
	return false


## Replaces one random affix on the item with a tagged affix, preserving prefix/suffix type.
## CRITICAL: prefix victims get prefix replacements, suffix victims get suffix replacements.
## Falls back to cross-type replacement only as last resort.
func _replace_random_affix_with_tagged(item: Item) -> void:
	var floor_val := item._get_affix_tier_floor()

	# Build tagged prefix pool: items that match item tags AND required_tag
	var tagged_prefix_pool: Array[Affix] = []
	for template: Affix in ItemAffixes.prefixes:
		if required_tag in template.tags and item.has_valid_tag(template):
			tagged_prefix_pool.append(template)

	# Build tagged suffix pool: items that match item tags AND required_tag
	var tagged_suffix_pool: Array[Affix] = []
	for template: Affix in ItemAffixes.suffixes:
		if required_tag in template.tags and item.has_valid_tag(template):
			tagged_suffix_pool.append(template)

	# If both pools are empty, can_apply should have prevented reaching this point
	if tagged_prefix_pool.is_empty() and tagged_suffix_pool.is_empty():
		return

	# Try same-type replacement: prefix victim -> prefix replacement
	if not tagged_prefix_pool.is_empty() and not item.prefixes.is_empty():
		var victim_idx: int = randi_range(0, item.prefixes.size() - 1)
		var template: Affix = tagged_prefix_pool.pick_random()
		item.prefixes[victim_idx] = Affixes.from_affix(template, floor_val)
		return

	# Try same-type replacement: suffix victim -> suffix replacement
	if not tagged_suffix_pool.is_empty() and not item.suffixes.is_empty():
		var victim_idx: int = randi_range(0, item.suffixes.size() - 1)
		var template: Affix = tagged_suffix_pool.pick_random()
		item.suffixes[victim_idx] = Affixes.from_affix(template, floor_val)
		return

	# Last resort: cross-type replacement if no same-type victim/replacement pairing available
	# Try prefix pool with any victim (prefix or suffix)
	if not tagged_prefix_pool.is_empty():
		var template: Affix = tagged_prefix_pool.pick_random()
		if not item.prefixes.is_empty():
			var victim_idx: int = randi_range(0, item.prefixes.size() - 1)
			item.prefixes[victim_idx] = Affixes.from_affix(template, floor_val)
		elif not item.suffixes.is_empty():
			var victim_idx: int = randi_range(0, item.suffixes.size() - 1)
			item.suffixes[victim_idx] = Affixes.from_affix(template, floor_val)
		return

	# Try suffix pool with any victim
	if not tagged_suffix_pool.is_empty():
		var template: Affix = tagged_suffix_pool.pick_random()
		if not item.suffixes.is_empty():
			var victim_idx: int = randi_range(0, item.suffixes.size() - 1)
			item.suffixes[victim_idx] = Affixes.from_affix(template, floor_val)
		elif not item.prefixes.is_empty():
			var victim_idx: int = randi_range(0, item.prefixes.size() - 1)
			item.prefixes[victim_idx] = Affixes.from_affix(template, floor_val)
