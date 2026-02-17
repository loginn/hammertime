extends Node2D

var current_view: String = "forge"

@onready var forge_view: Node2D = $ContentArea/ForgeView
@onready var gameplay_view: Node2D = $ContentArea/GameplayView
@onready var settings_view: Node2D = $ContentArea/SettingsView
@onready var forge_tab: Button = $TabBar/ForgeTab
@onready var combat_tab: Button = $TabBar/CombatTab
@onready var settings_tab: Button = $TabBar/SettingsTab
@onready var combat_ui: CanvasLayer = $ContentArea/GameplayView/CombatUI


func _ready() -> void:
	# Connect tab buttons
	forge_tab.pressed.connect(_on_forge_tab_pressed)
	combat_tab.pressed.connect(_on_combat_tab_pressed)
	settings_tab.pressed.connect(_on_settings_tab_pressed)

	# Connect settings view signals
	settings_view.new_game_started.connect(_on_new_game_started)

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


func _on_new_game_started() -> void:
	get_tree().reload_current_scene()


func show_view(view_name: String) -> void:
	# Hide all views
	forge_view.visible = false
	gameplay_view.visible = false
	settings_view.visible = false

	# Reset settings state when leaving
	if current_view == "settings" and view_name != "settings":
		settings_view.reset_state()

	match view_name:
		"forge":
			forge_view.visible = true
			forge_tab.disabled = true
			combat_tab.disabled = false
			settings_tab.disabled = false
		"combat":
			gameplay_view.visible = true
			forge_tab.disabled = false
			combat_tab.disabled = true
			settings_tab.disabled = false
		"settings":
			settings_view.visible = true
			forge_tab.disabled = false
			combat_tab.disabled = false
			settings_tab.disabled = true

	# CRITICAL: CanvasLayer doesn't inherit parent visibility — sync explicitly
	combat_ui.visible = (view_name == "combat")

	current_view = view_name
	print("Switched to ", view_name, " view")
