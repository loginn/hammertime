class_name RunicHammer extends Currency


func _init() -> void:
	currency_name = "Runic Hammer"


func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.NORMAL


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.NORMAL:
		return "Runic Hammer can only be used on Normal items"
	return ""


func _do_apply(item: Item) -> void:
	# Set rarity to MAGIC before adding mods (required for affix limit enforcement)
	item.rarity = Item.Rarity.MAGIC

	# Add 1-2 random mods total (70% chance of 1 mod, 30% chance of 2 mods)
	var mod_count = 1 if randf() < 0.7 else 2
	for i in range(mod_count):
		# Randomly choose prefix or suffix (50/50)
		var choose_prefix = randi_range(0, 1) == 0

		if choose_prefix:
			# Try prefix first, if it fails try suffix
			if not item.add_prefix():
				item.add_suffix()
		else:
			# Try suffix first, if it fails try prefix
			if not item.add_suffix():
				item.add_prefix()

	# Update item value after all mods added
	item.update_value()
