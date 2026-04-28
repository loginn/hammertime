extends HBoxContainer

signal strike_pressed

const MAX_AFFIX_SLOTS := 3

@onready var _prefix_rail: VBoxContainer = $MarginLeft/PrefixRail
@onready var _suffix_rail: VBoxContainer = $MarginRight/SuffixRail
@onready var _item_badge: PanelContainer = $MarginCenter/BadgeVBox/ItemBadge
@onready var _empty_label: Label = $MarginCenter/BadgeVBox/ItemBadge/EmptyLabel
@onready var _item_name_label: Label = $MarginCenter/BadgeVBox/ItemName
@onready var _deity_label: Label = $MarginCenter/BadgeVBox/DeityTag
@onready var _material_label: Label = $MarginCenter/BadgeVBox/MaterialTier
@onready var _modifier_summary: Label = %ModifierSummary
@onready var _prefix_count: Label = %PrefixCount
@onready var _suffix_count: Label = %SuffixCount


func _ready() -> void:
	_item_badge.gui_input.connect(_on_badge_gui_input)
	refresh(null)


func _on_badge_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		strike_pressed.emit()


func refresh(piece: TotemPiece) -> void:
	if piece == null:
		_item_name_label.visible = false
		_deity_label.visible = false
		_material_label.visible = false
		_modifier_summary.visible = false
		_empty_label.visible = true
		_prefix_count.text = "0 / 0"
		_suffix_count.text = "0 / 0"
		_populate_affix_rail(_prefix_rail, [], MAX_AFFIX_SLOTS, "PREFIX")
		_populate_affix_rail(_suffix_rail, [], MAX_AFFIX_SLOTS, "SUFFIX")
		return

	_empty_label.visible = false
	_item_name_label.visible = true
	_item_name_label.text = piece.item_name
	_item_name_label.add_theme_color_override("font_color", piece.get_rarity_color())

	if not piece.deity_tag.is_empty():
		_deity_label.text = piece.deity_tag.replace("_", " ").capitalize()
		_deity_label.visible = true
	else:
		_deity_label.visible = false

	var tier_name: String = Tag.material_name(piece.material_tier)
	_material_label.text = tier_name.to_upper()
	_material_label.visible = true

	var mods: Dictionary = piece.get_expedition_modifiers()
	var mod_parts: Array[String] = []
	if mods.get("drop_quantity", 0) != 0:
		mod_parts.append("+%d qty" % mods["drop_quantity"])
	if mods.get("drop_quality", 0) != 0:
		mod_parts.append("+%d%% qual" % mods["drop_quality"])
	if mods.get("duration_reduction", 0) != 0:
		mod_parts.append("-%d%% dur" % mods["duration_reduction"])
	if mods.get("hammer_chance", 0) != 0:
		mod_parts.append("+%d%% hammer" % mods["hammer_chance"])
	_modifier_summary.text = " · ".join(mod_parts) if mod_parts.size() > 0 else "No mods"
	_modifier_summary.visible = true

	_prefix_count.text = "%d / %d" % [piece.prefixes.size(), piece.max_prefixes()]
	_suffix_count.text = "%d / %d" % [piece.suffixes.size(), piece.max_suffixes()]
	_populate_affix_rail(_prefix_rail, piece.prefixes, MAX_AFFIX_SLOTS, "PREFIX")
	_populate_affix_rail(_suffix_rail, piece.suffixes, MAX_AFFIX_SLOTS, "SUFFIX")


func clear() -> void:
	refresh(null)


func _populate_affix_rail(container: VBoxContainer, affixes: Array, max_slots: int, label_prefix: String) -> void:
	for child in container.get_children():
		if child.name in ["RailHeader", "PrefixCount", "SuffixCount"]:
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
