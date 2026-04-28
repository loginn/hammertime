extends Control

@onready var _hammer_rail: Node = %HammerRail
@onready var _grid_panel: PanelContainer = %TotemGridPanel
@onready var _crafting_bench: HBoxContainer = %TotemCraftingBench
@onready var _inventory_grid: VBoxContainer = %TotemInventoryGrid

var _selected_piece: TotemPiece = null


func _ready() -> void:
	_inventory_grid.piece_selected.connect(_on_piece_selected)
	_inventory_grid.new_base_pressed.connect(_on_new_base_pressed)
	_grid_panel.slot_clicked.connect(_on_slot_clicked)
	_crafting_bench.strike_pressed.connect(_on_strike_pressed)

	GameEvents.totem_inventory_changed.connect(_on_totem_inventory_changed)
	GameEvents.totem_placed.connect(_on_totem_grid_changed)
	GameEvents.totem_removed.connect(_on_totem_grid_changed)
	GameEvents.totem_synergy_changed.connect(_on_totem_grid_changed)

	_refresh_all()


func _refresh_all() -> void:
	_grid_panel.refresh_grid(GameState.totem_grid)
	_inventory_grid.refresh(GameState.totem_inventory)
	_crafting_bench.refresh(_selected_piece)


func _on_piece_selected(piece: TotemPiece) -> void:
	_selected_piece = piece
	_crafting_bench.refresh(piece)


func _on_new_base_pressed() -> void:
	var new_piece := TotemPiece.new()
	GameState.add_totem_to_inventory(new_piece)


func _on_slot_clicked(pos: Vector2i) -> void:
	if _selected_piece == null:
		var removed: TotemPiece = GameState.totem_grid.remove_piece(pos)
		if removed != null:
			GameState.add_totem_to_inventory(removed)
			GameEvents.totem_removed.emit(pos)
			GameEvents.totem_synergy_changed.emit(GameState.totem_grid.get_synergy_pairs())
		return

	if GameState.totem_grid.place_piece(pos, _selected_piece):
		GameState.remove_totem_from_inventory(_selected_piece)
		_selected_piece = null
		_crafting_bench.clear()
		GameEvents.totem_placed.emit(pos, GameState.totem_grid.get_piece(pos))
		GameEvents.totem_synergy_changed.emit(GameState.totem_grid.get_synergy_pairs())


func _on_strike_pressed() -> void:
	pass


func _on_totem_inventory_changed() -> void:
	_inventory_grid.refresh(GameState.totem_inventory)


func _on_totem_grid_changed(_arg1: Variant = null, _arg2: Variant = null) -> void:
	_grid_panel.refresh_grid(GameState.totem_grid)
