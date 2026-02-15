extends Node2D

signal equipment_changed()

enum ItemSlot { NONE = -1, WEAPON, HELMET, ARMOR, BOOTS, RING }

@onready var stats_label: Label = $StatsPanel/StatsLabel
@onready var item_stats_label: Label = $ItemStatsPanel/ItemStatsLabel
@onready var crafted_item_stats_label: Label = $CraftedItemStatsPanel/CraftedItemStatsLabel
@onready var weapon_slot: Button = $WeaponSlot
@onready var helmet_slot: Button = $HelmetSlot
@onready var armor_slot: Button = $ArmorSlot
@onready var boots_slot: Button = $BootsSlot
@onready var ring_slot: Button = $RingSlot

var last_crafted_item: Item = null
var currently_hovered_slot: ItemSlot = ItemSlot.NONE


func _ready() -> void:
	# Connect item slot buttons
	weapon_slot.pressed.connect(_on_item_slot_clicked.bind(ItemSlot.WEAPON))
	helmet_slot.pressed.connect(_on_item_slot_clicked.bind(ItemSlot.HELMET))
	armor_slot.pressed.connect(_on_item_slot_clicked.bind(ItemSlot.ARMOR))
	boots_slot.pressed.connect(_on_item_slot_clicked.bind(ItemSlot.BOOTS))
	ring_slot.pressed.connect(_on_item_slot_clicked.bind(ItemSlot.RING))

	# Connect hover events for item slots
	weapon_slot.mouse_entered.connect(_on_item_slot_hover_entered.bind(ItemSlot.WEAPON))
	helmet_slot.mouse_entered.connect(_on_item_slot_hover_entered.bind(ItemSlot.HELMET))
	armor_slot.mouse_entered.connect(_on_item_slot_hover_entered.bind(ItemSlot.ARMOR))
	boots_slot.mouse_entered.connect(_on_item_slot_hover_entered.bind(ItemSlot.BOOTS))
	ring_slot.mouse_entered.connect(_on_item_slot_hover_entered.bind(ItemSlot.RING))

	weapon_slot.mouse_exited.connect(_on_item_slot_hover_exited.bind(ItemSlot.WEAPON))
	helmet_slot.mouse_exited.connect(_on_item_slot_hover_exited.bind(ItemSlot.HELMET))
	armor_slot.mouse_exited.connect(_on_item_slot_hover_exited.bind(ItemSlot.ARMOR))
	boots_slot.mouse_exited.connect(_on_item_slot_hover_exited.bind(ItemSlot.BOOTS))
	ring_slot.mouse_exited.connect(_on_item_slot_hover_exited.bind(ItemSlot.RING))

	update_all_slots()
	update_stats_display()
	update_crafted_item_stats_display()


func _on_item_slot_clicked(slot: ItemSlot) -> void:
	print("Clicked on ", get_slot_name(slot), " slot")

	# If there's a last crafted item and it can be equipped to this slot, equip it
	if last_crafted_item != null and can_equip_item(last_crafted_item, slot):
		var success = equip_item(last_crafted_item, slot)
		if success:
			last_crafted_item = null  # Clear the last crafted item after equipping
			update_crafted_item_stats_display()  # Update the crafted item stats display
			print("Equipped item to ", get_slot_name(slot), " slot")
		else:
			print("Failed to equip item to ", get_slot_name(slot), " slot")
	else:
		if last_crafted_item == null:
			print("No finished item available - craft and finish an item first!")
		else:
			print(
				"Cannot equip ", last_crafted_item.item_name, " to ", get_slot_name(slot), " slot"
			)


func _on_item_slot_hover_entered(slot: ItemSlot) -> void:
	currently_hovered_slot = slot
	update_item_stats_display()


func _on_item_slot_hover_exited(_slot: ItemSlot) -> void:
	currently_hovered_slot = ItemSlot.NONE
	update_item_stats_display()


func equip_item(item: Item, slot: ItemSlot) -> bool:
	if can_equip_item(item, slot):
		var slot_name = get_slot_name(slot).to_lower()
		GameState.hero.equip_item(item, slot_name)
		update_slot_display(slot)
		update_stats_display()
		update_item_stats_display()  # Update item stats display in case we're hovering
		equipment_changed.emit()  # Notify gameplay view of DPS change
		GameEvents.equipment_changed.emit(slot_name, item)
		print("Equipped ", item.item_name, " to ", get_slot_name(slot))
		return true
	else:
		print("Cannot equip ", item.item_name, " to ", get_slot_name(slot))
		return false


func unequip_item(slot: ItemSlot) -> Item:
	var slot_name = get_slot_name(slot).to_lower()
	var item = GameState.hero.equipped_items[slot_name]
	GameState.hero.unequip_item(slot_name)
	update_slot_display(slot)
	update_stats_display()
	equipment_changed.emit()  # Notify gameplay view of DPS change
	GameEvents.equipment_changed.emit(slot_name, null)
	if item:
		print("Unequipped ", item.item_name, " from ", get_slot_name(slot))
	return item


