extends Label

## Self-animating floating label for damage numbers and dodge text.
## Drifts upward and fades out, then auto-frees. Created by gameplay_view
## signal handlers and parented to FloatingTextContainer.


func show_damage(value: int, is_crit: bool) -> void:
	text = str(value)

	if is_crit:
		add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Gold
		pivot_offset = size / 2.0
		scale = Vector2(1.5, 1.5)
	else:
		add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White
		scale = Vector2(1.0, 1.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 60.0, 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)

	await tween.finished
	queue_free()


func show_dodge() -> void:
	text = "DODGE"
	add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White
	scale = Vector2(1.0, 1.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 40.0, 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)

	await tween.finished
	queue_free()
