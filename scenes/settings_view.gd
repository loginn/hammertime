extends Node2D

signal new_game_started()

@onready var save_button: Button = $SaveButton
@onready var new_game_button: Button = $NewGameButton

var _new_game_confirming: bool = false


func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)


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


func reset_state() -> void:
	_new_game_confirming = false
	new_game_button.text = "New Game"
