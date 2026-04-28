extends VBoxContainer

signal piece_selected(piece: TotemPiece)
signal new_base_pressed

@onready var _item_count: Label = $ItemCount
@onready var _grid: GridContainer = $ScrollContainer/Grid


func _ready() -> void:
	refresh([])


func refresh(inventory: Array) -> void:
	for child in _grid.get_children():
		child.queue_free()
		_grid.remove_child(child)

	_item_count.text = "%d pieces" % inventory.size()

	var new_base_btn := Button.new()
	new_base_btn.text = "+ New Base"
	new_base_btn.add_theme_font_size_override("font_size", 11)
	new_base_btn.custom_minimum_size = Vector2(80, 80)
	new_base_btn.pressed.connect(func() -> void: new_base_pressed.emit())
	_grid.add_child(new_base_btn)

	for piece: TotemPiece in inventory:
		var tile := _build_piece_tile(piece)
		_grid.add_child(tile)


func _build_piece_tile(piece: TotemPiece) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.add_theme_font_size_override("font_size", 10)
	var label := piece.item_name
	if not piece.deity_tag.is_empty():
		label += "\n" + piece.deity_tag.replace("_", " ").capitalize()
	btn.text = label
	btn.add_theme_color_override("font_color", piece.get_rarity_color())
	btn.pressed.connect(func() -> void: piece_selected.emit(piece))
	return btn
