class_name GrandHammer extends Currency
## Regal: Magic → Rare (adds 1+ random affix in the upgrade)


func _init() -> void:
	currency_name = "Grand Hammer"
	verb = "Regal"


func can_apply(item: CraftableItem) -> bool:
	return item.rarity == CraftableItem.Rarity.MAGIC


func get_error_message(item: CraftableItem) -> String:
	if item.rarity != CraftableItem.Rarity.MAGIC:
		return "Grand Hammer can only be used on Magic items"
	return ""


func _do_apply(item: CraftableItem) -> void:
	item.rarity = CraftableItem.Rarity.RARE
	var added := false
	var choose_prefix = randi_range(0, 1) == 0
	if choose_prefix:
		added = item.add_prefix() or item.add_suffix()
	else:
		added = item.add_suffix() or item.add_prefix()
	if not added:
		item.rarity = CraftableItem.Rarity.MAGIC
	item.update_value()
