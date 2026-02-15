class_name Currency extends Resource

var currency_name: String


## Validates whether this currency can be used on the item.
## Base implementation returns false (subclasses override).
func can_apply(item: Item) -> bool:
	return false


## Attempts to apply the currency to the item.
## Calls can_apply() first; if false, returns false (currency NOT consumed).
## If true, calls _do_apply(item) and returns true (currency consumed).
## This is the template method that enforces CRAFT-09 (consumed only on success).
func apply(item: Item) -> bool:
	if not can_apply(item):
		return false

	_do_apply(item)
	return true


## Virtual method for subclasses to implement actual behavior.
## Base does nothing.
func _do_apply(item: Item) -> void:
	pass


## Returns human-readable reason why can_apply() would fail.
## Base returns empty string.
func get_error_message(item: Item) -> String:
	return ""
