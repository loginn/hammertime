extends Node2D

signal equipment_changed()

enum ItemSlot { NONE = -1, WEAPON, HELMET, ARMOR, BOOTS, RING }

# Hammer button references
@onready var runic_btn: Button = $HammerSidebar/RunicHammerBtn
@onready var forge_btn: Button = $HammerSidebar/ForgeHammerBtn
@onready var tack_btn: Button = $HammerSidebar/TackHammerBtn
@onready var grand_btn: Button = $HammerSidebar/GrandHammerBtn
@onready var claw_btn: Button = $HammerSidebar/ClawHammerBtn
@onready var tuning_btn: Button = $HammerSidebar/TuningHammerBtn
@onready var finish_item_btn: Button = $HammerSidebar/FinishItemButton

# Item type button references
@onready var weapon_type_btn: Button = $ItemTypeButtons/WeaponButton
@onready var helmet_type_btn: Button = $ItemTypeButtons/HelmetButton
@onready var armor_type_btn: Button = $ItemTypeButtons/ArmorButton
@onready var boots_type_btn: Button = $ItemTypeButtons/BootsButton
@onready var ring_type_btn: Button = $ItemTypeButtons/RingButton

# Display references
@onready var item_image: TextureRect = $ItemGraphicsPanel/ItemImage
@onready var item_stats_label: Label = $ItemStatsPanel/ItemStatsLabel
@onready var hero_stats_label: Label = $HeroStatsPanel/HeroStatsLabel
@onready var inventory_label: Label = $HammerSidebar/InventoryLabel
@onready var melt_button: Button = $ItemStatsPanel/MeltButton
@onready var equip_button: Button = $ItemStatsPanel/EquipButton

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

# Crafting state
var current_item: Item = null
var finished_item: Item = null
var inventory_types: Array = ["weapon", "helmet", "armor", "boots", "ring"]

# Hero display state
var currently_hovered_type: String = ""

# Hammer icon textures
var hammer_icons: Dictionary = {
	"runic": preload("res://assets/runic_hammer.png"),
	"forge": preload("res://assets/forge_hammer.png"),
	"tack": preload("res://assets/tack_hammer.png"),
	"grand": preload("res://assets/grand_hammer.png"),
	"claw": preload("res://assets/claw_hammer.png"),
	"tuning": preload("res://assets/tuning_hammer.png")
}


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

	# Connect item image click for applying currency
	item_image.gui_input.connect(update_item)

	# Connect item type buttons
	weapon_type_btn.pressed.connect(_on_item_type_selected.bind("weapon"))
	helmet_type_btn.pressed.connect(_on_item_type_selected.bind("helmet"))
	armor_type_btn.pressed.connect(_on_item_type_selected.bind("armor"))
	boots_type_btn.pressed.connect(_on_item_type_selected.bind("boots"))
	ring_type_btn.pressed.connect(_on_item_type_selected.bind("ring"))

	# Connect item type button hover for hero stats comparison
	weapon_type_btn.mouse_entered.connect(_on_type_hover_entered.bind("weapon"))
	helmet_type_btn.mouse_entered.connect(_on_type_hover_entered.bind("helmet"))
	armor_type_btn.mouse_entered.connect(_on_type_hover_entered.bind("armor"))
	boots_type_btn.mouse_entered.connect(_on_type_hover_entered.bind("boots"))
	ring_type_btn.mouse_entered.connect(_on_type_hover_entered.bind("ring"))

	weapon_type_btn.mouse_exited.connect(_on_type_hover_exited.bind("weapon"))
	helmet_type_btn.mouse_exited.connect(_on_type_hover_exited.bind("helmet"))
	armor_type_btn.mouse_exited.connect(_on_type_hover_exited.bind("armor"))
	boots_type_btn.mouse_exited.connect(_on_type_hover_exited.bind("boots"))
	ring_type_btn.mouse_exited.connect(_on_type_hover_exited.bind("ring"))

	# Connect melt/equip buttons
	melt_button.pressed.connect(_on_melt_pressed)
	equip_button.pressed.connect(_on_equip_pressed)

	# Load crafting inventory from GameState
	var has_saved_items := false
	for type_name in inventory_types:
		if GameState.crafting_inventory.get(type_name) != null:
			has_saved_items = true
			break

	# Only create starting items if inventory is empty (fresh game, no save)
	if not has_saved_items:
		var starting_weapon := LightSword.new()
		var starting_helmet := BasicHelmet.new()
		var starting_armor := BasicArmor.new()
		var starting_boots := BasicBoots.new()
		var starting_ring := BasicRing.new()

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

	# Update all displays
	update_inventory_display()
	update_item_type_button_states()
	update_currency_button_states()
	update_item_stats_display()
	update_hero_stats_display()
	update_melt_equip_states()


