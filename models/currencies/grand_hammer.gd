class_name GrandHammer extends Currency


func _init() -> void:
	currency_name = "Regal Hammer"


## Regal can only be used on Magic items.
func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.MAGIC


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.MAGIC:
		return "Regal Hammer can only be used on Magic items"
	return ""


## Upgrades Magic to Rare by adding exactly one mod.
## Result: existing 1-2 mods + 1 new mod = 2-3 mod Rare item.
func _do_apply(item: Item) -> void:
	item.rarity = Item.Rarity.RARE

	# Add exactly one mod (prefix or suffix, random choice with fallback)
	var choose_prefix = randi_range(0, 1) == 0
	if choose_prefix:
		if not item.add_prefix():
			item.add_suffix()
	else:
		if not item.add_suffix():
			item.add_prefix()

	item.update_value()
