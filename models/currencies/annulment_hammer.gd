class_name AnnulmentHammer extends Currency


func _init() -> void:
	currency_name = "Annulment Hammer"


## Returns true if item has at least one explicit mod (prefix or suffix).
## Works on any rarity (Magic or Rare) that has mods.
func can_apply(item: Item) -> bool:
	return item.prefixes.size() > 0 or item.suffixes.size() > 0


## Returns human-readable error message explaining why currency cannot be used.
func get_error_message(item: Item) -> String:
	if item.prefixes.size() == 0 and item.suffixes.size() == 0:
		return "Item has no mods to remove"
	return ""


## Removes one random explicit mod from the item without changing rarity.
func _do_apply(item: Item) -> void:
	# Build list of all mods with their positions
	var all_mods: Array[Dictionary] = []

	for i in range(item.prefixes.size()):
		all_mods.append({"type": "prefix", "index": i})

	for i in range(item.suffixes.size()):
		all_mods.append({"type": "suffix", "index": i})

	# Pick one at random
	if all_mods.size() > 0:
		var selected = all_mods.pick_random()

		if selected["type"] == "prefix":
			item.prefixes.remove_at(selected["index"])
		else:
			item.suffixes.remove_at(selected["index"])

	# Do NOT change item.rarity - CRAFT-05 explicitly says "without changing rarity"
	item.update_value()
