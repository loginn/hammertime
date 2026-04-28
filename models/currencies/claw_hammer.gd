class_name ClawHammer extends Currency
## Annul: Remove one random explicit affix (prefix or suffix)


func _init() -> void:
	currency_name = "Claw Hammer"
	verb = "Annul"


func can_apply(item: CraftableItem) -> bool:
	return item.prefixes.size() > 0 or item.suffixes.size() > 0


func get_error_message(item: CraftableItem) -> String:
	if item.prefixes.size() == 0 and item.suffixes.size() == 0:
		return "Item has no mods to remove"
	return ""


func _do_apply(item: CraftableItem) -> void:
	var all_mods: Array[Dictionary] = []
	for i in range(item.prefixes.size()):
		all_mods.append({"type": "prefix", "index": i})
	for i in range(item.suffixes.size()):
		all_mods.append({"type": "suffix", "index": i})

	if all_mods.size() > 0:
		var selected = all_mods.pick_random()
		if selected["type"] == "prefix":
			item.prefixes.remove_at(selected["index"])
		else:
			item.suffixes.remove_at(selected["index"])

	item.update_value()
