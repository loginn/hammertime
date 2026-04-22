extends Control

var active_hammer_key: String = ""

@onready var _hammer_rail: VBoxContainer = %HammerRail
@onready var _crafting_bench: VBoxContainer = %CraftingBench
@onready var _inventory_grid: VBoxContainer = %InventoryGrid

var _strike_button: Button


func _ready() -> void:
	_strike_button = _crafting_bench.get_node("StrikeButton")
	GameEvents.prestige_completed.connect(_on_prestige_completed)
	_hammer_rail.hammer_selected.connect(_on_hammer_selected)
	_strike_button.pressed.connect(_on_strike_pressed)
	GameEvents.item_crafted.connect(_on_item_crafted)
	_inventory_grid.item_selected.connect(_on_item_selected)
	_crafting_bench.equip_pressed.connect(_on_equip_pressed)
	_crafting_bench.melt_pressed.connect(_on_melt_pressed)
	GameEvents.equipment_changed.connect(_on_equipment_changed)

	_refresh_bench()
	_update_strike_button_state()


func set_bench_item(item: Item) -> void:
	GameState.crafting_bench_item = item
	_refresh_bench()
	_update_strike_button_state()


func _on_item_selected(item: Item) -> void:
	set_bench_item(item)


func _on_hammer_selected(key: String) -> void:
	active_hammer_key = key
	_update_strike_button_state()


func _on_strike_pressed() -> void:
	var item: Item = GameState.crafting_bench_item
	if item == null:
		return
	if active_hammer_key == "":
		return

	var count: int = GameState.currency_counts.get(active_hammer_key, 0)
	if count <= 0:
		_crafting_bench.show_error("No %s remaining" % GameState.CURRENCY_DISPLAY_NAMES.get(active_hammer_key, active_hammer_key))
		return

	var currency: Currency = GameState.get_currency_instance(active_hammer_key)
	if currency == null:
		push_warning("Unrecognized currency key: %s" % active_hammer_key)
		return

	if not currency.can_apply(item):
		var error_msg: String = currency.get_error_message(item)
		_crafting_bench.show_error(error_msg)
		return

	GameState.spend_currency(active_hammer_key)
	currency.apply(item)
	item.update_value()
	_crafting_bench.clear_error()
	GameEvents.item_crafted.emit(item)


func _on_equip_pressed() -> void:
	var item: Item = GameState.crafting_bench_item
	if item == null:
		return
	var currently_equipped: Item = GameState.hero.get_equipped(item.slot)
	if currently_equipped == item:
		return
	GameState.hero.equip_item(item)
	GameEvents.equipment_changed.emit(item.slot, item)


func _on_melt_pressed() -> void:
	var item: Item = GameState.crafting_bench_item
	if item == null:
		return
	var equipped: Item = GameState.hero.get_equipped(item.slot)
	if equipped == item:
		return
	GameState.remove_item_from_inventory(item)
	GameEvents.item_melted.emit(item)
	set_bench_item(null)


func _on_item_crafted(_item: Item) -> void:
	_refresh_bench()
	_update_strike_button_state()


func _on_equipment_changed(_slot: int, _item: Item) -> void:
	_refresh_bench()


func _refresh_bench() -> void:
	var item: Item = GameState.crafting_bench_item
	_crafting_bench.refresh(item)
	_crafting_bench.update_equip_melt_state(item)


func _update_strike_button_state() -> void:
	var item: Item = GameState.crafting_bench_item
	if item == null or active_hammer_key == "":
		_strike_button.disabled = true
		return

	var count: int = GameState.currency_counts.get(active_hammer_key, 0)
	_strike_button.disabled = (count <= 0)


func _on_prestige_completed() -> void:
	pass