# --- Currency selection and application ---


func _on_currency_selected(currency_type: String) -> void:
	var button: Button = currency_buttons[currency_type]

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
	update_item_stats_display()
	update_currency_button_states()
	current_item.display()


func update_currency_button_states() -> void:
	# Update each currency button based on counts from GameState
	for currency_type in currency_buttons:
		var count: int = GameState.currency_counts.get(currency_type, 0)
		var button: Button = currency_buttons[currency_type]

		# Disable button if no currency available
		button.disabled = (count <= 0)

		# Update button text with currency name and count
		button.text = currencies[currency_type].currency_name + " (" + str(count) + ")"
		button.icon = hammer_icons.get(currency_type)

	# If selected currency count is 0, deselect it
	if selected_currency != null:
		var selected_count: int = GameState.currency_counts.get(selected_currency_type, 0)
		if selected_count <= 0:
			selected_currency = null
			selected_currency_type = ""
			# Untoggle the button
			for currency_type in currency_buttons:
				currency_buttons[currency_type].button_pressed = false


# --- Item type selection ---


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
	var button_map: Dictionary = {
		"weapon": weapon_type_btn,
		"helmet": helmet_type_btn,
		"armor": armor_type_btn,
		"boots": boots_type_btn,
		"ring": ring_type_btn
	}

	for item_type in button_map.keys():
		button_map[item_type].button_pressed = (item_type == GameState.crafting_bench_type)


func update_current_item() -> void:
	var selected_type: String = get_selected_item_type()

	if selected_type != "" and GameState.crafting_inventory.get(selected_type) != null:
		current_item = GameState.crafting_inventory[selected_type]
		print("Selected ", current_item.item_name, " for crafting")
	else:
		current_item = null
		print("No ", selected_type, " in inventory")

	update_item_stats_display()


func get_selected_item_type() -> String:
	return GameState.crafting_bench_type


# --- Item type hover for hero stats comparison ---


func _on_type_hover_entered(item_type: String) -> void:
	currently_hovered_type = item_type
	update_hero_stats_display()


func _on_type_hover_exited(_item_type: String) -> void:
	currently_hovered_type = ""
	update_hero_stats_display()


# --- Finish item ---


func _on_finish_item_button_pressed() -> void:
	finish_item()


func finish_item() -> void:
	if current_item == null:
		print("No item to finish")
		return

	# Untoggle all currency buttons
	for currency_type in currency_buttons:
		currency_buttons[currency_type].button_pressed = false

	# Clear currency selection
	selected_currency = null
	selected_currency_type = ""

	# Store the finished item
	finished_item = current_item

	# Emit global crafted signal for save triggers
	GameEvents.item_crafted.emit(finished_item)

	# Remove the finished item from inventory
	var finished_item_type: String = get_item_type(current_item)
	if finished_item_type != "None":
		GameState.crafting_inventory[finished_item_type] = null
		print("Removed finished ", finished_item_type, " from inventory")

	# Clear the current item — player must choose Melt or Equip
	current_item = null
	update_inventory_display()
	update_currency_button_states()
	update_item_stats_display()
	update_melt_equip_states()

	print("Item finished! Choose Melt or Equip.")


# --- Melt / Equip ---


func _on_melt_pressed() -> void:
	if finished_item == null:
		return
	# Destroy the item, free the crafting slot
	print("Melted: ", finished_item.item_name)
	finished_item = null
	update_item_stats_display()
	update_melt_equip_states()


func _on_equip_pressed() -> void:
	if finished_item == null:
		return
	var slot_name: String = get_item_type(finished_item)
	if slot_name == "None":
		return
	# Old item in slot is DESTROYED (no swap-back, per CONTEXT.md)
	GameState.hero.equip_item(finished_item, slot_name)
	GameEvents.equipment_changed.emit(slot_name, finished_item)
	print("Equipped: ", finished_item.item_name, " to ", slot_name)
	finished_item = null
	update_hero_stats_display()
	update_item_stats_display()
	update_melt_equip_states()
	equipment_changed.emit()


func update_melt_equip_states() -> void:
	var has_finished: bool = finished_item != null
	melt_button.disabled = not has_finished
	equip_button.disabled = not has_finished


# --- Inventory management ---


