class_name ExpeditionResolver extends RefCounted

## Tracks the currently active expedition, if any.
var active_config: ExpeditionConfig = null
var start_time: float = 0.0

## Whether an expedition is currently in progress.
var is_active: bool = false


func start_expedition(config: ExpeditionConfig) -> bool:
	if is_active:
		return false
	if GameState.hero.is_on_expedition:
		return false

	active_config = config
	start_time = Time.get_unix_time_from_system()
	is_active = true
	GameState.hero.is_on_expedition = true

	GameEvents.expedition_started.emit(config.expedition_id)
	return true


func get_elapsed_seconds() -> float:
	if not is_active:
		return 0.0
	return Time.get_unix_time_from_system() - start_time


func get_remaining_seconds() -> float:
	if not is_active or active_config == null:
		return 0.0
	var remaining := active_config.duration_seconds - get_elapsed_seconds()
	return maxf(0.0, remaining)


func get_progress() -> float:
	if not is_active or active_config == null:
		return 0.0
	var elapsed := get_elapsed_seconds()
	return clampf(elapsed / active_config.duration_seconds, 0.0, 1.0)


func is_completed() -> bool:
	if not is_active or active_config == null:
		return false
	return get_elapsed_seconds() >= active_config.duration_seconds


func resolve_rewards() -> Dictionary:
	if active_config == null:
		return {}

	var rewards: Dictionary = {}
	for currency_key: String in active_config.base_currency_rewards:
		var base_amount: int = active_config.base_currency_rewards[currency_key]
		var scaled_amount := _scale_reward(base_amount, active_config.difficulty)
		rewards[currency_key] = scaled_amount

	return rewards


func complete_expedition() -> Dictionary:
	if not is_active or not is_completed():
		return {}

	var rewards := resolve_rewards()
	var expedition_id := active_config.expedition_id

	GameState.add_currencies(rewards)

	_reset()

	GameEvents.expedition_completed.emit(expedition_id, rewards)
	GameEvents.expedition_collected.emit(expedition_id)

	return rewards


func cancel_expedition() -> void:
	if not is_active:
		return
	_reset()


func _reset() -> void:
	active_config = null
	start_time = 0.0
	is_active = false
	GameState.hero.is_on_expedition = false


func _scale_reward(base_amount: int, difficulty: int) -> int:
	## Simple scaling: each difficulty level adds 20% more rewards, with a
	## small random variance of +/- 20%.
	var multiplier := 1.0 + (difficulty - 1) * 0.2
	var variance := randf_range(0.8, 1.2)
	return maxi(1, int(float(base_amount) * multiplier * variance))


func get_save_data() -> Dictionary:
	if not is_active or active_config == null:
		return {}
	return {
		"expedition_id": active_config.expedition_id,
		"start_time": start_time,
	}


func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	var expedition_id: String = data.get("expedition_id", "")
	var saved_start_time: float = data.get("start_time", 0.0)

	var config := ExpeditionConfig.get_config_by_id(expedition_id)
	if config == null:
		return

	active_config = config
	start_time = saved_start_time
	is_active = true
	GameState.hero.is_on_expedition = true
