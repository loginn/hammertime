extends Node2D

var current_view: String = "forge"
var prestige_tab_revealed: bool = false
var _hero_overlay: Control = null

const _ARCH_NAMES: Dictionary = {
	HeroArchetype.Archetype.STR: "STR",
	HeroArchetype.Archetype.DEX: "DEX",
	HeroArchetype.Archetype.INT: "INT",
}
const _SUB_NAMES: Dictionary = {
	HeroArchetype.Subvariant.HIT: "Hit",
	HeroArchetype.Subvariant.DOT: "DoT",
	HeroArchetype.Subvariant.ELEMENTAL: "Elemental",
}

@onready var forge_view: Node2D = $ContentArea/ForgeView
@onready var gameplay_view: Node2D = $ContentArea/GameplayView
@onready var settings_view: Node2D = $ContentArea/SettingsView
@onready var forge_tab: Button = $TabBar/ForgeTab
@onready var combat_tab: Button = $TabBar/CombatTab
@onready var settings_tab: Button = $TabBar/SettingsTab
@onready var prestige_view: Node2D = $ContentArea/PrestigeView
@onready var prestige_tab: Button = $TabBar/PrestigeTab
@onready var fade_rect: ColorRect = $OverlayLayer/FadeRect
@onready var combat_ui: CanvasLayer = $ContentArea/GameplayView/CombatUI


func _ready() -> void:
	# Connect tab buttons
	forge_tab.pressed.connect(_on_forge_tab_pressed)
	combat_tab.pressed.connect(_on_combat_tab_pressed)
	settings_tab.pressed.connect(_on_settings_tab_pressed)
	prestige_tab.pressed.connect(_on_prestige_tab_pressed)

	# Connect settings view signals
	settings_view.new_game_started.connect(_on_new_game_started)

	# Connect prestige view signals
	prestige_view.prestige_triggered.connect(_on_prestige_triggered)

	# Connect currency signals for prestige tab reveal
	GameEvents.currency_dropped.connect(_check_prestige_tab_reveal)

	# Initial prestige tab state
	_check_prestige_tab_reveal()
	prestige_tab.text = "P" + str(GameState.prestige_level)

	# Cross-view signal wiring (ForgeView <-> GameplayView)
	forge_view.equipment_changed.connect(gameplay_view.refresh_clearing_speed)
	gameplay_view.item_base_found.connect(GameState.add_item_to_stash)
	gameplay_view.currencies_found.connect(forge_view.on_currencies_found)

	# Show forge view by default
	show_view("forge")

	# Hero selection check (D-08, D-09)
	if GameState.prestige_level >= 1 and GameState.hero_archetype == null:
		_show_hero_selection()


func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				show_view("forge")
			KEY_2:
				show_view("combat")
			KEY_TAB:
				if current_view == "forge":
					show_view("combat")
				else:
					show_view("forge")


func _on_forge_tab_pressed() -> void:
	show_view("forge")


func _on_combat_tab_pressed() -> void:
	show_view("combat")


func _on_settings_tab_pressed() -> void:
	show_view("settings")


func _on_prestige_tab_pressed() -> void:
	show_view("prestige")


func _on_new_game_started() -> void:
	get_tree().reload_current_scene()


func show_view(view_name: String) -> void:
	# Hide all views
	forge_view.visible = false
	gameplay_view.visible = false
	settings_view.visible = false
	prestige_view.visible = false

	# Reset settings state when leaving
	if current_view == "settings" and view_name != "settings":
		settings_view.reset_state()

	if current_view == "prestige" and view_name != "prestige":
		prestige_view.reset_state()

	match view_name:
		"forge":
			forge_view.visible = true
			forge_tab.disabled = true
			combat_tab.disabled = false
			settings_tab.disabled = false
			prestige_tab.disabled = false
		"combat":
			gameplay_view.visible = true
			forge_tab.disabled = false
			combat_tab.disabled = true
			settings_tab.disabled = false
			prestige_tab.disabled = false
		"settings":
			settings_view.visible = true
			forge_tab.disabled = false
			combat_tab.disabled = false
			settings_tab.disabled = true
			prestige_tab.disabled = false
		"prestige":
			prestige_view.visible = true
			forge_tab.disabled = false
			combat_tab.disabled = false
			settings_tab.disabled = false
			prestige_tab.disabled = true
			prestige_view._update_display()

	# CRITICAL: CanvasLayer doesn't inherit parent visibility — sync explicitly
	combat_ui.visible = (view_name == "combat")

	current_view = view_name
	print("Switched to ", view_name, " view")


