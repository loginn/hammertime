extends HBoxContainer

const MAX_AFFIX_SLOTS := 3

@onready var _item_name_label: Label = $MarginContainer3/BadgeVBox/ItemName
@onready var _material_label: Label = $MarginContainer3/BadgeVBox/MaterialTier
@onready var _empty_label: Label = $MarginContainer3/BadgeVBox/ItemBadge/EmptyLabel
@onready var _item_badge: PanelContainer = $MarginContainer3/BadgeVBox/ItemBadge
@onready var _prefix_rail: VBoxContainer = $MarginContainer/PrefixRail
@onready var _suffix_rail: VBoxContainer = $MarginContainer2/SuffixRail
@onready var _stat_readout: VBoxContainer = %StatReadout
@onready var _primary_stat: Label = %PrimaryStat
@onready var _primary_label: Label = %PrimaryLabel
@onready var _prefix_count: Label = %PrefixCount
@onready var _suffix_count: Label = %SuffixCount

signal strike_pressed


func _ready() -> void:
	_item_badge.gui_input.connect(_on_badge_gui_input)
	refresh(null)


func _on_badge_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		strike_pressed.emit()


func refresh(item: Item) -> void:
	if item == null:
		_item_name_label.text = ""
		_item_name_label.visible = false
		_material_label.text = ""
		_material_label.visible = false
		_empty_label.text = "No item on bench"
		_empty_label.visible = true
		_stat_readout.visible = false
		_prefix_count.text = "0 / 0"
		_suffix_count.text = "0 / 0"
		_populate_affix_rail(_prefix_rail, [], MAX_AFFIX_SLOTS, "PREFIX")
		_populate_affix_rail(_suffix_rail, [], MAX_AFFIX_SLOTS, "SUFFIX")
		return

	_empty_label.visible = false
	_item_name_label.visible = true
	_material_label.visible = true

	_item_name_label.text = item.item_name
	_item_name_label.add_theme_color_override("font_color", item.get_rarity_color())

	var tier_name: String = Tag.material_name(item.material_tier)
	var base_name: String = item.base_id.replace("_", " ").capitalize()
	_material_label.text = "%s · %s" % [tier_name.to_upper(), base_name.to_upper()]

	item.update_value()
	_update_stat_readout(item)

	_prefix_count.text = "%d / %d" % [item.prefixes.size(), item.max_prefixes()]
	_suffix_count.text = "%d / %d" % [item.suffixes.size(), item.max_suffixes()]

	_populate_affix_rail(_prefix_rail, item.prefixes, MAX_AFFIX_SLOTS, "PREFIX")
	_populate_affix_rail(_suffix_rail, item.suffixes, MAX_AFFIX_SLOTS, "SUFFIX")


func _update_stat_readout(item: Item) -> void:
	_stat_readout.visible = true

	if item.is_weapon_slot():
		_primary_stat.text = "%.1f" % item.dps
		_primary_label.text = "DPS · %.2f/s" % item.base_attack_speed
	elif item.is_defense_slot():
		if item.computed_armor > 0:
			_primary_stat.text = str(item.computed_armor)
			_primary_label.text = "ARMOR"
		elif item.computed_evasion > 0:
			_primary_stat.text = str(item.computed_evasion)
			_primary_label.text = "EVASION"
		elif item.computed_energy_shield > 0:
			_primary_stat.text = str(item.computed_energy_shield)
			_primary_label.text = "ENERGY SHIELD"
		else:
			_primary_stat.text = str(item.computed_health)
			_primary_label.text = "LIFE"
	else:
		_primary_stat.text = ""
		_primary_label.text = ""
		_stat_readout.visible = false


func _populate_affix_rail(container: VBoxContainer, affixes: Array, max_slots: int, label_prefix: String) -> void:
	for child in container.get_children():
		if child.name == "RailHeader" or child.name == "PrefixCount" or child.name == "SuffixCount":
			continue
		child.queue_free()
		container.remove_child(child)

	var is_prefix := (label_prefix == "PREFIX")
	var affix_color := Color(0.55, 0.65, 0.85) if is_prefix else Color(0.55, 0.85, 0.65)

	for i in range(max_slots):
		var slot_label := Label.new()
		slot_label.add_theme_font_size_override("font_size", 11)
		if i < affixes.size():
			var affix: Affix = affixes[i]
			slot_label.text = "T%d %s: %d" % [affix.tier, affix.affix_name, affix.value]
			slot_label.add_theme_color_override("font_color", affix_color)
		else:
			slot_label.text = "✦ OPEN %s ✦" % label_prefix
			slot_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
			slot_label.add_theme_font_size_override("font_size", 9)
		container.add_child(slot_label)
