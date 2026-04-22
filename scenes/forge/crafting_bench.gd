extends VBoxContainer

const MAX_AFFIX_SLOTS := 3

@onready var _item_name_label: Label = $BenchArea/ItemBadge/BadgeVBox/ItemName
@onready var _material_label: Label = $BenchArea/ItemBadge/BadgeVBox/MaterialTier
@onready var _base_label: Label = $BenchArea/ItemBadge/BadgeVBox/BaseName
@onready var _prefix_rail: VBoxContainer = $BenchArea/PrefixRail
@onready var _suffix_rail: VBoxContainer = $BenchArea/SuffixRail
@onready var _strike_button: Button = $StrikeButton
@onready var _error_label: Label = $ErrorFeedback
@onready var _empty_label: Label = $BenchArea/ItemBadge/BadgeVBox/EmptyLabel


func _ready() -> void:
	_strike_button.disabled = true
	_error_label.text = ""
	_error_label.visible = false
	refresh(null)


func refresh(item: Item) -> void:
	_error_label.text = ""
	_error_label.visible = false

	if item == null:
		_item_name_label.text = ""
		_item_name_label.visible = false
		_material_label.text = ""
		_material_label.visible = false
		_base_label.text = ""
		_base_label.visible = false
		_empty_label.text = "No item on bench"
		_empty_label.visible = true
		_populate_affix_rail(_prefix_rail, [], MAX_AFFIX_SLOTS, "PREFIX")
		_populate_affix_rail(_suffix_rail, [], MAX_AFFIX_SLOTS, "SUFFIX")
		_update_strike_enabled(null)
		return

	_empty_label.visible = false
	_item_name_label.visible = true
	_material_label.visible = true
	_base_label.visible = true

	_item_name_label.text = item.item_name
	_item_name_label.add_theme_color_override("font_color", item.get_rarity_color())

	var tier_name: String = Tag.material_name(item.material_tier)
	_material_label.text = tier_name

	_base_label.text = item.base_id.replace("_", " ").capitalize()

	_populate_affix_rail(_prefix_rail, item.prefixes, MAX_AFFIX_SLOTS, "PREFIX")
	_populate_affix_rail(_suffix_rail, item.suffixes, MAX_AFFIX_SLOTS, "SUFFIX")


func _populate_affix_rail(container: VBoxContainer, affixes: Array, max_slots: int, label_prefix: String) -> void:
	for child in container.get_children():
		if child.name != "RailHeader":
			child.queue_free()

	for i in range(max_slots):
		var slot_label := Label.new()
		slot_label.add_theme_font_size_override("font_size", 11)
		if i < affixes.size():
			var affix: Affix = affixes[i]
			slot_label.text = "%s T%d: %d" % [affix.affix_name, affix.tier, affix.value]
			slot_label.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
		else:
			slot_label.text = "OPEN %s" % label_prefix
			slot_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		container.add_child(slot_label)


func _update_strike_enabled(item: Item) -> void:
	_strike_button.disabled = (item == null)


func set_strike_enabled(enabled: bool) -> void:
	_strike_button.disabled = not enabled


func show_error(message: String) -> void:
	_error_label.text = message
	_error_label.visible = true


func clear_error() -> void:
	_error_label.text = ""
	_error_label.visible = false
