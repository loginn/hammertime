class_name TuningHammer extends Currency
## Alteration: Reroll all affixes on a Magic item (new random affixes, not just new values)


func _init() -> void:
	currency_name = "Tuning Hammer"
	verb = "Alteration"


func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.MAGIC


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.MAGIC:
		return "Tuning Hammer can only be used on Magic items"
	return ""


func _do_apply(item: Item) -> void:
	item.prefixes.clear()
	item.suffixes.clear()
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
		item.rarity = Item.Rarity.NORMAL
	item.update_value()
