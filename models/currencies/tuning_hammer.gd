class_name TuningHammer extends Currency


func _init() -> void:
	currency_name = "Tuning Hammer"


## Returns true if item has at least one explicit mod (prefix or suffix).
func can_apply(item: Item) -> bool:
	return item.prefixes.size() > 0 or item.suffixes.size() > 0


## Returns human-readable error message explaining why currency cannot be used.
func get_error_message(item: Item) -> String:
	if item.prefixes.size() == 0 and item.suffixes.size() == 0:
		return "Item has no mods to reroll"
	return ""


## Rerolls all explicit mod values within their tier ranges.
## Does NOT reroll the implicit - only prefixes and suffixes.
func _do_apply(item: Item) -> void:
	# Reroll all prefixes
	for prefix in item.prefixes:
		prefix.reroll()

	# Reroll all suffixes
	for suffix in item.suffixes:
		suffix.reroll()

	# Do NOT reroll implicit - CRAFT-06 says "rerolls all mod values"
	# where "mods" are explicit prefixes/suffixes, not implicits
	item.update_value()
