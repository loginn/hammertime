class_name ScourHammer extends Currency
## Scour: Strip all affixes, revert to Normal rarity


func _init() -> void:
	currency_name = "Scour Hammer"
	verb = "Scour"


func can_apply(item: Item) -> bool:
	return item.rarity != Item.Rarity.NORMAL


func get_error_message(item: Item) -> String:
	if item.rarity == Item.Rarity.NORMAL:
		return "Item is already Normal rarity"
	return ""


func _do_apply(item: Item) -> void:
	item.prefixes.clear()
	item.suffixes.clear()
	item.rarity = Item.Rarity.NORMAL
	item.update_value()
