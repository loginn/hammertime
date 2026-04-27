class_name RunicHammer extends Currency
## Exalt: Add one random affix to a Rare item that isn't full


func _init() -> void:
	currency_name = "Runic Hammer"
	verb = "Exalt"


func can_apply(item: HeroItem) -> bool:
	if item.rarity != CraftableItem.Rarity.RARE:
		return false
	return item.prefixes.size() < item.max_prefixes() or item.suffixes.size() < item.max_suffixes()


func get_error_message(item: HeroItem) -> String:
	if item.rarity != CraftableItem.Rarity.RARE:
		return "Runic Hammer can only be used on Rare items"
	if item.prefixes.size() >= item.max_prefixes() and item.suffixes.size() >= item.max_suffixes():
		return "Item already has maximum mods for Rare rarity"
	return ""


func _do_apply(item: HeroItem) -> void:
	var prefix_available = item.prefixes.size() < item.max_prefixes()
	var suffix_available = item.suffixes.size() < item.max_suffixes()
	var try_prefix_first = randi_range(0, 1) == 0

	if prefix_available and suffix_available:
		if try_prefix_first:
			if not item.add_prefix():
				item.add_suffix()
		else:
			if not item.add_suffix():
				item.add_prefix()
	elif prefix_available:
		item.add_prefix()
	elif suffix_available:
		item.add_suffix()

	item.update_value()
