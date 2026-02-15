extends Node2D

signal item_finished(item: Item)

enum button { NONE, IMPLICIT, PREFIX, SUFFIX }

var buttons
var button_pressed: button
var current_item: Item
var item_label: Label
var finished_item: Item = null
var inventory_label: Label

# Crafting inventory system
var crafting_inventory: Dictionary = {}
var inventory_types = ["weapon", "helmet", "armor", "boots", "ring"]
var selected_item_type: String = "weapon"

# Hammer limit system
var hammer_counts: Dictionary = {"implicit": 10, "prefix": 10, "suffix": 10}


func _ready() -> void:
	self.buttons = $ButtonControl.get_children()
	self.item_label = $Label
	self.inventory_label = $InventoryPanel/InventoryLabel

	# Initialize crafting inventory
	initialize_crafting_inventory()

	$ButtonControl/ImplicitHammer.connect("pressed", ImplicitHammer_toggled)
	$ButtonControl/AddPrefixHammer.connect("pressed", AddPrefixHammer_toggled)
	$ButtonControl/AddSuffixHammer.connect("pressed", AddSuffixHammer_toggled)
	$ButtonControl/FinishItemButton.connect("pressed", _on_finish_item_button_pressed)
	$ItemView.connect("gui_input", update_item)

	# Connect item type selection buttons
	if has_node("ItemTypeButtons/WeaponButton"):
		$ItemTypeButtons/WeaponButton.connect("pressed", _on_item_type_selected.bind("weapon"))
	if has_node("ItemTypeButtons/HelmetButton"):
		$ItemTypeButtons/HelmetButton.connect("pressed", _on_item_type_selected.bind("helmet"))
	if has_node("ItemTypeButtons/ArmorButton"):
		$ItemTypeButtons/ArmorButton.connect("pressed", _on_item_type_selected.bind("armor"))
	if has_node("ItemTypeButtons/BootsButton"):
		$ItemTypeButtons/BootsButton.connect("pressed", _on_item_type_selected.bind("boots"))
	if has_node("ItemTypeButtons/RingButton"):
		$ItemTypeButtons/RingButton.connect("pressed", _on_item_type_selected.bind("ring"))

	# Start with one basic item of each type for testing
	var starting_weapon = LightSword.new()
	var starting_helmet = BasicHelmet.new()
	var starting_armor = BasicArmor.new()
	var starting_boots = BasicBoots.new()
	var starting_ring = BasicRing.new()

	add_item_to_inventory(starting_weapon)
	add_item_to_inventory(starting_helmet)
	add_item_to_inventory(starting_armor)
	add_item_to_inventory(starting_boots)
	add_item_to_inventory(starting_ring)

	# Set weapon as the initial selected type and current item
	selected_item_type = "weapon"
	current_item = starting_weapon

	update_inventory_display()
	update_item_type_button_states()
	update_hammer_button_states()
	update_label()

	# Initially no finished item is available
	item_finished.emit(null)


func update_label() -> void:
	if current_item != null:
		$Label.text = self.current_item.get_display_text()
	else:
		$Label.text = "No item selected for crafting"


func update_item(event: InputEvent) -> void:
	if (
		(event is not InputEventMouseButton)
		or (not event.button_index == MOUSE_BUTTON_LEFT or not event.pressed)
	):
		return

	# Check if there's a current item to work with
	if current_item == null:
		print("No item selected for crafting")
		return

	print("click")
	if self.button_pressed == button.IMPLICIT:
		if hammer_counts["implicit"] <= 0:
			print("No implicit hammers remaining!")
			return
		self.current_item.reroll_affix(self.current_item.implicit)
		hammer_counts["implicit"] -= 1
		print("Implicit hammers remaining: ", hammer_counts["implicit"])
	elif self.button_pressed == button.PREFIX:
		if hammer_counts["prefix"] <= 0:
			print("No prefix hammers remaining!")
			return
		self.current_item.add_prefix()
		hammer_counts["prefix"] -= 1
		print("Prefix hammers remaining: ", hammer_counts["prefix"])
	elif self.button_pressed == button.SUFFIX:
		if hammer_counts["suffix"] <= 0:
			print("No suffix hammers remaining!")
			return
		self.current_item.add_suffix()
		hammer_counts["suffix"] -= 1
		print("Suffix hammers remaining: ", hammer_counts["suffix"])
	else:
		print("no button selected")

	self.current_item.update_value()
	self.update_label()
	update_hammer_button_states()

	# Don't update the hero view until item is finished
	current_item.display()


