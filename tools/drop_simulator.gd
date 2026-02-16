extends Node

## Drop distribution simulator for validating currency gating, rarity weights,
## and item quantity scaling.
## Run as main scene to output results to console.
## Remove or exclude from production builds.

func _ready() -> void:
	simulate_item_quantity()
	print("")
	simulate_rarity_distribution()
	print("")
	simulate_currency_drops()
	print("")
	validate_hard_gates()


func simulate_item_quantity() -> void:
	print("=== Item Quantity Distribution ===")
	print("(1000 clears per area level)")
	print("")

	var test_levels: Array = [1, 25, 50, 100, 150, 200, 250, 300, 400]
	var clears: int = 1000

	print("Level\tAvg Items\tMin\tMax")

	for area_level in test_levels:
		var total_items: int = 0
		var min_items: int = 999
		var max_items: int = 0
		for i in range(clears):
			var count: int = LootTable.get_item_drop_count(area_level)
			total_items += count
			min_items = min(min_items, count)
			max_items = max(max_items, count)
		var avg: String = "%.2f" % (float(total_items) / float(clears))
		print(str(area_level) + "\t" + avg + "\t\t" + str(min_items) + "\t" + str(max_items))


func simulate_rarity_distribution() -> void:
	print("=== Rarity Distribution (per roll + per clear) ===")
	print("(1000 rolls per area level)")
	print("")

	var test_levels: Array = [1, 50, 100, 150, 200, 250, 300, 400]
	var rolls_per_level: int = 1000

	print("Level\tNormal%\tMagic%\tRare%\tItems/Clr\tRares/Clr")

	for area_level in test_levels:
		var counts: Dictionary = {Item.Rarity.NORMAL: 0, Item.Rarity.MAGIC: 0, Item.Rarity.RARE: 0}
		for i in range(rolls_per_level):
			var rarity: Item.Rarity = LootTable.roll_rarity(area_level)
			counts[rarity] += 1

		var normal_pct: float = float(counts[Item.Rarity.NORMAL]) / float(rolls_per_level) * 100.0
		var magic_pct: float = float(counts[Item.Rarity.MAGIC]) / float(rolls_per_level) * 100.0
		var rare_pct: float = float(counts[Item.Rarity.RARE]) / float(rolls_per_level) * 100.0

		# Calculate average items per clear for this level
		var total_items: int = 0
		for j in range(100):
			total_items += LootTable.get_item_drop_count(area_level)
		var avg_items: float = float(total_items) / 100.0
		var rares_per_clear: float = (rare_pct / 100.0) * avg_items

		print(
			str(area_level) + "\t"
			+ "%.1f" % normal_pct + "\t"
			+ "%.1f" % magic_pct + "\t"
			+ "%.1f" % rare_pct + "\t"
			+ "%.1f" % avg_items + "\t\t"
			+ "%.2f" % rares_per_clear
		)


func simulate_currency_drops() -> void:
	print("=== Currency Drop Distribution ===")
	print("(1000 clears per area level)")
	print("")

	var test_levels: Array = [1, 50, 99, 100, 110, 150, 199, 200, 210, 250, 299, 300, 310, 350, 400]
	var clears_per_level: int = 1000
	var currency_names: Array = ["runic", "tack", "forge", "grand", "claw", "tuning"]

	# Print header
	var header: String = "Level\t"
	for cname in currency_names:
		header += cname + "\t"
	print(header)

	for area_level in test_levels:
		var totals: Dictionary = {}
		for cname in currency_names:
			totals[cname] = 0

		for i in range(clears_per_level):
			var drops: Dictionary = LootTable.roll_currency_drops(area_level)
			for currency in drops:
				totals[currency] += drops[currency]

		var line: String = str(area_level) + "\t"
		for cname in currency_names:
			var avg: String = "%.2f" % (float(totals[cname]) / float(clears_per_level))
			line += avg + "\t"
		print(line)


func validate_hard_gates() -> void:
	print("=== Hard Gate Validation ===")
	print("(10000 clears per gate boundary)")
	print("")

	# Test that currencies NEVER drop below their gate level
	var gate_tests: Array = [
		{"level": 99, "must_not_contain": ["forge", "grand", "claw", "tuning"]},
		{"level": 199, "must_not_contain": ["grand", "claw", "tuning"]},
		{"level": 299, "must_not_contain": ["claw", "tuning"]},
	]

	var all_passed: bool = true
	for test in gate_tests:
		var violations: Array = []
		for i in range(10000):
			var drops: Dictionary = LootTable.roll_currency_drops(test["level"])
			for forbidden in test["must_not_contain"]:
				if forbidden in drops:
					violations.append(forbidden)

		if violations.size() == 0:
			print("PASS: Area %d correctly excludes %s" % [test["level"], str(test["must_not_contain"])])
		else:
			print("FAIL: Area %d dropped forbidden currencies: %s" % [test["level"], str(violations)])
			all_passed = false

	print("")
	if all_passed:
		print("All hard gate checks PASSED")
	else:
		print("HARD GATE VIOLATIONS DETECTED - fix before shipping")