func _check_prestige_tab_reveal(_drops: Dictionary = {}) -> void:
	if prestige_tab_revealed:
		return
	if GameState.prestige_level > 0 or PrestigeManager.can_prestige():
		prestige_tab_revealed = true
		prestige_tab.visible = true
		prestige_tab.text = "P" + str(GameState.prestige_level)


func _on_prestige_triggered() -> void:
	# Show fade rect and block input during fade
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = 0  # STOP — block all input during fade

	# Tween fade to opaque black over 0.5s
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	tween.tween_callback(_do_prestige_reload)


func _do_prestige_reload() -> void:
	get_tree().reload_current_scene()


func _show_hero_selection() -> void:
	GameEvents.hero_selection_needed.emit()

	var choices := HeroArchetype.generate_choices()

	# Build overlay root
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.name = "HeroSelectionOverlay"
	_hero_overlay = overlay

	# Semi-transparent background (blocks all input)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.75)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)

	# Centered layout container
	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_CENTER)
	layout.grow_horizontal = Control.GROW_DIRECTION_BOTH
	layout.grow_vertical = Control.GROW_DIRECTION_BOTH
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(layout)

	# Header label
	var header := Label.new()
	header.text = "Choose Your Hero"
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color.WHITE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(header)

	# Card row
	var card_row := HBoxContainer.new()
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 20)
	layout.add_child(card_row)

	# Build one card per hero choice
	for hero in choices:
		card_row.add_child(_build_hero_card(hero))

	$OverlayLayer.add_child(overlay)


func _build_hero_card(hero: HeroArchetype) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	# Styled background with colored left border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 1.0)
	style.border_width_left = 5
	style.border_color = hero.color
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	card.add_child(content)

	# Archetype label (e.g. "STR - Hit")
	var arch_label := Label.new()
	arch_label.text = _ARCH_NAMES[hero.archetype] + " - " + _SUB_NAMES[hero.subvariant]
	arch_label.add_theme_font_size_override("font_size", 16)
	arch_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content.add_child(arch_label)

	# Hero title
	var title_label := Label.new()
	title_label.text = hero.title
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	content.add_child(title_label)

	# Separator
	content.add_child(HSeparator.new())

	# Passive bonus lines
	for bonus_str in HeroArchetype.format_bonuses(hero.passive_bonuses):
		var bonus_label := Label.new()
		bonus_label.text = bonus_str
		bonus_label.add_theme_font_size_override("font_size", 16)
		bonus_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		content.add_child(bonus_label)

	# Click handler
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_hero_card_selected(hero)
	)

	return card


func _on_hero_card_selected(hero: HeroArchetype) -> void:
	# Prevent double-click during fade
	if _hero_overlay == null:
		return
	var overlay := _hero_overlay
	_hero_overlay = null  # guard against re-entry

	# Set archetype and update stats (Pitfall 6)
	GameState.hero_archetype = hero
	GameState.hero.update_stats()

	# Persist immediately (D-14)
	SaveManager.save_game()

	# Place archetype-matched starter items in stash (D-09: after archetype confirmed)
	GameState._place_starter_kit(hero)
	SaveManager.save_game()  # Persist starter kit immediately

	# Emit signal for listeners
	GameEvents.hero_selected.emit(hero)

	# Fade out 0.3s then free (D-13)
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(overlay.queue_free)
