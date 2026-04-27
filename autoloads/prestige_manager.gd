extends Node

var prestige_count: int = 0


func can_prestige() -> bool:
	if is_max_prestige():
		return false
	var level_data: Dictionary = BalanceConfig.PRESTIGE_LEVELS[prestige_count]
	return GameState.currency_counts.get(level_data.cost_currency, 0) >= level_data.cost


func get_next_level_data() -> Dictionary:
	if is_max_prestige():
		return {}
	return BalanceConfig.PRESTIGE_LEVELS[prestige_count]


func is_max_prestige() -> bool:
	return prestige_count >= len(BalanceConfig.PRESTIGE_LEVELS)


func execute_prestige() -> bool:
	if not can_prestige():
		return false

	var level_data: Dictionary = BalanceConfig.PRESTIGE_LEVELS[prestige_count]

	GameState.spend_currency(level_data.cost_currency, level_data.cost)

	GameState.wipe_run_state()

	prestige_count += 1

	GameEvents.prestige_completed.emit()

	return true
