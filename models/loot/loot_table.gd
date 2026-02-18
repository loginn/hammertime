class_name LootTable extends Resource

# Rarity anchor points for logarithmic interpolation
# Weights are per-roll percentages (item quantity affects per-clear rate)
# Area 1:   1.0 items/clear -> 2% rare per roll = 0.02 rares/clear (1 per 50)
# Area 100: 2.3 items/clear -> 4% rare per roll = 0.09 rares/clear (1 per 11)
# Area 200: 3.5 items/clear -> 5% rare per roll = 0.18 rares/clear (1 per 5.7)
# Area 300: 4.5 items/clear -> 5% rare per roll = 0.23 rares/clear (1 per 4.4)
const RARITY_ANCHORS: Dictionary = {
	1: {Item.Rarity.NORMAL: 91.0, Item.Rarity.MAGIC: 7.0, Item.Rarity.RARE: 2.0},
	100: {Item.Rarity.NORMAL: 66.0, Item.Rarity.MAGIC: 30.0, Item.Rarity.RARE: 4.0},
	200: {Item.Rarity.NORMAL: 40.0, Item.Rarity.MAGIC: 55.0, Item.Rarity.RARE: 5.0},
	300: {Item.Rarity.NORMAL: 20.0, Item.Rarity.MAGIC: 75.0, Item.Rarity.RARE: 5.0},
}

# Currency unlock thresholds by area level
const CURRENCY_AREA_GATES: Dictionary = {
	"runic": 1,
	"tack": 1,
	"forge": 100,
	"grand": 200,
	"claw": 300,
	"tuning": 300,
}


## Returns the rarity weight distribution for a given area level
## Uses logarithmic interpolation between anchor points for smooth progression
static func get_rarity_weights(area_level: int) -> Dictionary:
	var anchors: Array = RARITY_ANCHORS.keys()
	anchors.sort()

	# Clamp to anchor range
	if area_level <= anchors[0]:
		return RARITY_ANCHORS[anchors[0]].duplicate()
	if area_level >= anchors[anchors.size() - 1]:
		return RARITY_ANCHORS[anchors[anchors.size() - 1]].duplicate()

	# Find bounding anchors
	var lower_key: int = anchors[0]
	var upper_key: int = anchors[anchors.size() - 1]
	for i in range(anchors.size() - 1):
		if area_level >= anchors[i] and area_level < anchors[i + 1]:
			lower_key = anchors[i]
			upper_key = anchors[i + 1]
			break

	# Calculate logarithmic interpolation factor
	var linear_t: float = float(area_level - lower_key) / float(upper_key - lower_key)
	var log_t: float = log(1.0 + linear_t * 9.0) / log(10.0)

	# Mild bump at tier boundaries (within 10 levels of 100/200/300)
	var bump: float = 0.0
	for boundary in [100, 200, 300]:
		var dist: float = abs(area_level - boundary)
		if dist <= 10:
			bump = 2.0 * (1.0 - dist / 10.0)
			break

	# Interpolate each rarity weight
	var lower: Dictionary = RARITY_ANCHORS[lower_key]
	var upper: Dictionary = RARITY_ANCHORS[upper_key]
	var result: Dictionary = {}
	for rarity in lower:
		var interpolated: float = lower[rarity] + (upper[rarity] - lower[rarity]) * log_t
		result[rarity] = interpolated

	# Apply tier boundary bump to rare (subtract from normal)
	if bump > 0.0:
		result[Item.Rarity.RARE] += bump
		result[Item.Rarity.NORMAL] -= bump

	return result


## Rolls a random rarity based on area level weights
static func roll_rarity(area_level: int) -> Item.Rarity:
	var weights: Dictionary = get_rarity_weights(area_level)

	# Calculate total weight
	var total_weight: float = 0.0
	for rarity in weights:
		total_weight += weights[rarity]

	# Generate random roll (0.0 to total_weight)
	var roll: float = randf() * total_weight

	# Walk through weights (NORMAL -> MAGIC -> RARE)
	var accumulated: float = 0.0

	accumulated += weights[Item.Rarity.NORMAL]
	if roll < accumulated:
		return Item.Rarity.NORMAL

	accumulated += weights[Item.Rarity.MAGIC]
	if roll < accumulated:
		return Item.Rarity.MAGIC

	return Item.Rarity.RARE


