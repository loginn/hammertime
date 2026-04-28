class_name ForgeHammer extends Currency
## Augment: Add one random affix to a Magic item that isn't full


func _init() -> void:
	currency_name = "Forge Hammer"
	verb = "Augment"


func can_apply(item: CraftableItem) -> bool:
	if item.rarity != CraftableItem.Rarity.MAGIC:
		return false
	return item.prefixes.size() < item.max_prefixes() or item.suffixes.size() < item.max_suffixes()


func get_error_message(item: CraftableItem) -> String:
	if item.rarity != CraftableItem.Rarity.MAGIC:
		return "Forge Hammer can only be used on Magic items"
	if item.prefixes.size() >= item.max_prefixes() and item.suffixes.size() >= item.max_suffixes():
		return "Item already has maximum mods for Magic rarity"
	return ""


func _do_apply(item: CraftableItem) -> void:
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
