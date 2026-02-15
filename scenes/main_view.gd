extends Node2D

var current_view: String = "crafting"
@onready var crafting_view: Node2D = $CraftingView
@onready var hero_view: Node2D = $HeroView
@onready var gameplay_view: Node2D = $GameplayView
@onready var crafting_button: Button = $NavigationPanel/CraftingButton
@onready var hero_button: Button = $NavigationPanel/HeroButton
@onready var gameplay_button: Button = $NavigationPanel/GameplayButton


func _ready() -> void:
	# Connect navigation buttons
	crafting_button.pressed.connect(_on_crafting_button_pressed)
	hero_button.pressed.connect(_on_hero_button_pressed)
	gameplay_button.pressed.connect(_on_gameplay_button_pressed)

	# Child-to-sibling communication via parent coordination
	crafting_view.item_finished.connect(hero_view.set_last_crafted_item)
	hero_view.equipment_changed.connect(gameplay_view.refresh_clearing_speed)
	gameplay_view.item_base_found.connect(crafting_view.set_new_item_base)
	gameplay_view.hammers_found.connect(crafting_view.add_hammers)

	# Show crafting view by default
	show_view("crafting")


func _input(event) -> void:
	# Keyboard shortcuts for navigation
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				show_view("crafting")
			KEY_2:
				show_view("hero")
			KEY_3:
				show_view("gameplay")
			KEY_TAB:
				# Toggle between views
				if current_view == "crafting":
					show_view("hero")
				elif current_view == "hero":
					show_view("gameplay")
				else:
					show_view("crafting")


func _on_crafting_button_pressed() -> void:
	show_view("crafting")


func _on_hero_button_pressed() -> void:
	show_view("hero")


func _on_gameplay_button_pressed() -> void:
	show_view("gameplay")


func show_view(view_name: String) -> void:
	# Hide all views
	crafting_view.visible = false
	hero_view.visible = false
	gameplay_view.visible = false

	# Show the selected view
	match view_name:
		"crafting":
			crafting_view.visible = true
			crafting_button.disabled = true
			hero_button.disabled = false
			gameplay_button.disabled = false
		"hero":
			hero_view.visible = true
			crafting_button.disabled = false
			hero_button.disabled = true
			gameplay_button.disabled = false
		"gameplay":
			gameplay_view.visible = true
			crafting_button.disabled = false
			hero_button.disabled = false
			gameplay_button.disabled = true

	current_view = view_name
	print("Switched to ", view_name, " view")
