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

# Item type button references
@onready var weapon_type_btn: Button = $ItemTypeButtons/WeaponButton
@onready var helmet_type_btn: Button = $ItemTypeButtons/HelmetButton
@onready var armor_type_btn: Button = $ItemTypeButtons/ArmorButton
@onready var boots_type_btn: Button = $ItemTypeButtons/BootsButton
@onready var ring_type_btn: Button = $ItemTypeButtons/RingButton

# Display references
@onready var item_image: TextureRect = $ItemGraphicsPanel/ItemImage
@onready var item_stats_label: Label = $ItemStatsPanel/ItemStatsLabel
@onready var hero_stats_label: RichTextLabel = $HeroStatsPanel/HeroStatsLabel
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
var inventory_types: Array = ["weapon", "helmet", "armor", "boots", "ring"]

# Equip confirmation state
var equip_confirm_pending: bool = false
var equip_timer: Timer

# Hero display state
var currently_hovered_type: String = ""
var equip_hover_active: bool = false

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

	# Set hammer tooltips
	runic_btn.tooltip_text = "Runic Hammer\nTurns a normal item into a magic item\nwith 1-2 random mods.\nRequires: Normal rarity"
	forge_btn.tooltip_text = "Forge Hammer\nTurns a normal item into a rare item\nwith 4-6 random mods.\nRequires: Normal rarity"
	tack_btn.tooltip_text = "Tack Hammer\nAdds one random mod to a magic item.\nRequires: Magic rarity with room for mods"
	grand_btn.tooltip_text = "Grand Hammer\nAdds one random mod to a rare item.\nRequires: Rare rarity with room for mods"
	claw_btn.tooltip_text = "Claw Hammer\nRemoves one random mod from an item.\nRequires: At least one mod"
	tuning_btn.tooltip_text = "Tuning Hammer\nRerolls all mod values within their\ntier ranges.\nRequires: At least one mod"

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

	# Connect equip button hover for stat comparison
	equip_button.mouse_entered.connect(_on_equip_hover_entered)
	equip_button.mouse_exited.connect(_on_equip_hover_exited)

	# Create equip confirmation timer
	equip_timer = Timer.new()
	equip_timer.name = "EquipTimer"
	equip_timer.one_shot = true
	equip_timer.wait_time = 3.0
	equip_timer.timeout.connect(_on_equip_timer_timeout)
	add_child(equip_timer)

	# Load crafting inventory from GameState
	var has_saved_items := false
	for type_name in inventory_types:
		if GameState.crafting_inventory.get(type_name) != null:
			has_saved_items = true
			break

	# Only create starting items if inventory is empty (fresh game, no save)
	# Player starts with only a weapon — must clear maps to get other items
	if not has_saved_items:
		var starting_weapon := LightSword.new()
		add_item_to_inventory(starting_weapon)

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
	# Reset equip confirmation when selecting currency
	if equip_confirm_pending:
		equip_confirm_pending = false
		equip_timer.stop()
		equip_button.text = "Equip"

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
	# Reset equip confirmation when switching types
	equip_confirm_pending = false
	if equip_timer != null:
		equip_timer.stop()
	equip_button.text = "Equip"

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
	update_melt_equip_states()


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


# --- Equip button hover for stat comparison ---


func _on_equip_hover_entered() -> void:
	equip_hover_active = true
	update_hero_stats_display()


func _on_equip_hover_exited() -> void:
	equip_hover_active = false
	update_hero_stats_display()


# --- Melt / Equip ---


func _on_melt_pressed() -> void:
	if current_item == null:
		return
	var slot_name: String = get_item_type(current_item)
	print("Melted: ", current_item.item_name)

	# Clear the crafting slot
	if slot_name != "None":
		GameState.crafting_inventory[slot_name] = null
	current_item = null

	# Reset equip confirm state if active
	equip_confirm_pending = false
	equip_timer.stop()
	equip_button.text = "Equip"

	update_item_stats_display()
	update_melt_equip_states()
	update_inventory_display()


