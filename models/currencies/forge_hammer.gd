class_name ForgeHammer extends Currency


func _init() -> void:
	currency_name = "Forge Hammer"


func can_apply(item: Item) -> bool:
	return item.rarity == Item.Rarity.NORMAL


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.NORMAL:
		return "Forge Hammer can only be used on Normal items"
	return ""


func _do_apply(item: Item) -> void:
	# Set rarity to RARE before adding mods (required for affix limit enforcement)
	item.rarity = Item.Rarity.RARE

	# Add 4-6 random mods total
	var mod_count = randi_range(4, 6)
	for i in range(mod_count):
		# Randomly choose prefix or suffix (50/50)
		var choose_prefix = randi_range(0, 1) == 0

		if choose_prefix:
			# Try prefix first, if it fails try suffix
			if not item.add_prefix():
				# If suffix also fails, stop (pool exhausted)
				if not item.add_suffix():
					break
		else:
			# Try suffix first, if it fails try prefix
			if not item.add_suffix():
				# If prefix also fails, stop (pool exhausted)
				if not item.add_prefix():
					break

	# Update item value after all mods added
	item.update_value()
