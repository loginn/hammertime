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


func get_effective_duration() -> float:
	if active_config == null:
		return 0.0
	var hero_power := GameState.hero.get_hero_power()
	var mods := _get_totem_modifiers()
	return active_config.duration_seconds / ((1.0 + hero_power * BalanceConfig.EXPEDITION_HERO_POWER_SCALING) * (1.0 + mods.get("duration_reduction", 0.0)))


func get_elapsed_seconds() -> float:
	if not is_active:
		return 0.0
	return Time.get_unix_time_from_system() - start_time


func get_remaining_seconds() -> float:
	if not is_active or active_config == null:
		return 0.0
	var remaining := get_effective_duration() - get_elapsed_seconds()
	return maxf(0.0, remaining)


func get_progress() -> float:
	if not is_active or active_config == null:
		return 0.0
	var elapsed := get_elapsed_seconds()
	return clampf(elapsed / get_effective_duration(), 0.0, 1.0)


func is_completed() -> bool:
	if not is_active or active_config == null:
		return false
	return get_elapsed_seconds() >= get_effective_duration()


func resolve_rewards() -> Dictionary:
	if active_config == null:
		return {}

	if active_config.drop_table != null:
		return _resolve_from_drop_table()

	return {}


func _get_totem_modifiers() -> Dictionary:
	return GameState.totem_grid.get_effective_modifiers()


func _resolve_from_drop_table() -> Dictionary:
	var currencies: Dictionary = {}
	var items: Array[HeroItem] = []
	var mods := _get_totem_modifiers()

	var drop_quantity: float = mods.get("drop_quantity", 0.0)
	var bonus_roll_chance: float = mods.get("bonus_roll_chance", 0.0)
	var hammer_chance: float = mods.get("hammer_chance", 0.0)
	var steel_chance: float = mods.get("steel_chance", 0.0)
	var wood_chance: float = mods.get("wood_chance", 0.0)
	var drop_quality: float = mods.get("drop_quality", 0.0)

	# Compute total rolls: base 1 + guaranteed bonus + chance of one more
	var extra_rolls: int = int(bonus_roll_chance)
	if randf() < fmod(bonus_roll_chance, 1.0):
		extra_rolls += 1

	# Process rolls (1 base + extra_rolls bonus)
	for _roll_idx in range(1 + extra_rolls):
		var rolled_entries := active_config.drop_table.roll()
		for entry: Dictionary in rolled_entries:
			var qty: int = randi_range(entry["qty_min"], entry["qty_max"])

			if entry["type"] == "currency":
				var scaled := _scale_reward(qty, active_config.difficulty)
				# Apply drop_quantity multiplier
				var boosted := maxi(1, int(float(scaled) * (1.0 + drop_quantity)))
				var key: String = entry["key"]
				if key in currencies:
					currencies[key] += boosted
				else:
					currencies[key] = boosted

			elif entry["type"] == "item":
				var tier: Tag_List.MaterialTier = entry["material_tier"] as Tag_List.MaterialTier
				# Apply drop_quality: upgrade IRON → STEEL
				if drop_quality > 0.0 and tier == Tag_List.MaterialTier.IRON and randf() < drop_quality:
					tier = Tag_List.MaterialTier.STEEL
				var bases := ItemFactory.get_bases_for_material(tier)
				if bases.is_empty():
					continue
				var base_id: String = bases[randi() % bases.size()]
				var item := ItemFactory.create_base(base_id)
				if item != null:
					items.append(item)

	# Post-roll bonus drops from chance modifiers
	const HAMMER_KEYS: Array[String] = ["tack", "tuning", "forge", "grand", "runic", "claw"]
	const WOOD_KEYS: Array[String] = ["ash", "oak"]

	if hammer_chance > 0.0 and randf() < hammer_chance:
		var hkey: String = HAMMER_KEYS[randi() % HAMMER_KEYS.size()]
		currencies[hkey] = currencies.get(hkey, 0) + 1

	if steel_chance > 0.0 and randf() < steel_chance:
		currencies["steel"] = currencies.get("steel", 0) + 1

	if wood_chance > 0.0 and randf() < wood_chance:
		var wkey: String = WOOD_KEYS[randi() % WOOD_KEYS.size()]
		currencies[wkey] = currencies.get(wkey, 0) + 1

	if not mods.values().all(func(v): return v == 0.0):
		print_debug("_apply_totem_modifiers: ", mods, " | currencies after: ", currencies)

	return {"currencies": currencies, "items": items}


func complete_expedition() -> Dictionary:
	if not is_active or not is_completed():
		return {}

	var rewards := resolve_rewards()
	var expedition_id := active_config.expedition_id

	if "currencies" in rewards:
		GameState.add_currencies(rewards["currencies"])
		for item: HeroItem in rewards.get("items", []):
			GameState.add_item_to_inventory(item)
	else:
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
