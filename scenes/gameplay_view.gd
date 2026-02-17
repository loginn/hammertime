extends Node2D

const FLOATING_LABEL = preload("res://scenes/floating_label.tscn")

signal item_base_found(item_base: Item)
signal currencies_found(drops: Dictionary)

@onready var start_clearing_button: Button = $StartClearingButton
@onready var next_area_button: Button = $NextAreaButton
@onready var combat_engine: CombatEngine = $CombatEngine
@onready var area_label: Label = $AreaLabel

# Combat UI bar references
@onready var hero_hp_bar: ProgressBar = $CombatUI/UIRoot/HeroHealthContainer/HeroHPBar
@onready var hero_es_bar: ProgressBar = $CombatUI/UIRoot/HeroHealthContainer/HeroESBar
@onready var hero_hp_label: Label = $CombatUI/UIRoot/HeroHealthContainer/HeroHPLabel
@onready var pack_hp_bar: ProgressBar = $CombatUI/UIRoot/PackHealthContainer/PackHPBar
@onready var pack_hp_label: Label = $CombatUI/UIRoot/PackHealthContainer/PackHPLabel
@onready var pack_progress_bar: ProgressBar = $CombatUI/UIRoot/PackProgressContainer/PackProgressBar
@onready var pack_progress_label: Label = $CombatUI/UIRoot/PackProgressContainer/PackProgressLabel
@onready var combat_state_label: Label = $CombatUI/UIRoot/CombatStateLabel
@onready var hero_health_container: Control = $CombatUI/UIRoot/HeroHealthContainer
@onready var pack_health_container: Control = $CombatUI/UIRoot/PackHealthContainer
@onready var pack_progress_container: Control = $CombatUI/UIRoot/PackProgressContainer
@onready var floating_text_container: Control = $CombatUI/UIRoot/FloatingTextContainer

var is_combat_active: bool = false
var item_bases_collected: Array = []
var combat_started_once: bool = false

## Default state label color
var default_label_color := Color(1.0, 1.0, 1.0)

## Floating text spawn positions (above health bars)
var hero_damage_pos := Vector2(125.0, 160.0)  # Above hero HP bar
var pack_damage_pos := Vector2(450.0, 160.0)  # Above pack HP bar


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

	_setup_bar_styles()
	update_display()


func _setup_bar_styles() -> void:
	# Hero HP bar — red fill, dark red background
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.8, 0.0, 0.0)
	hero_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.2, 0.0, 0.0)
	hero_hp_bar.add_theme_stylebox_override("background", hp_bg)

	# Hero ES bar — blue fill, transparent dark blue background (stacked on top)
	var es_fill := StyleBoxFlat.new()
	es_fill.bg_color = Color(0.0, 0.5, 1.0, 0.7)
	hero_es_bar.add_theme_stylebox_override("fill", es_fill)
	var es_bg := StyleBoxFlat.new()
	es_bg.bg_color = Color(0.0, 0.1, 0.3, 0.3)
	hero_es_bar.add_theme_stylebox_override("background", es_bg)

	# Pack HP bar — orange-red fill, dark background
	var pack_fill := StyleBoxFlat.new()
	pack_fill.bg_color = Color(0.85, 0.3, 0.1)
	pack_hp_bar.add_theme_stylebox_override("fill", pack_fill)
	var pack_bg := StyleBoxFlat.new()
	pack_bg.bg_color = Color(0.2, 0.1, 0.05)
	pack_hp_bar.add_theme_stylebox_override("background", pack_bg)

	# Pack progress bar — green fill, dark green background
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color(0.2, 0.7, 0.2)
	pack_progress_bar.add_theme_stylebox_override("fill", progress_fill)
	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color(0.1, 0.2, 0.1)
	pack_progress_bar.add_theme_stylebox_override("background", progress_bg)

	# All bars: show_percentage already false in .tscn


func _on_start_combat_pressed() -> void:
	if not is_combat_active:
		is_combat_active = true
		combat_engine.start_combat(GameState.area_level)
		start_clearing_button.text = "Stop Combat"
	else:
		is_combat_active = false
		combat_engine.stop_combat()
		start_clearing_button.text = "Start Combat"
	update_display()


func _on_next_area_pressed() -> void:
	GameState.area_level += 1
	GameState.max_unlocked_level = maxi(
		GameState.max_unlocked_level, GameState.area_level
	)
	if is_combat_active:
		combat_engine.stop_combat()
		combat_engine.start_combat(GameState.area_level)
	update_display()


## Called by main_view when equipment changes. Updates display only —
## CombatEngine recalculates attack speed at each pack fight start.
func refresh_clearing_speed() -> void:
	update_display()


# --- Combat signal handlers ---


func _on_combat_started(_area_level: int, _pack_count: int) -> void:
	combat_started_once = true
	combat_state_label.text = "Fighting..."
	combat_state_label.add_theme_color_override("font_color", default_label_color)
	update_display()


