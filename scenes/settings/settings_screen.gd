extends Control

@onready var _confirm_dialog: ConfirmationDialog = %ConfirmDialog
@onready var _btn_save: Button = %BtnSaveGame
@onready var _btn_new_game: Button = %BtnNewGame
@onready var _btn_export: Button = %BtnExportSave

const IRON_KIT: Array[String] = [
	"iron_shortsword", "iron_vest", "iron_cap", "iron_sandals", "iron_band"
]

const STEEL_KIT: Array[String] = [
	"steel_longsword", "steel_chainmail", "steel_helm", "steel_greaves", "steel_signet"
]

const CURRENCY_GRANT: Dictionary = {
	"tack": 100, "tuning": 100, "forge": 100, "grand": 100,
	"runic": 100, "claw": 100,
}


func _ready() -> void:
	_confirm_dialog.confirmed.connect(_on_new_game_confirmed)
	_btn_new_game.pressed.connect(_show_new_game_dialog)
	_btn_save.pressed.connect(_on_save_pressed)
	_btn_export.pressed.connect(_on_export_pressed)


func _on_save_pressed() -> void:
	pass


func _on_export_pressed() -> void:
	pass


func _grant_materials() -> void:
	GameState.add_currencies({"iron": 50, "steel": 10, "ash": 20, "oak": 10})
	for key: String in ["iron", "steel", "ash", "oak"]:
		GameEvents.currency_changed.emit(key, GameState.currency_counts[key])


func _grant_currencies() -> void:
	GameState.add_currencies(CURRENCY_GRANT)


func _grant_iron_kit() -> void:
	GameState.add_currencies({"iron": IRON_KIT.size()})
	for base_id: String in IRON_KIT:
		var item: HeroItem = ItemFactory.create_base(base_id)
		if item:
			GameState.add_item_to_inventory(item)


func _grant_steel_kit() -> void:
	GameState.add_currencies({"steel": STEEL_KIT.size()})
	for base_id: String in STEEL_KIT:
		var item: HeroItem = ItemFactory.create_base(base_id)
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
