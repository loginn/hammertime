extends Node2D

signal new_game_started()

@onready var save_button: Button = $SaveButton
@onready var new_game_button: Button = $NewGameButton
@onready var export_button: Button = $ExportButton
@onready var import_text_edit: TextEdit = $ImportTextEdit
@onready var import_button: Button = $ImportButton

var _new_game_confirming: bool = false
var _import_confirming: bool = false
var spell_mode_toggle: CheckButton


func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	export_button.pressed.connect(_on_export_pressed)
	import_button.pressed.connect(_on_import_pressed)
	import_text_edit.text_changed.connect(_on_import_text_changed)
	import_button.disabled = true  # Disabled until text entered

	# Dev toggle for spell mode
	spell_mode_toggle = CheckButton.new()
	spell_mode_toggle.text = "Spell Mode (Dev)"
	spell_mode_toggle.button_pressed = GameState.hero.is_spell_user
	spell_mode_toggle.toggled.connect(_on_spell_mode_toggled)
	add_child(spell_mode_toggle)
	spell_mode_toggle.position = Vector2(10, 300)


func _on_save_pressed() -> void:
	SaveManager.save_game()
	GameEvents.save_completed.emit()


func _on_new_game_pressed() -> void:
	if not _new_game_confirming:
		# First click: change button to confirm
		_new_game_confirming = true
		new_game_button.text = "Are you sure?"
	else:
		# Second click: wipe and restart
		_new_game_confirming = false
		new_game_button.text = "New Game"
		SaveManager.delete_save()
		GameState.initialize_fresh_game()
		SaveManager.save_game()  # Save the fresh state immediately
		new_game_started.emit()


func _on_export_pressed() -> void:
	var save_string := SaveManager.export_save_string()
	DisplayServer.clipboard_set(save_string)
	GameEvents.export_completed.emit()


func _on_import_text_changed() -> void:
	import_button.disabled = import_text_edit.text.strip_edges().is_empty()
	# Reset confirmation state when text changes
	if _import_confirming:
		_import_confirming = false
		import_button.text = "Import Save"


func _on_import_pressed() -> void:
	if import_text_edit.text.strip_edges().is_empty():
		return
	if not _import_confirming:
		_import_confirming = true
		import_button.text = "Confirm overwrite?"
	else:
		_import_confirming = false
		import_button.text = "Import Save"
		_do_import()


func _on_spell_mode_toggled(toggled_on: bool) -> void:
	GameState.hero.is_spell_user = toggled_on
	GameState.hero.update_stats()


func _do_import() -> void:
	var result := SaveManager.import_save_string(import_text_edit.text)
	if result["success"]:
		# Full UI refresh via scene reload (same as New Game)
		new_game_started.emit()
	else:
		# Show generic error toast — red-tinted
		GameEvents.import_failed.emit()


func reset_state() -> void:
	_new_game_confirming = false
	new_game_button.text = "New Game"
	_import_confirming = false
	import_button.text = "Import Save"
	import_text_edit.text = ""
	import_button.disabled = true
	spell_mode_toggle.button_pressed = GameState.hero.is_spell_user