func add_item_to_inventory(item: Item) -> void:
	var item_type: String = get_item_type(item)

	if item_type == "None":
		print("Unknown item type for: ", item.item_name)
		return

	# Check if we should replace the existing item
	var existing_item: Item = GameState.crafting_inventory[item_type]
	if existing_item == null or is_item_better(item, existing_item):
		GameState.crafting_inventory[item_type] = item
		print("Added ", item.item_name, " to ", item_type, " slot")
		update_inventory_display()
	else:
		print("New ", item.item_name, " is not better than existing ", existing_item.item_name)


func set_new_item_base(item_base: Item) -> void:
	add_item_to_inventory(item_base)
	print("New item base received: ", item_base.item_name)


func on_currencies_found(drops: Dictionary) -> void:
	# Currency counts are already updated in GameState
	# Just refresh UI to show new counts
	print("Currencies received: ", drops)
	update_inventory_display()
	update_currency_button_states()


func get_item_type(item: Item) -> String:
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
	return new_item.tier > existing_item.tier


# --- Display updates ---


func update_inventory_display() -> void:
	if inventory_label == null:
		return

	var display_text: String = "Crafting Inventory:\n\n"

	for item_type in inventory_types:
		var item: Item = GameState.crafting_inventory.get(item_type)
		var type_name: String = item_type.capitalize()

		if item != null:
			display_text += type_name + ": " + item.item_name
			var rarity_name: String = "Normal"
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


func update_item_stats_display() -> void:
	if item_stats_label == null:
		return

	if finished_item != null:
		item_stats_label.text = get_item_stats_text(finished_item)
		item_stats_label.modulate = finished_item.get_rarity_color()
	elif current_item != null:
		item_stats_label.text = get_item_stats_text(current_item)
		item_stats_label.modulate = current_item.get_rarity_color()
	else:
		item_stats_label.text = "No item on crafting bench"
		item_stats_label.modulate = Color.WHITE


func update_hero_stats_display() -> void:
	if hero_stats_label == null:
		return

	# If hovering an item type button, show equipped item of that type for comparison
	if currently_hovered_type != "":
		var equipped_item: Item = GameState.hero.equipped_items.get(currently_hovered_type)
		if equipped_item != null:
			hero_stats_label.text = (
				"Equipped " + currently_hovered_type.capitalize() + ":\n\n"
				+ get_item_stats_text(equipped_item)
			)
		else:
			hero_stats_label.text = (
				"Equipped " + currently_hovered_type.capitalize() + ":\n\n(Empty)"
			)
		return

	# Default: show aggregate hero stats
	var hero: Hero = GameState.hero

	# Offense section
	hero_stats_label.text = "Hero Stats:\n\nOffense:\n"
	hero_stats_label.text += "Total DPS: %.1f\n" % hero.get_total_dps()
	hero_stats_label.text += "Crit Chance: %.1f%%\n" % hero.get_total_crit_chance()
	hero_stats_label.text += "Crit Damage: %.1f%%\n" % hero.get_total_crit_damage()

	# Defense section (only show non-zero types)
	hero_stats_label.text += "\nDefense:\n"

	var total_armor: int = hero.get_total_armor()
	var total_evasion: int = hero.get_total_evasion()
	var total_es: int = hero.get_total_energy_shield()

	var has_defense: bool = false
	if total_armor > 0:
		hero_stats_label.text += "Armor: %d\n" % total_armor
		has_defense = true
	if total_evasion > 0:
		hero_stats_label.text += "Evasion: %d\n" % total_evasion
		has_defense = true
	if total_es > 0:
		hero_stats_label.text += (
			"Energy Shield: %.0f/%d\n"
			% [hero.get_current_energy_shield(), total_es]
		)
		has_defense = true

	var total_fire_res: int = hero.get_total_fire_resistance()
	var total_cold_res: int = hero.get_total_cold_resistance()
	var total_lightning_res: int = hero.get_total_lightning_resistance()

	if total_fire_res > 0:
		hero_stats_label.text += "Fire Resistance: %d\n" % total_fire_res
		has_defense = true
	if total_cold_res > 0:
		hero_stats_label.text += "Cold Resistance: %d\n" % total_cold_res
		has_defense = true
	if total_lightning_res > 0:
		hero_stats_label.text += "Lightning Resistance: %d\n" % total_lightning_res
		has_defense = true

	if not has_defense:
		hero_stats_label.text += "(No defense equipped)\n"


