class_name CombatEngine extends Node

## Pack-based combat engine with state machine and dual independent attack timers.
## Hero and packs attack on their own cadence. Replaces timer-based area clearing.
## Emits all combat events through GameEvents for UI observation (Phase 17).

enum State { IDLE, FIGHTING, MAP_COMPLETE, HERO_DEAD }

var state: State = State.IDLE
var current_packs: Array[MonsterPack] = []
var current_pack_index: int = 0
var auto_retry: bool = true  # Default on — player retries automatically after death
var pack_transition_delay_sec: float = 0.5  # Visual pause between pack fights
var death_retry_delay_sec: float = 2.5  # Delay before auto-retry after death
var hero_attack_speed: float = 1.0  # Cached from weapon at fight start
var run_currency_earned: Dictionary = {}  # Accumulated currency this run for display

var hero_attack_timer: Timer
var pack_attack_timer: Timer


func _ready() -> void:
	hero_attack_timer = Timer.new()
	hero_attack_timer.one_shot = false
	add_child(hero_attack_timer)
	hero_attack_timer.timeout.connect(_on_hero_attack)

	pack_attack_timer = Timer.new()
	pack_attack_timer.one_shot = false
	add_child(pack_attack_timer)
	pack_attack_timer.timeout.connect(_on_pack_attack)


## Starts a new map at the given area level. Generates fresh packs and begins combat.
func start_combat(level: int) -> void:
	GameState.area_level = level
	run_currency_earned = {}
	current_packs = PackGenerator.generate_packs(GameState.area_level)
	current_pack_index = 0
	state = State.FIGHTING
	GameEvents.combat_started.emit(GameState.area_level, current_packs.size())
	_start_pack_fight()


## Stops combat and returns to idle state. Restores hero HP and ES to max.
func stop_combat() -> void:
	_stop_timers()
	state = State.IDLE
	# Restore hero to full HP and ES when combat is stopped by player
	GameState.hero.health = GameState.hero.max_health
	GameState.hero.current_energy_shield = float(GameState.hero.total_energy_shield)
	GameEvents.combat_stopped.emit()


## Returns the current pack being fought, or null if out of bounds.
func get_current_pack() -> MonsterPack:
	if current_pack_index >= current_packs.size():
		return null
	return current_packs[current_pack_index]


## Begins a fight with the current pack. Sets timer cadences from weapon and pack speeds.
func _start_pack_fight() -> void:
	hero_attack_speed = _get_hero_attack_speed()
	hero_attack_timer.wait_time = 1.0 / hero_attack_speed
	pack_attack_timer.wait_time = 1.0 / get_current_pack().attack_speed
	hero_attack_timer.start()
	pack_attack_timer.start()


## Hero attacks the current pack. Rolls each damage element independently, then applies crit.
func _on_hero_attack() -> void:
	if state != State.FIGHTING:
		return

	var pack := get_current_pack()
	if pack == null or not pack.is_alive():
		return

	var hero := GameState.hero

	# Roll each element independently from hero's cached damage ranges
	var damage_per_hit := 0.0
	for element in hero.damage_ranges:
		var el_min: float = hero.damage_ranges[element]["min"]
		var el_max: float = hero.damage_ranges[element]["max"]
		if el_max > 0.0:
			damage_per_hit += randf_range(el_min, el_max)

	# Per-hit crit roll (applied to total, not per-element)
	var is_crit := randf() < (hero.total_crit_chance / 100.0)
	if is_crit:
		damage_per_hit *= (hero.total_crit_damage / 100.0)

	pack.take_damage(damage_per_hit)
	GameEvents.hero_attacked.emit(damage_per_hit, is_crit)

	if not pack.is_alive():
		_on_pack_killed()


## Pack attacks the hero. Rolls damage from pack range, routes through DefenseCalculator.
func _on_pack_attack() -> void:
	if state != State.FIGHTING:
		return

	var pack := get_current_pack()
	if pack == null:
		return

	var hero := GameState.hero
	var rolled_damage := randf_range(pack.damage_min, pack.damage_max)
	var result := DefenseCalculator.calculate_damage_taken(
		rolled_damage,
		pack.element,
		false,  # Pack attacks are attacks, not spells
		hero.get_total_armor(),
		hero.get_total_evasion(),
		hero.get_total_energy_shield(),
		hero.get_total_fire_resistance(),
		hero.get_total_cold_resistance(),
		hero.get_total_lightning_resistance(),
		hero.get_current_energy_shield()
	)

	GameEvents.pack_attacked.emit(result)

	if result["dodged"]:
		return

	hero.apply_damage(result["life_damage"], result["es_damage"])

	if not hero.is_healthy():
		_on_hero_died()


