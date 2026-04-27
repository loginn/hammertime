class_name ScourHammer extends Currency
## Scour: Strip all affixes, revert to Normal rarity


func _init() -> void:
	currency_name = "Scour Hammer"
	verb = "Scour"


func can_apply(item: HeroItem) -> bool:
	return item.rarity != CraftableItem.Rarity.NORMAL


func get_error_message(item: HeroItem) -> String:
	if item.rarity == CraftableItem.Rarity.NORMAL:
		return "Item is already Normal rarity"
	return ""


func _do_apply(item: HeroItem) -> void:
	item.prefixes.clear()
	item.suffixes.clear()
	item.rarity = CraftableItem.Rarity.NORMAL
	item.update_value()