func get_item_stats_text(item: Item) -> String:
	var rarity_name: String = "Normal"
	match item.rarity:
		Item.Rarity.MAGIC:
			rarity_name = "Magic"
		Item.Rarity.RARE:
			rarity_name = "Rare"
	var stats_text: String = item.item_name + " (" + rarity_name + ")" + "\n\n"

	if item is Weapon:
		var weapon: Weapon = item as Weapon
		stats_text += "DPS: %.1f\n" % weapon.dps
		stats_text += "Base Damage: %d\n" % weapon.base_damage
		stats_text += "Base Speed: %.1f\n" % weapon.base_speed
		stats_text += "Crit Chance: %.1f%%\n" % weapon.crit_chance
		stats_text += "Crit Damage: %.1f%%\n" % weapon.crit_damage

		if weapon.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += weapon.implicit.affix_name + ": " + str(weapon.implicit.value) + "\n"

		if weapon.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in weapon.prefixes:
				stats_text += prefix.affix_name + ": " + str(prefix.value) + "\n"

		if weapon.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in weapon.suffixes:
				stats_text += suffix.affix_name + ": " + str(suffix.value) + "\n"
	elif item is Armor:
		var armor_item: Armor = item as Armor
		stats_text += "Armor: %d\n" % armor_item.base_armor
		if armor_item.base_evasion > 0:
			stats_text += "Evasion: %d\n" % armor_item.base_evasion
		if armor_item.base_energy_shield > 0:
			stats_text += "Energy Shield: %d\n" % armor_item.base_energy_shield
		if armor_item.base_health > 0:
			stats_text += "Health: %d\n" % armor_item.base_health

		if armor_item.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += armor_item.implicit.affix_name + ": " + str(armor_item.implicit.value) + "\n"

		if armor_item.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in armor_item.prefixes:
				stats_text += prefix.affix_name + ": " + str(prefix.value) + "\n"

		if armor_item.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in armor_item.suffixes:
				stats_text += suffix.affix_name + ": " + str(suffix.value) + "\n"
	elif item is Boots:
		var boots_item: Boots = item as Boots
		stats_text += "Armor: %d\n" % boots_item.base_armor
		if boots_item.base_evasion > 0:
			stats_text += "Evasion: %d\n" % boots_item.base_evasion
		if boots_item.base_energy_shield > 0:
			stats_text += "Energy Shield: %d\n" % boots_item.base_energy_shield
		stats_text += "Movement Speed: %d\n" % boots_item.base_movement_speed
		if boots_item.base_health > 0:
			stats_text += "Health: %d\n" % boots_item.base_health

		if boots_item.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += boots_item.implicit.affix_name + ": " + str(boots_item.implicit.value) + "\n"

		if boots_item.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in boots_item.prefixes:
				stats_text += prefix.affix_name + ": " + str(prefix.value) + "\n"

		if boots_item.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in boots_item.suffixes:
				stats_text += suffix.affix_name + ": " + str(suffix.value) + "\n"
	elif item is Helmet:
		var helmet_item: Helmet = item as Helmet
		stats_text += "Armor: %d\n" % helmet_item.base_armor
		if helmet_item.base_evasion > 0:
			stats_text += "Evasion: %d\n" % helmet_item.base_evasion
		if helmet_item.base_energy_shield > 0:
			stats_text += "Energy Shield: %d\n" % helmet_item.base_energy_shield
		if helmet_item.base_mana > 0:
			stats_text += "Mana: %d\n" % helmet_item.base_mana
		if helmet_item.base_health > 0:
			stats_text += "Health: %d\n" % helmet_item.base_health

		if helmet_item.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += helmet_item.implicit.affix_name + ": " + str(helmet_item.implicit.value) + "\n"

		if helmet_item.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in helmet_item.prefixes:
				stats_text += prefix.affix_name + ": " + str(prefix.value) + "\n"

		if helmet_item.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in helmet_item.suffixes:
				stats_text += suffix.affix_name + ": " + str(suffix.value) + "\n"
	elif item is Ring:
		var ring_item: Ring = item as Ring
		stats_text += "DPS: %.1f\n" % ring_item.dps
		stats_text += "Crit Chance: %.1f%%\n" % ring_item.crit_chance
		stats_text += "Crit Damage: %.1f%%\n" % ring_item.crit_damage

		if ring_item.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += ring_item.implicit.affix_name + ": " + str(ring_item.implicit.value) + "\n"

		if ring_item.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in ring_item.prefixes:
				stats_text += prefix.affix_name + ": " + str(prefix.value) + "\n"

		if ring_item.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in ring_item.suffixes:
				stats_text += suffix.affix_name + ": " + str(suffix.value) + "\n"
	else:
		stats_text += "(Unknown item type)"

	return stats_text