## Returns number of items to drop on map completion (1-3).
## Distribution scales with area level per anchors:
##   Area 1:   ~99% chance for 1, ~1% for 2, ~0% for 3
##   Area 300: ~20% for 1, ~60% for 2, ~20% for 3
## Uses logarithmic interpolation for smooth progression between anchors.
static func get_map_item_count(area_level: int) -> int:
	# Log progress: 0.0 at area 1, approaches 1.0 at area 300
	var progress: float = log(1.0 + float(area_level) / 50.0) / log(1.0 + 300.0 / 50.0)
	progress = clampf(progress, 0.0, 1.0)

	# Interpolate anchor weights
	var w1: float = lerpf(0.99, 0.20, progress)  # chance for 1 item
	var w2: float = lerpf(0.01, 0.60, progress)  # chance for 2 items
	# w3 is the remainder (chance for 3 items)

	var roll: float = randf()
	if roll < w1:
		return 1
	elif roll < w1 + w2:
		return 2
	else:
		return 3


## Calculates currency drop chance with ramping for newly unlocked currencies
## Starts at 10% of base chance at unlock, linearly ramps to 100% over ramp_duration levels
static func _calculate_currency_chance(
	base_chance: float,
	area_level: int,
	unlock_level: int,
	ramp_duration: int = 50
) -> float:
	if area_level < unlock_level:
		return 0.0
	var levels_since_unlock: int = area_level - unlock_level
	if levels_since_unlock >= ramp_duration:
		return base_chance
	var ramp_progress: float = float(levels_since_unlock) / float(ramp_duration)
	var ramp_multiplier: float = 0.1 + (0.9 * ramp_progress)
	return base_chance * ramp_multiplier


## Rolls currency drops for a single pack kill.
## Returns dictionary mapping currency name to drop count (0-2 per currency type).
## Chances scale with area level and pack difficulty. Area gating from CURRENCY_AREA_GATES applies.
static func roll_pack_currency_drop(
	area_level: int, pack_difficulty_bonus: float = 1.0
) -> Dictionary:
	var drops: Dictionary = {}

	# Area scaling: higher areas give better drop rates
	# Starts at 1.0x at area 1, reaches ~1.85x at area 300
	var area_multiplier: float = 1.0 + log(float(maxi(area_level, 1))) * 0.15

	# Per-pack base chances (scaled down from per-clear rates for ~12 packs/map avg)
	var pack_currency_rules: Dictionary = {
		"runic": {"chance": 0.15, "max_qty": 2},
		"tack": {"chance": 0.10, "max_qty": 2},
		"forge": {"chance": 0.05, "max_qty": 1},
		"grand": {"chance": 0.03, "max_qty": 1},
		"claw": {"chance": 0.04, "max_qty": 1},
		"tuning": {"chance": 0.04, "max_qty": 1},
	}

	for currency_name in pack_currency_rules:
		var unlock_level: int = CURRENCY_AREA_GATES[currency_name]
		if area_level < unlock_level:
			continue

		var rule: Dictionary = pack_currency_rules[currency_name]
		var effective_chance: float = rule["chance"] * area_multiplier * pack_difficulty_bonus

		# Apply unlock ramp (same as existing _calculate_currency_chance)
		if unlock_level > 1:
			effective_chance = _calculate_currency_chance(
				effective_chance, area_level, unlock_level, 50
			)

		if randf() < effective_chance:
			# Roll quantity: 1 or up to max_qty
			var quantity: int = randi_range(1, rule["max_qty"])
			drops[currency_name] = quantity

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

		# Add 1-2 random mods (70% chance of 1 mod, 30% chance of 2 mods)
		var mod_count: int = 1 if randf() < 0.7 else 2
		for i in range(mod_count):
			# Randomly choose prefix or suffix (50/50)
			var choose_prefix: bool = randi_range(0, 1) == 0

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
		var mod_count: int = randi_range(4, 6)
		for i in range(mod_count):
			# Randomly choose prefix or suffix (50/50)
			var choose_prefix: bool = randi_range(0, 1) == 0

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
