class_name TackHammer extends Currency


func _init() -> void:
	currency_name = "Alteration Hammer"


## Alteration can only be used on Magic items.
func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.MAGIC


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.MAGIC:
		return "Alteration Hammer can only be used on Magic items"
	return ""


## Rerolls all mods: clears existing prefixes/suffixes, then adds 1-2 new mods.
## Same mod-count distribution as RunicHammer (70% 1 mod, 30% 2 mods).
func _do_apply(item: Item) -> void:
	# Clear existing mods — rarity stays MAGIC
	item.prefixes.clear()
	item.suffixes.clear()

	# Re-add 1-2 mods (same distribution as Transmute/RunicHammer)
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
