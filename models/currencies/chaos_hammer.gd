class_name ChaosHammer extends Currency


func _init() -> void:
	currency_name = "Chaos Hammer"


## Chaos rerolls all explicit mods on a Rare item. Works on empty Rares too.
func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.RARE


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.RARE:
		return "Chaos Hammer can only be used on Rare items"
	return ""


## Clears existing prefixes/suffixes and rolls 4-6 new random mods.
## Rarity is already RARE (gated by can_apply); does not change.
func _do_apply(item: Item) -> void:
	item.prefixes.clear()
	item.suffixes.clear()

	var mod_count = randi_range(4, 6)
	for i in range(mod_count):
		var choose_prefix = randi_range(0, 1) == 0
		if choose_prefix:
			if not item.add_prefix():
				if not item.add_suffix():
					break
		else:
			if not item.add_suffix():
				if not item.add_prefix():
					break

	item.update_value()
