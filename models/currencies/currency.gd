class_name Currency extends Resource

var currency_name: String
var verb: String


func can_apply(item: Item) -> bool:
	return false


func apply(item: Item) -> bool:
	if not can_apply(item):
		return false
	_do_apply(item)
	return true


func _do_apply(item: Item) -> void:
	pass


func get_error_message(item: Item) -> String:
	return ""