func _on_pack_killed(_pack_index: int, _total_packs: int) -> void:
	combat_state_label.text = "Pack cleared!"
	combat_state_label.add_theme_color_override("font_color", default_label_color)
	update_display()


func _on_hero_attacked(damage: float, is_crit: bool) -> void:
	# Hero attacked the pack — show damage near pack HP bar
	_spawn_floating_text(pack_damage_pos, int(damage), is_crit)
	update_display()


func _on_pack_attacked(result: Dictionary) -> void:
	# Pack attacked the hero — show damage/dodge near hero HP bar
	if result["dodged"]:
		_spawn_floating_text(hero_damage_pos, 0, false, true)
	else:
		var total_damage := int(result["life_damage"] + result["es_damage"])
		_spawn_floating_text(hero_damage_pos, total_damage, false)
	update_display()


func _on_hero_died() -> void:
	combat_state_label.text = "Hero died! Retrying..."
	combat_state_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	if not combat_engine.auto_retry:
		is_combat_active = false
		start_clearing_button.text = "Start Combat"
		combat_state_label.text = "Hero died! Click Start Combat to retry."
	update_display()


func _on_map_completed(completed_level: int) -> void:
	combat_state_label.text = "Map Clear!"
	combat_state_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	# Emit area_cleared for existing systems (preserve backward compatibility)
	GameEvents.area_cleared.emit(completed_level)
	update_display()


func _on_combat_stopped() -> void:
	combat_state_label.text = "Combat stopped."
	combat_state_label.add_theme_color_override("font_color", default_label_color)
	update_display()


# --- Drop signal handlers (Phase 16) ---


func _on_items_dropped(completed_level: int, item_count: int) -> void:
	for i in range(item_count):
		var item_base := get_random_item_base(completed_level)
		if item_base != null:
			item_bases_collected.append(item_base)
			item_base_found.emit(item_base)


func _on_currency_dropped(_drops: Dictionary) -> void:
	currencies_found.emit(_drops)
	update_display()


# --- Floating text ---


func _spawn_floating_text(spawn_pos: Vector2, value: int, is_crit: bool = false, is_dodge: bool = false) -> void:
	var label = FLOATING_LABEL.instantiate()
	label.position = spawn_pos + Vector2(randf_range(-20.0, 20.0), 0.0)
	floating_text_container.add_child(label)
	if is_dodge:
		label.show_dodge()
	else:
		label.show_damage(value, is_crit)


# --- Display ---


func update_display() -> void:
	var hero := GameState.hero

	# Area info
	var biome := BiomeConfig.get_biome_for_level(GameState.area_level)
	area_label.text = "%s — Level %d" % [biome.biome_name, GameState.area_level]

	# Hero HP bar
	hero_hp_bar.max_value = hero.max_health
	hero_hp_bar.value = hero.health

	# Hero ES bar (stacked on top of HP bar, PoE style)
	var total_es := hero.get_total_energy_shield()
	var current_es := hero.get_current_energy_shield()
	if total_es > 0:
		hero_es_bar.visible = true
		hero_es_bar.max_value = total_es
		hero_es_bar.value = current_es
	else:
		hero_es_bar.visible = false

	# Hero HP label with ES info
	if total_es > 0:
		hero_hp_label.text = "%.0f/%.0f  ES: %.0f/%d" % [
			hero.health, hero.max_health, current_es, total_es
		]
	else:
		hero_hp_label.text = "%.0f/%.0f" % [hero.health, hero.max_health]

	# Hero health container: visible once combat has started at least once
	hero_health_container.visible = combat_started_once

	# Pack HP bar
	if combat_engine.state == CombatEngine.State.FIGHTING:
		var pack := combat_engine.get_current_pack()
		if pack != null:
			pack_health_container.visible = true
			pack_hp_bar.max_value = pack.max_hp
			pack_hp_bar.value = pack.hp
			pack_hp_label.text = "%.0f/%.0f" % [pack.hp, pack.max_hp]
		else:
			pack_health_container.visible = false
	else:
		pack_health_container.visible = false

	# Pack progress bar
	if combat_engine.state == CombatEngine.State.FIGHTING or combat_engine.state == CombatEngine.State.MAP_COMPLETE:
		pack_progress_container.visible = true
		var total_packs := combat_engine.current_packs.size()
		pack_progress_bar.max_value = total_packs
		pack_progress_bar.value = combat_engine.current_pack_index
		pack_progress_label.text = "%d/%d" % [combat_engine.current_pack_index, total_packs]
	else:
		pack_progress_container.visible = combat_started_once and combat_engine.state == CombatEngine.State.HERO_DEAD


# --- Item generation ---


func get_random_item_base(level: int = 1) -> Item:
	var item_types = [LightSword, BasicHelmet, BasicArmor, BasicBoots, BasicRing]
	var random_type = item_types[randi() % item_types.size()]
	var item = random_type.new()

	var rarity = LootTable.roll_rarity(level)
	LootTable.spawn_item_with_mods(item, rarity)

	return item