func untoggle_all_other_buttons(pressed_button: Button) -> void:
	for btn in self.buttons:
		if btn != pressed_button:
			btn.button_pressed = false


func update_hammer_button_states() -> void:
	# Update hammer button states based on remaining counts
	$ButtonControl/ImplicitHammer.disabled = (hammer_counts["implicit"] <= 0)
	$ButtonControl/AddPrefixHammer.disabled = (hammer_counts["prefix"] <= 0)
	$ButtonControl/AddSuffixHammer.disabled = (hammer_counts["suffix"] <= 0)

	# Update button text to show remaining counts
	$ButtonControl/ImplicitHammer.text = "Implicit (" + str(hammer_counts["implicit"]) + ")"
	$ButtonControl/AddPrefixHammer.text = "Add Prefix (" + str(hammer_counts["prefix"]) + ")"
	$ButtonControl/AddSuffixHammer.text = "Add Suffix (" + str(hammer_counts["suffix"]) + ")"


func ImplicitHammer_toggled() -> void:
	# Check if implicit hammers are available
	if hammer_counts["implicit"] <= 0:
		print("No implicit hammers remaining!")
		$ButtonControl/ImplicitHammer.button_pressed = false
		return

	self.untoggle_all_other_buttons($ButtonControl/ImplicitHammer)
	if $ButtonControl/ImplicitHammer.button_pressed:
		self.button_pressed = button.IMPLICIT
		print("implicit")


func AddPrefixHammer_toggled() -> void:
	# Check if prefix hammers are available
	if hammer_counts["prefix"] <= 0:
		print("No prefix hammers remaining!")
		$ButtonControl/AddPrefixHammer.button_pressed = false
		return

	self.untoggle_all_other_buttons($ButtonControl/AddPrefixHammer)
	if $ButtonControl/AddPrefixHammer.button_pressed:
		self.button_pressed = button.PREFIX
		print("prefix")


func AddSuffixHammer_toggled() -> void:
	# Check if suffix hammers are available
	if hammer_counts["suffix"] <= 0:
		print("No suffix hammers remaining!")
		$ButtonControl/AddSuffixHammer.button_pressed = false
		return

	self.untoggle_all_other_buttons($ButtonControl/AddSuffixHammer)
	if $ButtonControl/AddSuffixHammer.button_pressed:
		self.button_pressed = button.SUFFIX
		print("suffix")


func _on_finish_item_button_pressed() -> void:
	finish_item()


func finish_item() -> void:
	# Untoggle all buttons
	untoggle_all_other_buttons(null)
	self.button_pressed = button.NONE

	# Store the finished item
	finished_item = current_item

	# Update the last crafted item in hero view with the finished item
	item_finished.emit(finished_item)

	# Remove the finished item from inventory
	var finished_item_type = get_item_type(current_item)
	if finished_item_type != null:
		crafting_inventory[finished_item_type] = null
		print("Removed finished ", finished_item_type, " from inventory")

	# Clear the current item - no automatic item generation
	current_item = null
	update_inventory_display()
	update_label()

	print("Item finished! No new item generated.")


func set_new_item_base(item_base: Item) -> void:
	# Add the new item base to the crafting inventory
	add_item_to_inventory(item_base)
	print("New item base received: ", item_base.item_name)


func add_hammers(implicit_count: int, prefix_count: int, suffix_count: int) -> void:
	# Add hammers found by hero in the area
	hammer_counts["implicit"] += implicit_count
	hammer_counts["prefix"] += prefix_count
	hammer_counts["suffix"] += suffix_count

	print(
		"Hero found hammers! Added: ",
		implicit_count,
		" implicit, ",
		prefix_count,
		" prefix, ",
		suffix_count,
		" suffix"
	)
	print(
		"Total hammers now: Implicit(",
		hammer_counts["implicit"],
		") Prefix(",
		hammer_counts["prefix"],
		") Suffix(",
		hammer_counts["suffix"],
		")"
	)

	# Update button states to reflect new hammer counts
	update_hammer_button_states()


