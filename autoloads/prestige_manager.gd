extends Node

var prestige_count: int = 0


func can_prestige() -> bool:
	return GameState.currency_counts.get("tack", 0) >= BalanceConfig.PRESTIGE_TACK_HAMMER_COST


func get_tack_hammer_count() -> int:
	return GameState.currency_counts.get("tack", 0)


func execute_prestige() -> bool:
	if not can_prestige():
		return false

	GameState.spend_currency("tack", BalanceConfig.PRESTIGE_TACK_HAMMER_COST)

	GameState.wipe_run_state()

	for key in GameState.CURRENCY_KEYS:
		GameState.currency_counts[key] = BalanceConfig.PRESTIGE_REWARD_AMOUNT

	prestige_count += 1

	GameEvents.prestige_completed.emit()

	return true
