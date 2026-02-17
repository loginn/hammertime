extends Node2D

signal item_base_found(item_base: Item)
signal currencies_found(drops: Dictionary)

@onready var start_clearing_button: Button = $StartClearingButton
@onready var next_area_button: Button = $NextAreaButton
@onready var combat_engine: CombatEngine = $CombatEngine
@onready var materials_label: Label = $MaterialsLabel
@onready var area_label: Label = $AreaLabel

var is_combat_active: bool = false
var item_bases_collected: Array = []


func _ready() -> void:
	item_bases_collected = []
	start_clearing_button.pressed.connect(_on_start_combat_pressed)
	next_area_button.pressed.connect(_on_next_area_pressed)

	# Connect combat signals for display updates
	GameEvents.combat_started.connect(_on_combat_started)
	GameEvents.pack_killed.connect(_on_pack_killed)
	GameEvents.hero_attacked.connect(_on_hero_attacked)
	GameEvents.pack_attacked.connect(_on_pack_attacked)
	GameEvents.hero_died.connect(_on_hero_died)
	GameEvents.map_completed.connect(_on_map_completed)
	GameEvents.combat_stopped.connect(_on_combat_stopped)

	# Connect drop system signals (Phase 16)
	GameEvents.items_dropped.connect(_on_items_dropped)
	GameEvents.currency_dropped.connect(_on_currency_dropped)

	update_display()


func _on_start_combat_pressed() -> void:
	if not is_combat_active:
		is_combat_active = true
		combat_engine.start_combat(combat_engine.area_level)
		start_clearing_button.text = "Stop Combat"
	else:
		is_combat_active = false
		combat_engine.stop_combat()
		start_clearing_button.text = "Start Combat"
	update_display()


func _on_next_area_pressed() -> void:
	combat_engine.area_level += 1
	combat_engine.max_unlocked_level = maxi(
		combat_engine.max_unlocked_level, combat_engine.area_level
	)
	if is_combat_active:
		combat_engine.stop_combat()
		combat_engine.start_combat(combat_engine.area_level)
	update_display()


## Called by main_view when equipment changes. Updates display only —
## CombatEngine recalculates attack speed at each pack fight start.
func refresh_clearing_speed() -> void:
	update_display()


# --- Combat signal handlers (display updates only) ---


func _on_combat_started(_area_level: int, _pack_count: int) -> void:
	update_display()


func _on_pack_killed(_pack_index: int, _total_packs: int) -> void:
	update_display()


func _on_hero_attacked(_damage: float, _is_crit: bool) -> void:
	update_display()


func _on_pack_attacked(_result: Dictionary) -> void:
	update_display()


func _on_hero_died() -> void:
	if not combat_engine.auto_retry:
		is_combat_active = false
		start_clearing_button.text = "Start Combat"
	update_display()


func _on_map_completed(completed_level: int) -> void:
	# Emit area_cleared for existing systems (preserve backward compatibility)
	GameEvents.area_cleared.emit(completed_level)
	update_display()


func _on_combat_stopped() -> void:
	update_display()


# --- Drop signal handlers (Phase 16) ---


func _on_items_dropped(completed_level: int, item_count: int) -> void:
	for i in range(item_count):
		var item_base := get_random_item_base(completed_level)
		if item_base != null:
			item_bases_collected.append(item_base)
			item_base_found.emit(item_base)


func _on_currency_dropped(drops: Dictionary) -> void:
	currencies_found.emit(drops)
	update_display()


# --- Display ---


func update_display() -> void:
	var hero := GameState.hero
	var display_text := ""

	# Area info
	var biome := BiomeConfig.get_biome_for_level(combat_engine.area_level)
	area_label.text = "Current Area: %s (Level %d)" % [biome.biome_name, combat_engine.area_level]

	# Hero health
	display_text += "Hero HP: %.0f/%.0f\n" % [hero.health, hero.max_health]

	# ES display
	if hero.get_total_energy_shield() > 0:
		display_text += (
			"ES: %.0f/%d\n" % [hero.get_current_energy_shield(), hero.get_total_energy_shield()]
		)

	display_text += "\n"

	# Combat state
	if combat_engine.state == CombatEngine.State.FIGHTING:
		var pack := combat_engine.get_current_pack()
		if pack != null:
			display_text += "Fighting: %s (%s)\n" % [pack.pack_name, pack.element]
			display_text += "Pack HP: %.0f/%.0f\n" % [pack.hp, pack.max_hp]
			display_text += (
				"Pack %d of %d\n"
				% [combat_engine.current_pack_index + 1, combat_engine.current_packs.size()]
			)
		display_text += "\n"
		display_text += "Hero DPS: %.1f\n" % hero.total_dps
	elif combat_engine.state == CombatEngine.State.HERO_DEAD and not combat_engine.auto_retry:
		display_text += "Hero died! Click Start Combat to retry.\n"
	elif combat_engine.state == CombatEngine.State.IDLE:
		display_text += "Ready to fight.\n"
		display_text += "Hero DPS: %.1f\n" % hero.total_dps

	# Defense summary
	display_text += "\n"
	if hero.get_total_armor() > 0:
		display_text += "Armor: %d\n" % hero.get_total_armor()
	if hero.get_total_evasion() > 0:
		var dodge := DefenseCalculator.calculate_dodge_chance(hero.get_total_evasion())
		display_text += "Evasion: %d (%.0f%% dodge)\n" % [hero.get_total_evasion(), dodge * 100.0]

	materials_label.text = display_text


# --- Item generation ---


func get_random_item_base(level: int = 1) -> Item:
	var item_types = [LightSword, BasicHelmet, BasicArmor, BasicBoots, BasicRing]
	var random_type = item_types[randi() % item_types.size()]
	var item = random_type.new()

	var rarity = LootTable.roll_rarity(level)
	LootTable.spawn_item_with_mods(item, rarity)

	return item
