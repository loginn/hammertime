class_name TackHammer extends Currency


func _init() -> void:
	currency_name = "Tack Hammer"


## Returns true if item is Magic rarity AND has room for at least one more mod.
func can_apply(item: Item) -> bool:
	if item.rarity != Item.Rarity.MAGIC:
		return false
	return item.prefixes.size() < item.max_prefixes() or item.suffixes.size() < item.max_suffixes()


## Returns human-readable error message explaining why currency cannot be used.
func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.MAGIC:
		return "Tack Hammer can only be used on Magic items"
	if item.prefixes.size() >= item.max_prefixes() and item.suffixes.size() >= item.max_suffixes():
		return "Item already has maximum mods for Magic rarity"
	return ""


## Adds one random mod to the item.
## Chooses randomly between prefix/suffix, with fallback if one type is full.
func _do_apply(item: Item) -> void:
	var prefix_available = item.prefixes.size() < item.max_prefixes()
	var suffix_available = item.suffixes.size() < item.max_suffixes()

	# Choose randomly if both available
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
