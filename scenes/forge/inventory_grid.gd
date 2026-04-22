extends VBoxContainer

signal item_selected(item: Item)

var active_slot: Tag_List.ItemSlot = Tag_List.ItemSlot.WEAPON

var _tab_buttons: Dictionary = {}

@onready var _slot_tabs: HBoxContainer = $SlotTabs
@onready var _item_count: Label = $ItemCount
@onready var _grid: GridContainer = $ScrollContainer/Grid


func _ready() -> void:
	_build_slot_tabs()
	GameEvents.inventory_changed.connect(_on_inventory_changed)
	GameEvents.equipment_changed.connect(_on_equipment_changed)
	refresh_grid()


func _build_slot_tabs() -> void:
	for slot_val in Tag.ALL_SLOTS:
		var btn := Button.new()
		var slot_label: String = Tag.slot_name(slot_val).capitalize()
		btn.text = slot_label
		btn.custom_minimum_size = Vector2(70, 30)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_tab_pressed.bind(slot_val))
		_slot_tabs.add_child(btn)
		_tab_buttons[slot_val] = btn
	_update_tab_highlight()


func _on_tab_pressed(slot_val: int) -> void:
	active_slot = slot_val as Tag_List.ItemSlot
	_update_tab_highlight()
	refresh_grid()


func _update_tab_highlight() -> void:
	for k in _tab_buttons:
		var btn: Button = _tab_buttons[k]
		if k == active_slot:
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
			btn.modulate = Color(1.2, 1.1, 0.8)
		else:
			btn.remove_theme_color_override("font_color")
			btn.modulate = Color.WHITE


func refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var items: Array = GameState.crafting_inventory.get(active_slot, [])
	_item_count.text = "%d items" % items.size()

	var new_base_btn := Button.new()
	new_base_btn.text = "+ New Base"
	new_base_btn.custom_minimum_size = Vector2(80, 50)
	new_base_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_base_btn.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	new_base_btn.pressed.connect(_on_new_base_pressed)
	_grid.add_child(new_base_btn)

	for item: Item in items:
		var tile := Button.new()
		var display_name: String = item.item_name
		if display_name.length() > 12:
			display_name = display_name.substr(0, 11) + "…"

		var tier_initial: String = Tag.material_name(item.material_tier).substr(0, 1)
		var equipped_item: Item = GameState.hero.get_equipped(item.slot)
		if equipped_item == item:
			display_name += " [EQ]"

		tile.text = "%s (%s)" % [display_name, tier_initial]
		tile.custom_minimum_size = Vector2(80, 50)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.modulate = item.get_rarity_color()
		tile.pressed.connect(_on_item_tile_pressed.bind(item))
		_grid.add_child(tile)


func _on_item_tile_pressed(item: Item) -> void:
	item_selected.emit(item)


func _on_new_base_pressed() -> void:
	var bases: Array[String] = ItemFactory.get_bases_for_slot(active_slot)
	if bases.is_empty():
		return
	var new_item: Item = ItemFactory.create_base(bases[0])
	if new_item == null:
		return
	GameState.add_item_to_inventory(new_item)


func _on_inventory_changed(slot: int) -> void:
	if slot == active_slot:
		refresh_grid()


func _on_equipment_changed(_slot: int, _item: Item) -> void:
	refresh_grid()
