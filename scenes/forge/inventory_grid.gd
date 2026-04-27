extends VBoxContainer

signal item_selected(item: HeroItem)

const NewBaseTile := preload("res://scenes/forge/new_base_tile.tscn")
const ItemTile := preload("res://scenes/forge/item_tile.tscn")

var active_slot: Tag_List.ItemSlot = Tag_List.ItemSlot.WEAPON

var _tab_buttons: Dictionary = {}

@onready var _slot_tabs: HBoxContainer = $SlotTabs
@onready var _item_count: Label = $ItemCount
@onready var _grid: GridContainer = $ScrollContainer/Grid


func _ready() -> void:
	_build_slot_tabs()
	GameEvents.inventory_changed.connect(_on_inventory_changed)
	GameEvents.equipment_changed.connect(_on_equipment_changed)
	GameEvents.item_crafted.connect(_on_item_crafted)
	refresh_grid()


func _build_slot_tabs() -> void:
	for slot_val in Tag.ALL_SLOTS:
		var btn := Button.new()
		var slot_label: String = Tag.slot_name(slot_val).capitalize()
		btn.text = slot_label
		btn.custom_minimum_size = Vector2(60, 22)
		btn.add_theme_font_size_override("font_size", 11)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
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


func switch_to_slot(slot_val: int) -> void:
	active_slot = slot_val as Tag_List.ItemSlot
	_update_tab_highlight()
	refresh_grid()



func refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
		_grid.remove_child(child)

	var items: Array = GameState.crafting_inventory.get(active_slot, [])
	_item_count.text = "%d items" % items.size()

	var new_base_tile: Node = NewBaseTile.instantiate()
	new_base_tile.active_slot = active_slot
	new_base_tile.new_base_requested.connect(_on_new_base_requested)
	_grid.add_child(new_base_tile)

	for item: HeroItem in items:
		var tile: Node = ItemTile.instantiate()
		tile.item = item
		tile.item_selected.connect(_on_item_tile_pressed)
		_grid.add_child(tile)


func _on_item_tile_pressed(item: HeroItem) -> void:
	item_selected.emit(item)


func _on_new_base_requested(slot: int) -> void:
	var bases: Array[String] = ItemFactory.get_bases_for_slot(slot)
	if bases.is_empty():
		return
	var new_item: HeroItem = ItemFactory.create_base(bases[0])
	if new_item == null:
		return
	GameState.add_item_to_inventory(new_item)


func _on_inventory_changed(slot: int) -> void:
	if slot == active_slot:
		refresh_grid()


func _on_equipment_changed(_slot: int, _item: HeroItem) -> void:
	refresh_grid()


func _on_item_crafted(item: HeroItem) -> void:
	if item.slot == active_slot:
		refresh_grid()
