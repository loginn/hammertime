extends PanelContainer

signal slot_clicked(pos: Vector2i)

@onready var _slot_00: PanelContainer = %Slot00
@onready var _slot_10: PanelContainer = %Slot10
@onready var _slot_01: PanelContainer = %Slot01
@onready var _slot_11: PanelContainer = %Slot11

var _slots: Dictionary = {}


func _ready() -> void:
	_slots[Vector2i(0, 0)] = _slot_00
	_slots[Vector2i(1, 0)] = _slot_10
	_slots[Vector2i(0, 1)] = _slot_01
	_slots[Vector2i(1, 1)] = _slot_11

	for pos: Vector2i in _slots:
		var s: PanelContainer = _slots[pos]
		s.grid_pos = pos
		s.slot_clicked.connect(_on_slot_clicked)


func _on_slot_clicked(pos: Vector2i) -> void:
	slot_clicked.emit(pos)


func refresh_grid(grid: TotemGrid) -> void:
	var synergies: Array[Dictionary] = grid.get_synergy_pairs()
	var synergy_positions: Array = []
	for pair in synergies:
		if pair["pos_a"] not in synergy_positions:
			synergy_positions.append(pair["pos_a"])
		if pair["pos_b"] not in synergy_positions:
			synergy_positions.append(pair["pos_b"])

	for pos: Vector2i in _slots:
		var s: PanelContainer = _slots[pos]
		var piece: TotemPiece = grid.get_piece(pos)
		s.refresh(piece, pos in synergy_positions)
