class_name GrandHammer extends Currency
## Regal: Magic → Rare (adds 1+ random affix in the upgrade)


func _init() -> void:
	currency_name = "Grand Hammer"
	verb = "Regal"


func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.MAGIC


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.MAGIC:
		return "Grand Hammer can only be used on Magic items"
	return ""


func _do_apply(item: Item) -> void:
	item.rarity = Item.Rarity.RARE
	var choose_prefix = randi_range(0, 1) == 0
	if choose_prefix:
		if not item.add_prefix():
			item.add_suffix()
	else:
		if not item.add_suffix():
			item.add_prefix()
	item.update_value()
