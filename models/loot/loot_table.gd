class_name LootTable extends Resource

# Rarity weight tables per area level
# Higher area levels have higher chance for better rarity items
const RARITY_WEIGHTS: Dictionary = {
	1: { Item.Rarity.NORMAL: 80, Item.Rarity.MAGIC: 18, Item.Rarity.RARE: 2 },
	2: { Item.Rarity.NORMAL: 50, Item.Rarity.MAGIC: 40, Item.Rarity.RARE: 10 },
	3: { Item.Rarity.NORMAL: 20, Item.Rarity.MAGIC: 45, Item.Rarity.RARE: 35 },
	4: { Item.Rarity.NORMAL: 5, Item.Rarity.MAGIC: 30, Item.Rarity.RARE: 65 },
	5: { Item.Rarity.NORMAL: 2, Item.Rarity.MAGIC: 28, Item.Rarity.RARE: 70 },  # For area_level >= 5
}


## Returns the rarity weight distribution for a given area level
static func get_rarity_weights(area_level: int) -> Dictionary:
	# For area levels beyond 4, use level 5's weights
	var lookup_level = min(area_level, 5)
	return RARITY_WEIGHTS[lookup_level]


## Rolls a random rarity based on area level weights
static func roll_rarity(area_level: int) -> Item.Rarity:
	var weights = get_rarity_weights(area_level)

	# Calculate total weight
	var total_weight = 0
	for rarity in weights:
		total_weight += weights[rarity]

	# Generate random roll
	var roll = randi_range(1, total_weight)

	# Walk through weights (NORMAL -> MAGIC -> RARE)
	var accumulated = 0

	# Check NORMAL first
	accumulated += weights[Item.Rarity.NORMAL]
	if roll <= accumulated:
		return Item.Rarity.NORMAL

	# Check MAGIC next
	accumulated += weights[Item.Rarity.MAGIC]
	if roll <= accumulated:
		return Item.Rarity.MAGIC

	# Otherwise RARE
	return Item.Rarity.RARE


## Rolls currency drops for area clear based on area level
## Returns dictionary mapping currency name to drop count
## Currency names: "runic", "forge", "tack", "grand", "claw", "tuning"
static func roll_currency_drops(area_level: int) -> Dictionary:
	var drops: Dictionary = {}

	# Per-currency drop chances and quantities
	# Each currency has independent chance to drop
	var currency_rules = {
		"runic": {"chance": 0.7, "min_qty": 1, "max_qty": 2},
		"forge": {"chance": 0.3, "min_qty": 1, "max_qty": 1},
		"tack": {"chance": 0.5, "min_qty": 1, "max_qty": 2},
		"grand": {"chance": 0.2, "min_qty": 1, "max_qty": 1},
		"claw": {"chance": 0.4, "min_qty": 1, "max_qty": 2},
		"tuning": {"chance": 0.4, "min_qty": 1, "max_qty": 2},
	}

	# Roll each currency
	for currency_name in currency_rules:
		var rule = currency_rules[currency_name]
		if randf() < rule["chance"]:
			var quantity = randi_range(rule["min_qty"], rule["max_qty"])
			drops[currency_name] = quantity

	# Area level bonus: (area_level - 1) bonus drops distributed to currencies that dropped
	var bonus_drops = area_level - 1
	if bonus_drops > 0 and drops.size() > 0:
		var dropped_currencies = drops.keys()
		for i in range(bonus_drops):
			var random_currency = dropped_currencies[randi() % dropped_currencies.size()]
			drops[random_currency] += 1

	# Guarantee at least 1 runic hammer if nothing dropped
	if drops.is_empty():
		drops["runic"] = 1

	return drops


## Spawns an item with appropriate mods for its rarity
## Does NOT consume currency - this is drop generation, not crafting
static func spawn_item_with_mods(item: Item, rarity: Item.Rarity) -> void:
	if rarity == Item.Rarity.NORMAL:
		# Normal items have no explicit mods
		return

	elif rarity == Item.Rarity.MAGIC:
		# Set rarity first (required for affix limit enforcement)
		item.rarity = Item.Rarity.MAGIC

		# Add 1-2 random mods (same logic as RunicHammer)
		var mod_count = randi_range(1, 2)
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

	elif rarity == Item.Rarity.RARE:
		# Set rarity first (required for affix limit enforcement)
		item.rarity = Item.Rarity.RARE

		# Add 4-6 random mods (same logic as ForgeHammer)
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
