class_name TackHammer extends Currency
## Transmute: Normal → Magic (1-2 random affixes)


func _init() -> void:
	currency_name = "Tack Hammer"
	verb = "Transmute"


func can_apply(item: CraftableItem) -> bool:
	return item.rarity == CraftableItem.Rarity.NORMAL


func get_error_message(item: CraftableItem) -> String:
	if item.rarity != CraftableItem.Rarity.NORMAL:
		return "Tack Hammer can only be used on Normal items"
	return ""


func _do_apply(item: CraftableItem) -> void:
	item.rarity = CraftableItem.Rarity.MAGIC
	var mod_count = 1 if randf() < 0.7 else 2
	var added := 0
	for i in range(mod_count):
		var choose_prefix = randi_range(0, 1) == 0
		if choose_prefix:
			if item.add_prefix():
				added += 1
			elif item.add_suffix():
				added += 1
		else:
			if item.add_suffix():
				added += 1
			elif item.add_prefix():
				added += 1
	if added == 0:
		item.rarity = CraftableItem.Rarity.NORMAL
	item.update_value()
