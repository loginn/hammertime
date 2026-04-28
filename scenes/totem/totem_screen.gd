extends Control

@onready var _hammer_rail: Node = %HammerRail
@onready var _grid_panel: PanelContainer = %TotemGridPanel
@onready var _crafting_bench: HBoxContainer = %TotemCraftingBench
@onready var _inventory_grid: VBoxContainer = %TotemInventoryGrid

var _selected_piece: TotemPiece = null
var _tier_picker: PanelContainer = null


func _ready() -> void:
	_inventory_grid.piece_selected.connect(_on_piece_selected)
	_inventory_grid.new_base_pressed.connect(_on_new_base_pressed)
	_grid_panel.slot_clicked.connect(_on_slot_clicked)
	_crafting_bench.strike_pressed.connect(_on_strike_pressed)

	GameEvents.totem_inventory_changed.connect(_on_totem_inventory_changed)
	GameEvents.totem_placed.connect(_on_totem_grid_changed)
	GameEvents.totem_removed.connect(_on_totem_grid_changed)
	GameEvents.totem_synergy_changed.connect(_on_totem_grid_changed)

	_build_tier_picker()
	_refresh_all()


func _build_tier_picker() -> void:
	_tier_picker = PanelContainer.new()
	_tier_picker.visible = false
	_tier_picker.z_index = 10

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = "Choose Material"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var ash_btn := Button.new()
	ash_btn.text = "Ash\n(%d wood)" % BalanceConfig.BASE_TOTEM_ASH_COST
	ash_btn.custom_minimum_size = Vector2(90, 52)
	ash_btn.pressed.connect(_on_tier_selected.bind(Tag_List.MaterialTier.ASH))

	var oak_btn := Button.new()
	oak_btn.text = "Oak\n(%d wood)" % BalanceConfig.BASE_TOTEM_OAK_COST
	oak_btn.custom_minimum_size = Vector2(90, 52)
	oak_btn.pressed.connect(_on_tier_selected.bind(Tag_List.MaterialTier.OAK))

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(60, 52)
	cancel_btn.pressed.connect(func() -> void: _tier_picker.visible = false)

	hbox.add_child(ash_btn)
	hbox.add_child(oak_btn)
	hbox.add_child(cancel_btn)
	vbox.add_child(hbox)
	_tier_picker.add_child(vbox)
	add_child(_tier_picker)
	_tier_picker.set_anchors_preset(Control.PRESET_CENTER)


func _refresh_all() -> void:
	_grid_panel.refresh_grid(GameState.totem_grid)
	_inventory_grid.refresh(GameState.totem_inventory)
	_crafting_bench.refresh(_selected_piece)


func _on_piece_selected(piece: TotemPiece) -> void:
	_selected_piece = piece
	_crafting_bench.refresh(piece)


func _on_new_base_pressed() -> void:
	_tier_picker.visible = true


func _on_tier_selected(tier: Tag_List.MaterialTier) -> void:
	_tier_picker.visible = false
	if not TotemPieceFactory.can_afford(tier):
		push_warning("TotemScreen: cannot afford tier %d" % tier)
		return
	var piece := TotemPieceFactory.create_base(tier)
	if piece == null:
		return
	GameState.add_totem_to_inventory(piece)


func _on_slot_clicked(pos: Vector2i) -> void:
	if _selected_piece == null:
		var removed: TotemPiece = GameState.totem_grid.remove_piece(pos)
		if removed != null:
			GameState.add_totem_to_inventory(removed)
			GameEvents.totem_removed.emit(pos, removed)
			GameEvents.totem_synergy_changed.emit(GameState.totem_grid.get_synergy_pairs())
		return

	if GameState.totem_grid.place_piece(pos, _selected_piece):
		GameState.remove_totem_from_inventory(_selected_piece)
		var placed := _selected_piece
		_selected_piece = null
		_crafting_bench.clear()
		GameEvents.totem_placed.emit(pos, placed)
		GameEvents.totem_synergy_changed.emit(GameState.totem_grid.get_synergy_pairs())


func _on_strike_pressed() -> void:
	if _selected_piece == null:
		return
	var hammer_key: String = _hammer_rail.get_selected_key()
	if hammer_key.is_empty():
		return
	var hammer: Currency = GameState.get_currency_instance(hammer_key)
	if hammer == null:
		return
	if hammer.apply(_selected_piece):
		_selected_piece.recompute_deity_tag()
		_crafting_bench.refresh(_selected_piece)
		# Deity tag may have changed — re-check synergies if piece is on the grid
		if _is_piece_in_grid(_selected_piece):
			GameEvents.totem_synergy_changed.emit(GameState.totem_grid.get_synergy_pairs())


func _is_piece_in_grid(piece: TotemPiece) -> bool:
	for pos: Vector2i in GameState.totem_grid.slots:
		if GameState.totem_grid.slots[pos] == piece:
			return true
	return false


func _on_totem_inventory_changed() -> void:
	_inventory_grid.refresh(GameState.totem_inventory)


func _on_totem_grid_changed(_arg1: Variant = null, _arg2: Variant = null) -> void:
	_grid_panel.refresh_grid(GameState.totem_grid)
