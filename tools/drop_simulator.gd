extends Node

## Drop distribution simulator for validating currency gating and rarity weights.
## Run as main scene to output results to console.
## Remove or exclude from production builds.

func _ready() -> void:
	simulate_currency_drops()
	print("")
	simulate_rarity_distribution()
	print("")
	validate_hard_gates()

func simulate_currency_drops() -> void:
	print("=== Currency Drop Distribution ===")
	print("(1000 clears per area level)")
	print("")

	var test_levels = [1, 50, 99, 100, 110, 150, 199, 200, 210, 250, 299, 300, 310, 350, 400]
	var clears_per_level = 1000
	var currency_names = ["runic", "tack", "forge", "grand", "claw", "tuning"]

	# Print header
	var header = "Level\t"
	for name in currency_names:
		header += name + "\t"
	print(header)

	for area_level in test_levels:
		var totals = {}
		for name in currency_names:
			totals[name] = 0

		for i in range(clears_per_level):
			var drops = LootTable.roll_currency_drops(area_level)
			for currency in drops:
				totals[currency] += drops[currency]

		var line = str(area_level) + "\t"
		for name in currency_names:
			var avg = "%.2f" % (float(totals[name]) / float(clears_per_level))
			line += avg + "\t"
		print(line)

func simulate_rarity_distribution() -> void:
	print("=== Rarity Distribution ===")
	print("(1000 rolls per area level)")
	print("")

	var test_levels = [1, 50, 100, 150, 200, 250, 300, 400, 500]
	var rolls_per_level = 1000

	print("Level\tNormal%\tMagic%\tRare%")

	for area_level in test_levels:
		var counts = { Item.Rarity.NORMAL: 0, Item.Rarity.MAGIC: 0, Item.Rarity.RARE: 0 }
		for i in range(rolls_per_level):
			var rarity = LootTable.roll_rarity(area_level)
			counts[rarity] += 1

		var normal_pct = "%.1f" % (float(counts[Item.Rarity.NORMAL]) / float(rolls_per_level) * 100.0)
		var magic_pct = "%.1f" % (float(counts[Item.Rarity.MAGIC]) / float(rolls_per_level) * 100.0)
		var rare_pct = "%.1f" % (float(counts[Item.Rarity.RARE]) / float(rolls_per_level) * 100.0)
		print(str(area_level) + "\t" + normal_pct + "\t" + magic_pct + "\t" + rare_pct)

func validate_hard_gates() -> void:
	print("=== Hard Gate Validation ===")
	print("(10000 clears per gate boundary)")
	print("")

	# Test that currencies NEVER drop below their gate level
	var gate_tests = [
		{"level": 99, "must_not_contain": ["forge", "grand", "claw", "tuning"]},
		{"level": 199, "must_not_contain": ["grand", "claw", "tuning"]},
		{"level": 299, "must_not_contain": ["claw", "tuning"]},
	]

	var all_passed = true
	for test in gate_tests:
		var violations = []
		for i in range(10000):
			var drops = LootTable.roll_currency_drops(test["level"])
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
