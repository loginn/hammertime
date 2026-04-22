extends Node

var prestige_count: int = 0


func can_prestige() -> bool:
	if is_max_prestige():
		return false
	return GameState.currency_counts.get("tack", 0) >= BalanceConfig.PRESTIGE_LEVELS[prestige_count].cost


func get_tack_hammer_count() -> int:
	return GameState.currency_counts.get("tack", 0)


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

	GameState.spend_currency("tack", level_data.cost)

	GameState.wipe_run_state()

	for key in GameState.CURRENCY_KEYS:
		GameState.currency_counts[key] = level_data.reward_amount

	prestige_count += 1

	GameEvents.prestige_completed.emit()

	return true
