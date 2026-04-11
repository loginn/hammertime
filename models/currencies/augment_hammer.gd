class_name AugmentHammer extends Currency


func _init() -> void:
	currency_name = "Augment Hammer"


## Augment adds one mod to a Magic item that still has room for another affix.
func can_apply(item: Item) -> bool:
	if item.rarity != Item.Rarity.MAGIC:
		return false
	var has_room: bool = (
		len(item.prefixes) < item.max_prefixes()
		or len(item.suffixes) < item.max_suffixes()
	)
	return has_room


func get_error_message(item: Item) -> String:
	if item.rarity != Item.Rarity.MAGIC:
		return "Augment Hammer can only be used on Magic items"
	if len(item.prefixes) >= item.max_prefixes() and len(item.suffixes) >= item.max_suffixes():
		return "Magic item has no room for another mod"
	return ""


## Adds exactly one mod (prefix or suffix, 50/50 with fallback to the other slot).
func _do_apply(item: Item) -> void:
	var choose_prefix = randi_range(0, 1) == 0
	if choose_prefix:
		if not item.add_prefix():
			item.add_suffix()
	else:
		if not item.add_suffix():
			item.add_prefix()

	item.update_value()
