extends Control

const COLOR_TAB_ACTIVE := Color(0.85, 0.75, 0.55, 1)
const COLOR_TAB_INACTIVE := Color(0.45, 0.38, 0.3, 1)

@onready var _tab_forge: Button = %TabForge
@onready var _tab_expeditions: Button = %TabExpeditions
@onready var _tab_prestige: Button = %TabPrestige
@onready var _tab_settings: Button = %TabSettings

@onready var _forge_view: Control = $VBox/Body/ForgeView
@onready var _expedition_screen: Control = $VBox/Body/ExpeditionScreen

var _views: Dictionary = {}
var _tabs: Dictionary = {}


func _ready() -> void:
	_views = {
		"forge": _forge_view,
		"expeditions": _expedition_screen,
	}
	_tabs = {
		"forge": _tab_forge,
		"expeditions": _tab_expeditions,
	}

	_tab_forge.pressed.connect(_on_tab_forge_pressed)
	_tab_expeditions.pressed.connect(_on_tab_expeditions_pressed)

	_switch_to_view("forge")


func _on_tab_forge_pressed() -> void:
	_switch_to_view("forge")


func _on_tab_expeditions_pressed() -> void:
	_switch_to_view("expeditions")


func _switch_to_view(view_name: String) -> void:
	for key: String in _views:
		_views[key].visible = (key == view_name)

	for key: String in _tabs:
		var btn: Button = _tabs[key]
		if key == view_name:
			btn.add_theme_color_override("font_color", COLOR_TAB_ACTIVE)
		else:
			btn.add_theme_color_override("font_color", COLOR_TAB_INACTIVE)
