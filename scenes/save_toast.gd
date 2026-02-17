extends Label


func _ready() -> void:
	visible = false
	GameEvents.save_completed.connect(_on_save_completed)
	GameEvents.save_failed.connect(_on_save_failed)

	# Check for corrupted save on startup
	if GameState.save_was_corrupted:
		show_toast("Save could not be loaded")
		GameState.save_was_corrupted = false


func _on_save_completed() -> void:
	show_toast("Saved")


func _on_save_failed() -> void:
	show_toast("Save failed")


func show_toast(message: String) -> void:
	text = message
	modulate.a = 1.0
	visible = true
	var tween := create_tween()
	tween.tween_interval(1.0)  # Hold visible for 1 second
	tween.tween_property(self, "modulate:a", 0.0, 0.5)  # Fade out over 0.5 seconds
	tween.tween_callback(func(): visible = false)
