extends VBoxContainer

signal hammer_selected(key: String)

const HAMMER_DATA: Array[Dictionary] = [
	{"key": "tack", "glyph": "🔨", "name": "Tack Hammer", "verb": "Transmute", "effect": "Normal → Magic", "target": "Normal"},
	{"key": "tuning", "glyph": "🔧", "name": "Tuning Hammer", "verb": "Alteration", "effect": "Reroll Magic affixes", "target": "Magic"},
	{"key": "forge", "glyph": "⚒️", "name": "Forge Hammer", "verb": "Augment", "effect": "Add affix to Magic", "target": "Magic"},
	{"key": "grand", "glyph": "👑", "name": "Grand Hammer", "verb": "Regal", "effect": "Magic → Rare", "target": "Magic"},
	{"key": "runic", "glyph": "✨", "name": "Runic Hammer", "verb": "Exalt", "effect": "Add affix to Rare", "target": "Rare"},
	{"key": "claw", "glyph": "🪝", "name": "Claw Hammer", "verb": "Annul", "effect": "Remove random affix", "target": "Any with mods"},
	{"key": "scour", "glyph": "🧹", "name": "Scour Hammer", "verb": "Scour", "effect": "Strip all → Normal", "target": "Non-Normal"},
]

var _selected_key: String = ""
var _buttons: Dictionary = {}
var _count_labels: Dictionary = {}

@onready var _grid: GridContainer = $MarginContainer/Content/Grid
@onready var _detail_panel: PanelContainer = $MarginContainer/Content/DetailPanel
@onready var _detail_name: Label = $MarginContainer/Content/DetailPanel/DetailVBox/DetailName
@onready var _detail_verb: Label = $MarginContainer/Content/DetailPanel/DetailVBox/DetailVerb
@onready var _detail_effect: Label = $MarginContainer/Content/DetailPanel/DetailVBox/DetailEffect
@onready var _detail_count: Label = $MarginContainer/Content/DetailPanel/DetailVBox/DetailCount
@onready var _tab_elemental: Button = $MarginContainer/Content/TabRow/TabElemental


func _ready() -> void:
	_build_buttons()
	_update_all_counts()
	_detail_panel.visible = false
	GameEvents.currency_changed.connect(_on_currency_changed)
	GameEvents.prestige_completed.connect(_on_prestige_completed)
	_update_elemental_tab()


func _build_buttons() -> void:
	for data in HAMMER_DATA:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(56, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 0)

		var glyph_label := Label.new()
		glyph_label.text = data["glyph"]
		glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph_label.add_theme_font_size_override("font_size", 22)
		glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(glyph_label)

		var count_label := Label.new()
		count_label.text = "0"
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 10)
		count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(count_label)

		btn.add_child(vbox)
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var dot := Panel.new()
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = Color(1.0, 0.7, 0.15)
		dot_style.corner_radius_top_left = 5
		dot_style.corner_radius_top_right = 5
		dot_style.corner_radius_bottom_left = 5
		dot_style.corner_radius_bottom_right = 5
		dot_style.shadow_color = Color(1.0, 0.55, 0.0, 0.7)
		dot_style.shadow_size = 3
		dot_style.shadow_offset = Vector2(0, 0)
		dot.add_theme_stylebox_override("panel", dot_style)
		dot.custom_minimum_size = Vector2(6, 6)
		dot.size = Vector2(6, 6)
		dot.position = Vector2(5, 5)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.visible = false
		btn.add_child(dot)

		btn.pressed.connect(_on_hammer_pressed.bind(data["key"]))
		btn.tooltip_text = data["name"]

		_grid.add_child(btn)
		_buttons[data["key"]] = btn
		_count_labels[data["key"]] = count_label


func _on_hammer_pressed(key: String) -> void:
	_selected_key = key
	_update_selection_highlight()
	_update_detail_card()
	hammer_selected.emit(key)


func _update_selection_highlight() -> void:
	for k in _buttons:
		var btn: Button = _buttons[k]
		var dot: Panel = btn.get_child(btn.get_child_count() - 1)
		dot.visible = (k == _selected_key)


func _update_detail_card() -> void:
	if _selected_key == "":
		_detail_panel.visible = false
		return

	var data: Dictionary = _get_hammer_data(_selected_key)
	if data.is_empty():
		_detail_panel.visible = false
		return

	_detail_panel.visible = true
	_detail_name.text = data["name"]
	_detail_verb.text = data["verb"]
	_detail_effect.text = data["effect"]
	var count: int = GameState.currency_counts.get(_selected_key, 0)
	_detail_count.text = "Count: %d" % count


func _get_hammer_data(key: String) -> Dictionary:
	for data in HAMMER_DATA:
		if data["key"] == key:
			return data
	return {}


func _on_currency_changed(currency_key: String, new_amount: int) -> void:
	if currency_key in _count_labels:
		_count_labels[currency_key].text = str(new_amount)
	if currency_key == _selected_key:
		_detail_count.text = "Count: %d" % new_amount


func _update_all_counts() -> void:
	for key in _count_labels:
		var count: int = GameState.currency_counts.get(key, 0)
		_count_labels[key].text = str(count)


func get_selected_key() -> String:
	return _selected_key


func _update_elemental_tab() -> void:
	if PrestigeManager.prestige_count >= 1:
		_tab_elemental.disabled = false
		_tab_elemental.text = "Elemental"
		_tab_elemental.tooltip_text = "Tag hammers coming soon"
	else:
		_tab_elemental.disabled = true
		_tab_elemental.text = "🔒 Elemental"
		_tab_elemental.tooltip_text = "Unlock by completing your first Prestige"


func _on_prestige_completed() -> void:
	_update_elemental_tab()
	_update_all_counts()