func _on_equip_pressed() -> void:
	if current_item == null:
		return
	var slot_name: String = get_item_type(current_item)
	if slot_name == "None":
		return

	# Check if slot is occupied and confirmation not yet given
	var existing: Item = GameState.hero.equipped_items.get(slot_name)
	if existing != null and not equip_confirm_pending:
		# First click — show confirmation
		equip_confirm_pending = true
		equip_button.text = "Confirm Overwrite?"
		equip_timer.start()
		return

	# Second click (confirmed) or empty slot — do the equip
	equip_confirm_pending = false
	equip_timer.stop()
	equip_button.text = "Equip"

	# Equip the item (old item in slot is destroyed)
	GameState.hero.equip_item(current_item, slot_name)
	GameEvents.equipment_changed.emit(slot_name, current_item)
	GameEvents.item_crafted.emit(current_item)
	print("Equipped: ", current_item.item_name, " to ", slot_name)

	# Clear the crafting slot
	GameState.crafting_inventory[slot_name] = null
	current_item = null

	# Update all displays
	update_hero_stats_display()
	update_item_stats_display()
	update_melt_equip_states()
	update_inventory_display()
	equipment_changed.emit()


func _on_equip_timer_timeout() -> void:
	equip_confirm_pending = false
	equip_button.text = "Equip"


func update_melt_equip_states() -> void:
	var has_item: bool = current_item != null
	melt_button.disabled = not has_item
	equip_button.disabled = not has_item


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

	if current_item != null:
		item_stats_label.text = get_item_stats_text(current_item)
		item_stats_label.modulate = current_item.get_rarity_color()
	else:
		item_stats_label.text = "No item on crafting bench"
		item_stats_label.modulate = Color.WHITE


func update_hero_stats_display() -> void:
	if hero_stats_label == null:
		return

	# If hovering the Equip button, show stat comparison
	if equip_hover_active and current_item != null:
		hero_stats_label.text = get_stat_comparison_text()
		return

	# If hovering an item type button, show equipped item of that type for comparison
	if currently_hovered_type != "":
		var equipped_item: Item = GameState.hero.equipped_items.get(currently_hovered_type)
		if equipped_item != null:
			hero_stats_label.text = (
				"Equipped " + currently_hovered_type.capitalize() + ":\n\n"
				+ get_item_stats_text(equipped_item)
			)
			# Apply rarity color to the equipped item text
			hero_stats_label.modulate = equipped_item.get_rarity_color()
		else:
			hero_stats_label.text = (
				"Equipped " + currently_hovered_type.capitalize() + ":\n\n(Empty)"
			)
			hero_stats_label.modulate = Color.WHITE
		return

	# Default: show aggregate hero stats (no BBCode needed for default view)
	var hero: Hero = GameState.hero

	# Reset color to white for default view
	hero_stats_label.modulate = Color.WHITE

	# Offense section
	hero_stats_label.text = "Hero Stats:\n\nOffense:\n"
	hero_stats_label.text += "Total DPS: %.1f\n" % hero.get_total_dps()
	hero_stats_label.text += "Crit Chance: %.1f%%\n" % hero.get_total_crit_chance()
	hero_stats_label.text += "Crit Damage: %.1f%%\n" % hero.get_total_crit_damage()

	# Defense section (only show non-zero types)
	hero_stats_label.text += "\nDefense:\n"
	hero_stats_label.text += "Health: %.0f/%.0f\n" % [hero.health, hero.max_health]

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


func format_stat_delta(label: String, current_val: float, new_val: float, fmt: String = "%.1f") -> String:
	var delta: float = new_val - current_val
	var line: String = label + ": " + fmt % current_val
	if abs(delta) < 0.05:
		return line  # No meaningful change, no delta shown
	if delta > 0:
		line += " [color=#55ff55]+" + fmt % delta + "[/color]"
	else:
		line += " [color=#ff5555]" + fmt % delta + "[/color]"
	return line


func format_stat_delta_int(label: String, current_val: int, new_val: int) -> String:
	var delta: int = new_val - current_val
	var line: String = label + ": " + str(current_val)
	if delta == 0:
		return line
	if delta > 0:
		line += " [color=#55ff55]+" + str(delta) + "[/color]"
	else:
		line += " [color=#ff5555]" + str(delta) + "[/color]"
	return line