func initialize_crafting_inventory() -> void:
	# Initialize empty inventory for each item type
	for item_type in inventory_types:
		crafting_inventory[item_type] = null


func add_item_to_inventory(item: Item) -> void:
	# Determine the item type
	var item_type = get_item_type(item)

	if item_type == null:
		print("Unknown item type for: ", item.item_name)
		return

	# Check if we should replace the existing item
	var existing_item = crafting_inventory[item_type]
	if existing_item == null or is_item_better(item, existing_item):
		crafting_inventory[item_type] = item
		print("Added ", item.item_name, " to ", item_type, " slot")

		# Update inventory display
		update_inventory_display()
	else:
		print("New ", item.item_name, " is not better than existing ", existing_item.item_name)


func get_item_type(item: Item) -> String:
	# Determine item type based on class
	if item is Weapon:
		return "weapon"
	elif item is Helmet:
		return "helmet"
	elif item is Armor:
		return "armor"
	elif item is Boots:
		return "boots"
	elif item is Ring:
		return "ring"
	else:
		return "None"


func is_item_better(new_item: Item, existing_item: Item) -> bool:
	# Compare items based on their tier
	var new_tier = get_item_tier(new_item)
	var existing_tier = get_item_tier(existing_item)

	return new_tier > existing_tier


func get_item_tier(item: Item) -> int:
	# Return tier directly from item property
	return item.tier


func update_current_item() -> void:
	# Use the currently selected item type
	var selected_type = get_selected_item_type()

	if selected_type != null and crafting_inventory[selected_type] != null:
		current_item = crafting_inventory[selected_type]
		print("Selected ", current_item.item_name, " for crafting")
	else:
		# Create appropriate default item based on selected type
		if selected_type == "weapon":
			current_item = LightSword.new()
			print("No weapon in inventory, using default Light Sword")
		elif selected_type == "helmet":
			current_item = BasicHelmet.new()
			print("No helmet in inventory, using default Basic Helmet")
		elif selected_type == "armor":
			current_item = BasicArmor.new()
			print("No armor in inventory, using default Basic Armor")
		elif selected_type == "boots":
			current_item = BasicBoots.new()
			print("No boots in inventory, using default Basic Boots")
		elif selected_type == "ring":
			current_item = BasicRing.new()
			print("No ring in inventory, using default Basic Ring")
		else:
			# Fallback to Light Sword for unknown types
			current_item = LightSword.new()
			print("Unknown item type, using default Light Sword")

	update_label()


func get_selected_item_type() -> String:
	# Return the currently selected item type
	return selected_item_type


func _on_item_type_selected(item_type: String) -> void:
	# Check if there's an item of this type in the inventory
	# Exception: weapons always work for testing (creates Light Swords)
	if crafting_inventory[item_type] == null and item_type != "weapon":
		print("No ", item_type, " in inventory - selection ignored")
		return

	# Update selected item type
	selected_item_type = item_type
	print("Selected item type: ", item_type)

	# Update current item to use the selected type
	update_current_item()

	# Update button visual states
	update_item_type_button_states()


func update_item_type_button_states() -> void:
	# Update button pressed states to show which type is selected
	var button_map = {
		"weapon": "ItemTypeButtons/WeaponButton",
		"helmet": "ItemTypeButtons/HelmetButton",
		"armor": "ItemTypeButtons/ArmorButton",
		"boots": "ItemTypeButtons/BootsButton",
		"ring": "ItemTypeButtons/RingButton"
	}

	for item_type in button_map.keys():
		var button_path = button_map[item_type]
		if has_node(button_path):
			var type_button = get_node(button_path)
			type_button.button_pressed = (item_type == selected_item_type)


func update_inventory_display() -> void:
	if inventory_label == null:
		return

	var display_text = "Crafting Inventory:\n\n"

	for item_type in inventory_types:
		var item = crafting_inventory[item_type]
		var type_name = item_type.capitalize()

		if item != null:
			display_text += type_name + ": " + item.item_name
			var tier = get_item_tier(item)
			display_text += " (Tier " + str(tier) + ")"
			display_text += "\n"
		else:
			display_text += type_name + ": None\n"

	inventory_label.text = display_text
