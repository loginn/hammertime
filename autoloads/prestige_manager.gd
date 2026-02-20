extends Node

const MAX_PRESTIGE_LEVEL: int = 7

# Key = prestige level (1-7), Value = {currency_type: amount}
# P2-P7 use stub values (999999) -- unreachable until costs are tuned
const PRESTIGE_COSTS: Dictionary = {
	1: { "forge": 100 },
	2: { "forge": 999999 },
	3: { "forge": 999999 },
	4: { "forge": 999999 },
	5: { "forge": 999999 },
	6: { "forge": 999999 },
	7: { "forge": 999999 },
}

# Index = prestige level (0-7), Value = max_item_tier_unlocked
# P0 baseline: tier 8 (lowest quality ceiling)
# P7 final: tier 1 (best quality ceiling)
const ITEM_TIERS_BY_PRESTIGE: Array[int] = [8, 7, 6, 5, 4, 3, 2, 1]

const TAG_TYPES: Array[String] = ["fire", "cold", "lightning", "defense", "physical"]


## Returns true if player meets all prestige requirements.
func can_prestige() -> bool:
	if GameState.prestige_level >= MAX_PRESTIGE_LEVEL:
		return false
	var next_level: int = GameState.prestige_level + 1
	var cost: Dictionary = PRESTIGE_COSTS[next_level]
	for currency_type in cost:
		if GameState.currency_counts.get(currency_type, 0) < cost[currency_type]:
			return false
	return true


## Returns the cost dictionary for the next prestige, or empty if at max.
func get_next_prestige_cost() -> Dictionary:
	if GameState.prestige_level >= MAX_PRESTIGE_LEVEL:
		return {}
	return PRESTIGE_COSTS[GameState.prestige_level + 1]


## Executes prestige: validates, spends, advances level, wipes run, grants bonus, signals.
## Returns true on success, false if requirements not met.
func execute_prestige() -> bool:
	if not can_prestige():
		return false

	var next_level: int = GameState.prestige_level + 1
	var cost: Dictionary = PRESTIGE_COSTS[next_level]

	# CRITICAL: Spend BEFORE wipe -- wipe zeroes currency_counts
	for currency_type in cost:
		var amount: int = cost[currency_type]
		for i in range(amount):
			GameState.spend_currency(currency_type)

	# Advance prestige state (both fields before wipe so they survive)
	GameState.prestige_level = next_level
	GameState.max_item_tier_unlocked = ITEM_TIERS_BY_PRESTIGE[next_level]

	# Wipe all run-scoped state
	GameState._wipe_run_state()

	# Grant post-prestige bonus: 1 random tag hammer (AFTER wipe so it's not wiped)
	_grant_random_tag_currency()

	# Notify observers
	GameEvents.prestige_completed.emit(next_level)

	return true


## Grants 1 unit of a uniformly-random tag currency after prestige wipe.
func _grant_random_tag_currency() -> void:
	var chosen: String = TAG_TYPES.pick_random()
	if chosen not in GameState.tag_currency_counts:
		GameState.tag_currency_counts[chosen] = 0
	GameState.tag_currency_counts[chosen] += 1
