extends Node2D

signal item_finished(item: Item)

@onready var buttons = $ButtonControl.get_children()
@onready var item_label: Label = $Label
@onready var inventory_label: Label = $InventoryPanel/InventoryLabel
@onready var runic_btn: Button = $ButtonControl/RunicHammerBtn
@onready var forge_btn: Button = $ButtonControl/ForgeHammerBtn
@onready var tack_btn: Button = $ButtonControl/TackHammerBtn
@onready var grand_btn: Button = $ButtonControl/GrandHammerBtn
@onready var claw_btn: Button = $ButtonControl/ClawHammerBtn
@onready var tuning_btn: Button = $ButtonControl/TuningHammerBtn
@onready var finish_item_btn: Button = $ButtonControl/FinishItemButton
@onready var item_view: TextureRect = $ItemView
@onready var weapon_type_btn: Button = $ItemTypeButtons/WeaponButton
@onready var helmet_type_btn: Button = $ItemTypeButtons/HelmetButton
@onready var armor_type_btn: Button = $ItemTypeButtons/ArmorButton
@onready var boots_type_btn: Button = $ItemTypeButtons/BootsButton
@onready var ring_type_btn: Button = $ItemTypeButtons/RingButton

# Currency instances
var currencies: Dictionary = {
	"runic": RunicHammer.new(),
	"forge": ForgeHammer.new(),
	"tack": TackHammer.new(),
	"grand": GrandHammer.new(),
	"claw": ClawHammer.new(),
	"tuning": TuningHammer.new()
}
var selected_currency: Currency = null
var selected_currency_type: String = ""

# Button-to-currency mapping (initialized in _ready)
var currency_buttons: Dictionary = {}

var current_item: Item
var finished_item: Item = null

# Item type list for iteration
var inventory_types = ["weapon", "helmet", "armor", "boots", "ring"]


func _ready() -> void:
	# Initialize currency button mapping
	currency_buttons = {
		"runic": runic_btn,
		"forge": forge_btn,
		"tack": tack_btn,
		"grand": grand_btn,
		"claw": claw_btn,
		"tuning": tuning_btn
	}

	# Connect currency button signals
	runic_btn.pressed.connect(_on_currency_selected.bind("runic"))
	forge_btn.pressed.connect(_on_currency_selected.bind("forge"))
	tack_btn.pressed.connect(_on_currency_selected.bind("tack"))
	grand_btn.pressed.connect(_on_currency_selected.bind("grand"))
	claw_btn.pressed.connect(_on_currency_selected.bind("claw"))
	tuning_btn.pressed.connect(_on_currency_selected.bind("tuning"))
	finish_item_btn.pressed.connect(_on_finish_item_button_pressed)
	item_view.gui_input.connect(update_item)
	weapon_type_btn.pressed.connect(_on_item_type_selected.bind("weapon"))
	helmet_type_btn.pressed.connect(_on_item_type_selected.bind("helmet"))
	armor_type_btn.pressed.connect(_on_item_type_selected.bind("armor"))
	boots_type_btn.pressed.connect(_on_item_type_selected.bind("boots"))
	ring_type_btn.pressed.connect(_on_item_type_selected.bind("ring"))

	# Check if crafting inventory has any items (from save load)
	var has_saved_items := false
	for type_name in inventory_types:
		if GameState.crafting_inventory.get(type_name) != null:
			has_saved_items = true
			break

	# Only create starting items if inventory is empty (fresh game, no save)
	if not has_saved_items:
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

	# Set current item from saved bench type or default to weapon
	var selected_type: String = GameState.crafting_bench_type
	if GameState.crafting_inventory.get(selected_type) != null:
		current_item = GameState.crafting_inventory[selected_type]
	else:
		# Fall back to first available item
		current_item = null
		for type_name in inventory_types:
			if GameState.crafting_inventory.get(type_name) != null:
				selected_type = type_name
				current_item = GameState.crafting_inventory[type_name]
				break
	GameState.crafting_bench_type = selected_type

	update_inventory_display()
	update_item_type_button_states()
	update_currency_button_states()
	update_label()

	# Initially no finished item is available
	item_finished.emit(null)


func update_label() -> void:
	if current_item != null:
		item_label.text = self.current_item.get_display_text()
		item_label.modulate = current_item.get_rarity_color()
	else:
		item_label.text = "No item selected for crafting"
		item_label.modulate = Color.WHITE


func update_item(event: InputEvent) -> void:
	if (
		(event is not InputEventMouseButton)
		or (not event.button_index == MOUSE_BUTTON_LEFT or not event.pressed)
	):
		return

	# Guard: if no currency selected
	if selected_currency == null:
		print("No currency selected")
		return

	# Guard: if no item selected
	if current_item == null:
		print("No item selected")
		return

	# Check if currency can be applied to the item
	if not selected_currency.can_apply(current_item):
		print(selected_currency.get_error_message(current_item))
		return

	# Try to spend the currency
	if not GameState.spend_currency(selected_currency_type):
		print("No " + selected_currency.currency_name + " remaining!")
		return

	# Apply the currency effect
	selected_currency.apply(current_item)
	print("Applied " + selected_currency.currency_name)

	# Update UI
	update_label()
	update_currency_button_states()
	current_item.display()