func get_stat_comparison_text() -> String:
	if current_item == null:
		return ""
	var slot_name: String = get_item_type(current_item)
	if slot_name == "None":
		return ""

	var equipped: Item = GameState.hero.equipped_items.get(slot_name)
	var text: String = "Stat Comparison:\n"
	text += current_item.item_name + " vs "
	if equipped != null:
		text += equipped.item_name
	else:
		text += "(empty slot)"
	text += "\n\n"

	# Weapon stats
	if current_item is Weapon:
		var crafted: Weapon = current_item as Weapon
		var eq_dps: float = 0.0
		var eq_base_dmg: int = 0
		var eq_crit_chance: float = 5.0
		var eq_crit_damage: float = 150.0
		if equipped != null and equipped is Weapon:
			var eq_weapon: Weapon = equipped as Weapon
			eq_dps = eq_weapon.dps
			eq_base_dmg = eq_weapon.base_damage
			eq_crit_chance = eq_weapon.crit_chance
			eq_crit_damage = eq_weapon.crit_damage
		text += format_stat_delta("DPS", eq_dps, crafted.dps) + "\n"
		text += format_stat_delta_int("Base Damage", eq_base_dmg, crafted.base_damage) + "\n"
		text += format_stat_delta("Crit Chance", eq_crit_chance, crafted.crit_chance, "%.1f%%") + "\n"
		text += format_stat_delta("Crit Damage", eq_crit_damage, crafted.crit_damage, "%.1f%%") + "\n"

	# Ring stats (same as weapon — DPS and crit)
	elif current_item is Ring:
		var crafted: Ring = current_item as Ring
		var eq_dps: float = 0.0
		var eq_crit_chance: float = 5.0
		var eq_crit_damage: float = 150.0
		if equipped != null and equipped is Ring:
			var eq_ring: Ring = equipped as Ring
			eq_dps = eq_ring.dps
			eq_crit_chance = eq_ring.crit_chance
			eq_crit_damage = eq_ring.crit_damage
		text += format_stat_delta("DPS", eq_dps, crafted.dps) + "\n"
		text += format_stat_delta("Crit Chance", eq_crit_chance, crafted.crit_chance, "%.1f%%") + "\n"
		text += format_stat_delta("Crit Damage", eq_crit_damage, crafted.crit_damage, "%.1f%%") + "\n"

	# Armor stats
	elif current_item is Armor:
		var crafted: Armor = current_item as Armor
		var eq_armor: int = 0
		var eq_evasion: int = 0
		var eq_es: int = 0
		var eq_health: int = 0
		if equipped != null and equipped is Armor:
			var eq_item: Armor = equipped as Armor
			eq_armor = eq_item.base_armor
			eq_evasion = eq_item.base_evasion
			eq_es = eq_item.base_energy_shield
			eq_health = eq_item.base_health
		text += format_stat_delta_int("Armor", eq_armor, crafted.base_armor) + "\n"
		if crafted.base_evasion > 0 or eq_evasion > 0:
			text += format_stat_delta_int("Evasion", eq_evasion, crafted.base_evasion) + "\n"
		if crafted.base_energy_shield > 0 or eq_es > 0:
			text += format_stat_delta_int("Energy Shield", eq_es, crafted.base_energy_shield) + "\n"
		if crafted.base_health > 0 or eq_health > 0:
			text += format_stat_delta_int("Health", eq_health, crafted.base_health) + "\n"

	# Helmet stats
	elif current_item is Helmet:
		var crafted: Helmet = current_item as Helmet
		var eq_armor: int = 0
		var eq_evasion: int = 0
		var eq_es: int = 0
		var eq_health: int = 0
		var eq_mana: int = 0
		if equipped != null and equipped is Helmet:
			var eq_item: Helmet = equipped as Helmet
			eq_armor = eq_item.base_armor
			eq_evasion = eq_item.base_evasion
			eq_es = eq_item.base_energy_shield
			eq_health = eq_item.base_health
			eq_mana = eq_item.base_mana
		text += format_stat_delta_int("Armor", eq_armor, crafted.base_armor) + "\n"
		if crafted.base_evasion > 0 or eq_evasion > 0:
			text += format_stat_delta_int("Evasion", eq_evasion, crafted.base_evasion) + "\n"
		if crafted.base_energy_shield > 0 or eq_es > 0:
			text += format_stat_delta_int("Energy Shield", eq_es, crafted.base_energy_shield) + "\n"
		if crafted.base_health > 0 or eq_health > 0:
			text += format_stat_delta_int("Health", eq_health, crafted.base_health) + "\n"
		if crafted.base_mana > 0 or eq_mana > 0:
			text += format_stat_delta_int("Mana", eq_mana, crafted.base_mana) + "\n"

	# Boots stats
	elif current_item is Boots:
		var crafted: Boots = current_item as Boots
		var eq_armor: int = 0
		var eq_evasion: int = 0
		var eq_es: int = 0
		var eq_health: int = 0
		var eq_ms: int = 0
		if equipped != null and equipped is Boots:
			var eq_item: Boots = equipped as Boots
			eq_armor = eq_item.base_armor
			eq_evasion = eq_item.base_evasion
			eq_es = eq_item.base_energy_shield
			eq_health = eq_item.base_health
			eq_ms = eq_item.base_movement_speed
		text += format_stat_delta_int("Armor", eq_armor, crafted.base_armor) + "\n"
		if crafted.base_evasion > 0 or eq_evasion > 0:
			text += format_stat_delta_int("Evasion", eq_evasion, crafted.base_evasion) + "\n"
		if crafted.base_energy_shield > 0 or eq_es > 0:
			text += format_stat_delta_int("Energy Shield", eq_es, crafted.base_energy_shield) + "\n"
		if crafted.base_movement_speed > 0 or eq_ms > 0:
			text += format_stat_delta_int("Movement Speed", eq_ms, crafted.base_movement_speed) + "\n"
		if crafted.base_health > 0 or eq_health > 0:
			text += format_stat_delta_int("Health", eq_health, crafted.base_health) + "\n"

	# Add resistance comparison for all item types (resistances come from suffixes)
	text += _get_resistance_comparison_text(current_item, equipped)

	return text


