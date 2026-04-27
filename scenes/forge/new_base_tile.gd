extends Button

signal new_base_requested(slot: int)

var active_slot: int = 0


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	new_base_requested.emit(active_slot)
