extends Button

signal item_selected(item: Item)

var item: Item = null


func _ready() -> void:
	if item != null:
		_setup()
	pressed.connect(func(): item_selected.emit(item))


func _setup() -> void:
	var rarity_color: Color = item.get_rarity_color()

	# Duplicate styles so each tile has independent color values
	var normal_style := (get_theme_stylebox("normal") as StyleBoxFlat).duplicate()
	var hover_style := (get_theme_stylebox("hover") as StyleBoxFlat).duplicate()
	var pressed_style := (get_theme_stylebox("pressed") as StyleBoxFlat).duplicate()

	normal_style.border_color = rarity_color
	hover_style.border_color = rarity_color.lightened(0.15)
	pressed_style.border_color = rarity_color.lightened(0.3)

	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)

	%ItemName.text = item.item_name
	%ItemName.add_theme_color_override("font_color", item.get_rarity_color())

	var equipped_item: Item = GameState.hero.get_equipped(item.slot)
	%EqBadge.visible = (equipped_item == item)

	%MaterialLabel.text = Tag.material_name(item.material_tier).to_upper()
	%TierLabel.text = "T%d" % (item.material_tier + 1)