func _get_resistance_comparison_text(crafted: Item, equipped: Item) -> String:
	var text: String = ""

	# Sum resistance values from suffixes
	var crafted_fire: int = _sum_suffix_stat(crafted, Tag.StatType.FIRE_RESISTANCE)
	var crafted_cold: int = _sum_suffix_stat(crafted, Tag.StatType.COLD_RESISTANCE)
	var crafted_lightning: int = _sum_suffix_stat(crafted, Tag.StatType.LIGHTNING_RESISTANCE)

	# Add ALL_RESISTANCE to each element
	var crafted_all: int = _sum_suffix_stat(crafted, Tag.StatType.ALL_RESISTANCE)
	crafted_fire += crafted_all
	crafted_cold += crafted_all
	crafted_lightning += crafted_all

	var eq_fire: int = 0
	var eq_cold: int = 0
	var eq_lightning: int = 0
	if equipped != null:
		eq_fire = _sum_suffix_stat(equipped, Tag.StatType.FIRE_RESISTANCE)
		eq_cold = _sum_suffix_stat(equipped, Tag.StatType.COLD_RESISTANCE)
		eq_lightning = _sum_suffix_stat(equipped, Tag.StatType.LIGHTNING_RESISTANCE)
		var eq_all: int = _sum_suffix_stat(equipped, Tag.StatType.ALL_RESISTANCE)
		eq_fire += eq_all
		eq_cold += eq_all
		eq_lightning += eq_all

	if crafted_fire > 0 or eq_fire > 0:
		text += format_stat_delta_int("Fire Res", eq_fire, crafted_fire) + "\n"
	if crafted_cold > 0 or eq_cold > 0:
		text += format_stat_delta_int("Cold Res", eq_cold, crafted_cold) + "\n"
	if crafted_lightning > 0 or eq_lightning > 0:
		text += format_stat_delta_int("Lightning Res", eq_lightning, crafted_lightning) + "\n"

	return text


func _sum_suffix_stat(item: Item, stat_type: int) -> int:
	var total: int = 0
	for suffix in item.suffixes:
		if stat_type in suffix.stat_types:
			total += suffix.value
	return total


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
