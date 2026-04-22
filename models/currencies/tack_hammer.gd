class_name TackHammer extends Currency
## Transmute: Normal → Magic (1-2 random affixes)


func _init() -> void:
	currency_name = "Tack Hammer"
	verb = "Transmute"


func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.NORMAL


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.NORMAL:
		return "Tack Hammer can only be used on Normal items"
	return ""


func _do_apply(item: Item) -> void:
	item.rarity = Item.Rarity.MAGIC
	var mod_count = 1 if randf() < 0.7 else 2
	for i in range(mod_count):
		var choose_prefix = randi_range(0, 1) == 0
		if choose_prefix:
			if not item.add_prefix():
				item.add_suffix()
		else:
			if not item.add_suffix():
				item.add_prefix()
	item.update_value()