## Current pack killed. Drop currency and items, recharge ES, advance to next pack or complete map.
func _on_pack_killed() -> void:
	var killed_pack := get_current_pack()
	_stop_timers()

	# Currency drops on pack kill (Phase 16)
	var drops := LootTable.roll_pack_currency_drop(GameState.area_level, killed_pack.difficulty_bonus)
	if not drops.is_empty():
		GameState.add_currencies(drops)
		_accumulate_run_currency(drops)
		GameEvents.currency_dropped.emit(drops)

	# Item drops on pack kill (Phase 33)
	if LootTable.roll_pack_item_drop():
		GameEvents.items_dropped.emit(GameState.area_level)

	# Tag currency drops (P1+)
	var tag_drops := LootTable.roll_pack_tag_currency_drop(GameState.area_level)
	if not tag_drops.is_empty():
		for tag_type in tag_drops:
			GameState.tag_currency_counts[tag_type] = GameState.tag_currency_counts.get(tag_type, 0) + tag_drops[tag_type]
		GameEvents.tag_currency_dropped.emit(tag_drops)

	current_pack_index += 1
	GameEvents.pack_killed.emit(current_pack_index, current_packs.size())

	if current_pack_index >= current_packs.size():
		_on_map_completed()
		return

	# ES recharges 33% between packs
	GameState.hero.recharge_energy_shield()
	# Brief visual pause so player notices pack change
	await get_tree().create_timer(pack_transition_delay_sec).timeout
	# Guard: state may have changed during delay (e.g., combat stopped)
	if state != State.FIGHTING:
		return
	_start_pack_fight()


## All packs cleared. Full HP/ES recharge, advance area level, auto-start next map.
## Items now drop per-pack (Phase 33), not on map completion.
func _on_map_completed() -> void:
	state = State.MAP_COMPLETE
	# Full HP and ES recharge between maps
	GameState.hero.health = GameState.hero.max_health
	GameState.hero.current_energy_shield = float(GameState.hero.total_energy_shield)

	# Deterministic progression: always current_level + 1
	GameState.area_level += 1
	GameState.max_unlocked_level = maxi(GameState.max_unlocked_level, GameState.area_level)
	# Emit the level that was completed (before increment)
	GameEvents.map_completed.emit(GameState.area_level - 1)
	# Auto-advance: start next map immediately
	start_combat(GameState.area_level)


## Hero died. Revive with full HP + ES. Retry or wait based on auto_retry.
## Currency already in inventory from per-pack drops — no clawback.
## Items also drop per-pack — death means losing remaining packs' potential drops.
func _on_hero_died() -> void:
	state = State.HERO_DEAD
	_stop_timers()
	GameState.hero.revive()
	GameEvents.hero_died.emit()
	# Hero stays at same area level — retry until cleared or gear up
	if auto_retry:
		await get_tree().create_timer(death_retry_delay_sec).timeout
		# Guard: state may have changed during delay (e.g., combat stopped)
		if state != State.HERO_DEAD:
			return
		start_combat(GameState.area_level)


## Gets hero attack speed from equipped weapon, or default 1.0 unarmed.
func _get_hero_attack_speed() -> float:
	var weapon = GameState.hero.equipped_items.get("weapon")
	if weapon != null and weapon is Weapon:
		return weapon.base_attack_speed
	return 1.0


## Accumulates currency drops into run tracking dictionary.
func _accumulate_run_currency(drops: Dictionary) -> void:
	for currency_name in drops:
		if currency_name in run_currency_earned:
			run_currency_earned[currency_name] += drops[currency_name]
		else:
			run_currency_earned[currency_name] = drops[currency_name]


## Stops both attack timers. Called on every state transition exit.
func _stop_timers() -> void:
	hero_attack_timer.stop()
	pack_attack_timer.stop()
