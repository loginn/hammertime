extends Control


func _ready() -> void:
	GameEvents.prestige_completed.connect(_on_prestige_completed)


func _on_prestige_completed() -> void:
	pass
