extends Label


func _ready() -> void:
	visible = false
	GameEvents.save_completed.connect(_on_save_completed)
	GameEvents.save_failed.connect(_on_save_failed)
	GameEvents.export_completed.connect(_on_export_completed)
	GameEvents.import_failed.connect(_on_import_failed)

	# Check for corrupted save on startup
	if GameState.save_was_corrupted:
		show_toast("Save could not be loaded", Color(1.0, 0.4, 0.4))
		GameState.save_was_corrupted = false

	# Check for successful import (flag survives scene reload)
	if GameState.import_just_completed:
		show_toast("Save imported!", Color(0.4, 1.0, 0.4))
		GameState.import_just_completed = false


func _on_save_completed() -> void:
	show_toast("Saved")


func _on_save_failed() -> void:
	show_toast("Save failed", Color(1.0, 0.4, 0.4))


func _on_export_completed() -> void:
	show_toast("Copied to clipboard!", Color(0.4, 1.0, 0.4))


func _on_import_failed() -> void:
	show_toast("Invalid save string. Please check and try again.", Color(1.0, 0.4, 0.4))


func show_toast(message: String, color: Color = Color.WHITE) -> void:
	text = message
	modulate = Color(color.r, color.g, color.b, 1.0)
	visible = true
	var tween := create_tween()
	tween.tween_interval(1.0)  # Hold visible for 1 second
	tween.tween_property(self, "modulate:a", 0.0, 0.5)  # Fade out over 0.5 seconds
	tween.tween_callback(func(): visible = false)
