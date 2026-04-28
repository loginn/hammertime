extends PanelContainer

signal slot_clicked(pos: Vector2i)

var grid_pos: Vector2i = Vector2i(0, 0)

@onready var _piece_name: Label = %PieceName
@onready var _deity_tag: Label = %DeityTag
@onready var _rarity: Label = %Rarity
@onready var _synergy_label: Label = %SynergyLabel

var _synergy_style: StyleBoxFlat
var _normal_style: StyleBoxFlat


func _ready() -> void:
	_synergy_style = StyleBoxFlat.new()
	_synergy_style.bg_color = Color(0.06, 0.18, 0.08, 1)
	_synergy_style.border_width_left = 2
	_synergy_style.border_width_top = 2
	_synergy_style.border_width_right = 2
	_synergy_style.border_width_bottom = 2
	_synergy_style.border_color = Color(0.2, 0.85, 0.35, 1)
	_synergy_style.corner_radius_top_left = 3
	_synergy_style.corner_radius_top_right = 3
	_synergy_style.corner_radius_bottom_right = 3
	_synergy_style.corner_radius_bottom_left = 3
	_synergy_style.content_margin_left = 6.0
	_synergy_style.content_margin_top = 6.0
	_synergy_style.content_margin_right = 6.0
	_synergy_style.content_margin_bottom = 6.0

	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color(0.1, 0.08, 0.06, 1)
	_normal_style.corner_radius_top_left = 3
	_normal_style.corner_radius_top_right = 3
	_normal_style.corner_radius_bottom_right = 3
	_normal_style.corner_radius_bottom_left = 3
	_normal_style.content_margin_left = 6.0
	_normal_style.content_margin_top = 6.0
	_normal_style.content_margin_right = 6.0
	_normal_style.content_margin_bottom = 6.0

	add_theme_stylebox_override("panel", _normal_style)
	gui_input.connect(_on_gui_input)
	refresh(null, false)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		slot_clicked.emit(grid_pos)


func refresh(piece: TotemPiece, is_synergized: bool) -> void:
	if piece == null:
		_piece_name.text = "Empty"
		_piece_name.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
		_deity_tag.visible = false
		_rarity.visible = false
		_synergy_label.visible = false
		add_theme_stylebox_override("panel", _normal_style)
		return

	_piece_name.text = piece.item_name
	_piece_name.add_theme_color_override("font_color", piece.get_rarity_color())

	if not piece.deity_tag.is_empty():
		_deity_tag.text = piece.deity_tag.replace("_", " ").capitalize()
		_deity_tag.visible = true
	else:
		_deity_tag.visible = false

	var tier_name: String = Tag.material_name(piece.material_tier)
	if not tier_name.is_empty():
		_rarity.text = tier_name.to_upper()
		_rarity.visible = true
	else:
		_rarity.visible = false

	_synergy_label.visible = is_synergized
	add_theme_stylebox_override("panel", _synergy_style if is_synergized else _normal_style)
