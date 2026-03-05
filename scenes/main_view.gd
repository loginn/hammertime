extends Node2D

var current_view: String = "forge"
var prestige_tab_revealed: bool = false

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
	gameplay_view.item_base_found.connect(forge_view.set_new_item_base)
	gameplay_view.currencies_found.connect(forge_view.on_currencies_found)

	# Show forge view by default
	show_view("forge")


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
