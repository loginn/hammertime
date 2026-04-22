extends Control

@onready var _confirm_dialog: ConfirmationDialog = %ConfirmDialog

const IRON_KIT: Array[String] = [
	"iron_shortsword", "iron_vest", "iron_cap", "iron_sandals", "iron_band"
]

const STEEL_KIT: Array[String] = [
	"steel_longsword", "steel_chainmail", "steel_helm", "steel_greaves", "steel_signet"
]

const CURRENCY_GRANT: Dictionary = {
	"tack": 100, "tuning": 100, "forge": 100, "grand": 100,
	"runic": 100, "claw": 100, "scour": 100,
}


func _ready() -> void:
	_confirm_dialog.confirmed.connect(_on_new_game_confirmed)


func _grant_currencies() -> void:
	GameState.add_currencies(CURRENCY_GRANT)
	for key: String in GameState.CURRENCY_KEYS:
		GameEvents.currency_changed.emit(key, GameState.currency_counts[key])


func _grant_iron_kit() -> void:
	for base_id: String in IRON_KIT:
		var item: Item = ItemFactory.create_base(base_id)
		if item:
			GameState.add_item_to_inventory(item)


func _grant_steel_kit() -> void:
	for base_id: String in STEEL_KIT:
		var item: Item = ItemFactory.create_base(base_id)
		if item:
			GameState.add_item_to_inventory(item)


func _add_prestige() -> void:
	PrestigeManager.prestige_count += 1
	GameEvents.prestige_completed.emit()


func _reset_prestige() -> void:
	PrestigeManager.prestige_count = 0
	GameEvents.prestige_completed.emit()


func _wipe_run() -> void:
	GameState.wipe_run_state()
	for key: String in GameState.CURRENCY_KEYS:
		GameEvents.currency_changed.emit(key, GameState.currency_counts[key])
	for slot: int in Tag_List.ALL_SLOTS:
		GameEvents.inventory_changed.emit(slot)


func _show_new_game_dialog() -> void:
	_confirm_dialog.dialog_text = "Reset ALL progress?\n\nThis will erase:\n- All currencies\n- All inventory items\n- Hero equipment\n- Prestige level"
	_confirm_dialog.popup_centered()


func _on_new_game_confirmed() -> void:
	GameState.initialize_fresh_game()
	PrestigeManager.prestige_count = 0
	GameEvents.prestige_completed.emit()
	for key: String in GameState.CURRENCY_KEYS:
		GameEvents.currency_changed.emit(key, GameState.currency_counts[key])
	for slot: int in Tag_List.ALL_SLOTS:
		GameEvents.inventory_changed.emit(slot)
