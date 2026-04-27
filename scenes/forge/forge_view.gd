extends Control

var active_hammer_key: String = ""

@onready var _hammer_rail: VBoxContainer = %HammerRail
@onready var _crafting_bench = %CraftingBench
@onready var _inventory_grid: VBoxContainer = %InventoryGrid
@onready var _hero_panel: VBoxContainer = %HeroPanel


func _ready() -> void:
	GameEvents.prestige_completed.connect(_on_prestige_completed)
	_hammer_rail.hammer_selected.connect(_on_hammer_selected)
	_crafting_bench.strike_pressed.connect(_on_strike_pressed)
	GameEvents.item_crafted.connect(_on_item_crafted)
	_inventory_grid.item_selected.connect(_on_item_selected)
	GameEvents.equipment_changed.connect(_on_equipment_changed)
	_hero_panel.slot_tab_requested.connect(_on_slot_tab_requested)

	_refresh_bench()


func set_bench_item(item: Item) -> void:
	GameState.crafting_bench_item = item
	_refresh_bench()
	_hero_panel.show_deltas(item)
	_hero_panel.update_bench_item(item)


func _on_item_selected(item: Item) -> void:
	set_bench_item(item)


func _on_hammer_selected(key: String) -> void:
	active_hammer_key = key


func _on_strike_pressed() -> void:
	var item: Item = GameState.crafting_bench_item
	if item == null:
		return
	if active_hammer_key == "":
		return

	var count: int = GameState.currency_counts.get(active_hammer_key, 0)
	if count <= 0:
		return

	var currency: Currency = GameState.get_currency_instance(active_hammer_key)
	if currency == null:
		push_warning("Unrecognized currency key: %s" % active_hammer_key)
		return

	if not currency.can_apply(item):
		return

	GameState.spend_currency(active_hammer_key)
	currency.apply(item)
	item.update_value()
	GameEvents.item_crafted.emit(item)


func _on_item_crafted(_item: Item) -> void:
	_refresh_bench()


func _on_equipment_changed(_slot: int, _item: Item) -> void:
	_refresh_bench()
	_hero_panel.update_bench_item(GameState.crafting_bench_item)


func _refresh_bench() -> void:
	_crafting_bench.refresh(GameState.crafting_bench_item)


func _on_slot_tab_requested(slot: int) -> void:
	_inventory_grid.switch_to_slot(slot)


func _on_prestige_completed() -> void:
	set_bench_item(null)
	_inventory_grid.refresh_grid()
	_hero_panel.refresh()