func can_equip_item(item: Item, slot: ItemSlot) -> bool:
	# Check if item type matches slot type
	match slot:
		ItemSlot.WEAPON:
			return item is Weapon
		ItemSlot.HELMET:
			return item is Helmet
		ItemSlot.ARMOR:
			return item is Armor
		ItemSlot.BOOTS:
			return item is Boots
		ItemSlot.RING:
			return item is Ring
		_:
			return false


func get_slot_name(slot: ItemSlot) -> String:
	match slot:
		ItemSlot.WEAPON:
			return "Weapon"
		ItemSlot.HELMET:
			return "Helmet"
		ItemSlot.ARMOR:
			return "Armor"
		ItemSlot.BOOTS:
			return "Boots"
		ItemSlot.RING:
			return "Ring"
		_:
			return "Unknown"


func update_slot_display(slot: ItemSlot) -> void:
	var slot_node = get_slot_node(slot)
	var slot_name = get_slot_name(slot).to_lower()
	var item = GameState.hero.equipped_items[slot_name]

	if item:
		slot_node.text = item.item_name
		slot_node.modulate = item.get_rarity_color()
	else:
		slot_node.text = get_slot_name(slot) + "\n(Empty)"
		slot_node.modulate = Color.GRAY


func get_slot_node(slot: ItemSlot) -> Button:
	match slot:
		ItemSlot.WEAPON:
			return weapon_slot
		ItemSlot.HELMET:
			return helmet_slot
		ItemSlot.ARMOR:
			return armor_slot
		ItemSlot.BOOTS:
			return boots_slot
		ItemSlot.RING:
			return ring_slot
		_:
			return null


func update_all_slots() -> void:
	for slot in ItemSlot.values():
		if slot == ItemSlot.NONE:
			continue
		update_slot_display(slot)


func get_total_dps() -> float:
	return GameState.hero.get_total_dps()


func get_total_crit_chance() -> float:
	return GameState.hero.get_total_crit_chance()


func get_total_crit_damage() -> float:
	return GameState.hero.get_total_crit_damage()


func get_total_defense() -> int:
	return GameState.hero.get_total_defense()


func update_stats_display() -> void:
	var total_dps = get_total_dps()
	var total_crit_chance = get_total_crit_chance()
	var total_crit_damage = get_total_crit_damage()
	var total_defense = get_total_defense()

	stats_label.text = "Hero Stats:\n"
	stats_label.text += "Total DPS: %.1f\n" % total_dps
	stats_label.text += "Crit Chance: %.1f%%\n" % total_crit_chance
	stats_label.text += "Crit Damage: %.1f%%\n" % total_crit_damage
	stats_label.text += "Defense: %d" % total_defense


# Set the last crafted item (called from crafting view)
func set_last_crafted_item(item: Item) -> void:
	last_crafted_item = item
	update_crafted_item_stats_display()
	print("Last crafted item set to: ", item.item_name if item else "null")


# Check if there's a last crafted item available
func has_last_crafted_item() -> bool:
	return last_crafted_item != null


# Get info about the last crafted item
func get_last_crafted_item_info() -> String:
	if last_crafted_item == null:
		return "No finished item available"
	else:
		return "Last crafted: " + last_crafted_item.item_name


# Update the crafted item stats display
func update_crafted_item_stats_display() -> void:
	if crafted_item_stats_label == null:
		return

	if last_crafted_item != null:
		crafted_item_stats_label.text = (
			"Crafted Item Stats:\n\n" + get_item_stats_text(last_crafted_item)
		)
	else:
		crafted_item_stats_label.text = "Crafted Item Stats:\n\nNo finished item available"


# Update the item stats display
func update_item_stats_display() -> void:
	if item_stats_label == null:
		return

	if currently_hovered_slot != ItemSlot.NONE:
		var slot_name = get_slot_name(currently_hovered_slot).to_lower()
		var item = GameState.hero.equipped_items[slot_name]
		if item != null:
			# Show stats for the hovered item
			item_stats_label.text = "Item Stats:\n\n" + get_item_stats_text(item)
		else:
			item_stats_label.text = "Item Stats:\n"
	else:
		# Show default message
		item_stats_label.text = "Item Stats:\n"


# Get formatted stats text for an item
func get_item_stats_text(item: Item) -> String:
	var rarity_name = "Normal"
	match item.rarity:
		Item.Rarity.MAGIC:
			rarity_name = "Magic"
		Item.Rarity.RARE:
			rarity_name = "Rare"
	var stats_text = item.item_name + " (" + rarity_name + ")" + "\n\n"

	if item is Weapon:
		var weapon = item as Weapon
		stats_text += "DPS: %.1f\n" % weapon.dps
		stats_text += "Base Damage: %d\n" % weapon.base_damage
		stats_text += "Base Speed: %.1f\n" % weapon.base_speed
		stats_text += "Crit Chance: %.1f%%\n" % weapon.crit_chance
		stats_text += "Crit Damage: %.1f%%\n" % weapon.crit_damage

		# Add affix information
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
	else:
		stats_text += "Defense: 0\n"  # Placeholder for future armor items
		stats_text += "Other stats coming soon..."

	return stats_text


# Test function to equip a weapon
func test_equip_weapon() -> void:
	var test_weapon = LightSword.new()
	equip_item(test_weapon, ItemSlot.WEAPON)
