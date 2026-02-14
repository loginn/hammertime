extends Node2D

var current_view: String = "crafting"
var crafting_view: Node2D
var hero_view: Node2D
var gameplay_view: Node2D


func _ready() -> void:
	print("MainView: Starting initialization...")

	# Get references to all views
	crafting_view = $CraftingView
	hero_view = $HeroView
	gameplay_view = $GameplayView

	print("MainView: Crafting view found: ", crafting_view != null)
	print("MainView: Hero view found: ", hero_view != null)
	print("MainView: Gameplay view found: ", gameplay_view != null)
	print("MainView: Navigation panel found: ", has_node("NavigationPanel"))

	# Connect navigation buttons
	if has_node("NavigationPanel/CraftingButton"):
		$NavigationPanel/CraftingButton.connect("pressed", _on_crafting_button_pressed)
		print("MainView: Crafting button connected")
	else:
		print("MainView: ERROR - Crafting button not found!")

	if has_node("NavigationPanel/HeroButton"):
		$NavigationPanel/HeroButton.connect("pressed", _on_hero_button_pressed)
		print("MainView: Hero button connected")
	else:
		print("MainView: ERROR - Hero button not found!")

	if has_node("NavigationPanel/GameplayButton"):
		$NavigationPanel/GameplayButton.connect("pressed", _on_gameplay_button_pressed)
		print("MainView: Gameplay button connected")
	else:
		print("MainView: ERROR - Gameplay button not found!")

	# Show crafting view by default
	show_view("crafting")

	# Make navigation panel more visible for debugging
	if has_node("NavigationPanel"):
		$NavigationPanel.modulate = Color.WHITE
		print("MainView: Navigation panel made visible")

	print("MainView: Initialization complete")


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
			$NavigationPanel/CraftingButton.disabled = true
			$NavigationPanel/HeroButton.disabled = false
			$NavigationPanel/GameplayButton.disabled = false
		"hero":
			hero_view.visible = true
			$NavigationPanel/CraftingButton.disabled = false
			$NavigationPanel/HeroButton.disabled = true
			$NavigationPanel/GameplayButton.disabled = false
		"gameplay":
			gameplay_view.visible = true
			$NavigationPanel/CraftingButton.disabled = false
			$NavigationPanel/HeroButton.disabled = false
			$NavigationPanel/GameplayButton.disabled = true

	current_view = view_name
	print("Switched to ", view_name, " view")