func untoggle_all_other_buttons(pressed_button: Button) -> void:
	for btn in self.buttons:
		if btn != pressed_button:
			btn.button_pressed = false


func update_currency_button_states() -> void:
	# Update each currency button based on counts from GameState
	for currency_type in currency_buttons:
		var count = GameState.currency_counts.get(currency_type, 0)
		var button = currency_buttons[currency_type]

		# Disable button if no currency available
		button.disabled = (count <= 0)

		# Update button text with currency name and count
		button.text = currencies[currency_type].currency_name + " (" + str(count) + ")"

	# If selected currency count is 0, deselect it
	if selected_currency != null:
		var selected_count = GameState.currency_counts.get(selected_currency_type, 0)
		if selected_count <= 0:
			selected_currency = null
			selected_currency_type = ""
			# Untoggle the button
			for currency_type in currency_buttons:
				currency_buttons[currency_type].button_pressed = false


func _on_currency_selected(currency_type: String) -> void:
	var button = currency_buttons[currency_type]

	if button.button_pressed:
		# Currency selected
		selected_currency = currencies[currency_type]
		selected_currency_type = currency_type
		print("Selected: ", selected_currency.currency_name)

		# Untoggle all other currency buttons
		for other_type in currency_buttons:
			if other_type != currency_type:
				currency_buttons[other_type].button_pressed = false
	else:
		# Currency deselected
		selected_currency = null
		selected_currency_type = ""
		print("Deselected currency")


func _on_finish_item_button_pressed() -> void:
	finish_item()


func finish_item() -> void:
	# Untoggle all buttons
	untoggle_all_other_buttons(null)

	# Clear currency selection
	selected_currency = null
	selected_currency_type = ""

	# Store the finished item
	finished_item = current_item

	# Update the last crafted item in hero view with the finished item
	item_finished.emit(finished_item)

	# Emit global crafted signal for save triggers
	GameEvents.item_crafted.emit(finished_item)

	# Remove the finished item from inventory
	var finished_item_type = get_item_type(current_item)
	if finished_item_type != null:
		GameState.crafting_inventory[finished_item_type] = null
		print("Removed finished ", finished_item_type, " from inventory")

	# Clear the current item - no automatic item generation
	current_item = null
	update_inventory_display()
	update_currency_button_states()
	update_label()

	print("Item finished! No new item generated.")


func set_new_item_base(item_base: Item) -> void:
	# Add the new item base to the crafting inventory
	add_item_to_inventory(item_base)
	print("New item base received: ", item_base.item_name)


func on_currencies_found(drops: Dictionary) -> void:
	# Currency counts are already updated in GameState
	# Just refresh UI to show new counts
	print("Currencies received: ", drops)

	# Update UI
	update_inventory_display()
	update_currency_button_states()


func add_item_to_inventory(item: Item) -> void:
	# Determine the item type
	var item_type = get_item_type(item)

	if item_type == null:
		print("Unknown item type for: ", item.item_name)
		return

	# Check if we should replace the existing item
	var existing_item = GameState.crafting_inventory[item_type]
	if existing_item == null or is_item_better(item, existing_item):
		GameState.crafting_inventory[item_type] = item
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

	if selected_type != null and GameState.crafting_inventory.get(selected_type) != null:
		current_item = GameState.crafting_inventory[selected_type]
		print("Selected ", current_item.item_name, " for crafting")
	else:
		current_item = null
		print("No ", selected_type, " in inventory")

	update_label()


func get_selected_item_type() -> String:
	# Return the currently selected item type
	return GameState.crafting_bench_type


func _on_item_type_selected(item_type: String) -> void:
	# Check if there's an item of this type in the inventory
	if GameState.crafting_inventory.get(item_type) == null:
		print("No ", item_type, " in inventory - selection ignored")
		return

	# Update selected item type
	GameState.crafting_bench_type = item_type
	print("Selected item type: ", item_type)

	# Update current item to use the selected type
	update_current_item()

	# Update button visual states
	update_item_type_button_states()


func update_item_type_button_states() -> void:
	# Update button pressed states to show which type is selected
	var button_map = {
		"weapon": weapon_type_btn,
		"helmet": helmet_type_btn,
		"armor": armor_type_btn,
		"boots": boots_type_btn,
		"ring": ring_type_btn
	}

	for item_type in button_map.keys():
		button_map[item_type].button_pressed = (item_type == GameState.crafting_bench_type)


func update_inventory_display() -> void:
	if inventory_label == null:
		return

	var display_text = "Crafting Inventory:\n\n"

	for item_type in inventory_types:
		var item = GameState.crafting_inventory.get(item_type)
		var type_name = item_type.capitalize()

		if item != null:
			display_text += type_name + ": " + item.item_name
			var rarity_name = "Normal"
			match item.rarity:
				Item.Rarity.MAGIC:
					rarity_name = "Magic"
				Item.Rarity.RARE:
					rarity_name = "Rare"
			display_text += " (" + rarity_name + ")"
			display_text += "\n"
		else:
			display_text += type_name + ": None\n"

	inventory_label.text = display_text
