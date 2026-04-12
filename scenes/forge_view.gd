extends Node2D

signal equipment_changed()

enum ItemSlot { NONE = -1, WEAPON, HELMET, ARMOR, BOOTS, RING }

# Hammer button references
@onready var runic_btn: Button = $HammerSidebar/RunicHammerBtn
@onready var alchemy_btn: Button = $HammerSidebar/AlchemyHammerBtn
@onready var tack_btn: Button = $HammerSidebar/TackHammerBtn
@onready var grand_btn: Button = $HammerSidebar/GrandHammerBtn
@onready var annulment_btn: Button = $HammerSidebar/AnnulmentHammerBtn
@onready var divine_btn: Button = $HammerSidebar/DivineHammerBtn
@onready var augment_btn: Button = $HammerSidebar/AugmentHammerBtn
@onready var chaos_btn: Button = $HammerSidebar/ChaosHammerBtn
@onready var exalt_btn: Button = $HammerSidebar/ExaltHammerBtn

# Tag hammer button references
@onready var fire_hammer_btn: Button = $HammerSidebar/TagHammerSection/FireHammerBtn
@onready var cold_hammer_btn: Button = $HammerSidebar/TagHammerSection/ColdHammerBtn
@onready var lightning_hammer_btn: Button = $HammerSidebar/TagHammerSection/LightningHammerBtn
@onready var defense_hammer_btn: Button = $HammerSidebar/TagHammerSection/DefenseHammerBtn
@onready var physical_hammer_btn: Button = $HammerSidebar/TagHammerSection/PhysicalHammerBtn
@onready var tag_hammer_section: Control = $HammerSidebar/TagHammerSection

# Stash slot button references (populated in _ready)
var stash_slot_buttons: Dictionary = {}

# Display references
@onready var item_image: TextureRect = $ItemGraphicsPanel/ItemImage
@onready var item_stats_label: Label = $ItemStatsPanel/ItemStatsLabel
@onready var hero_stats_label: RichTextLabel = $HeroStatsPanel/HeroStatsLabel
@onready var inventory_label: Label = $InventoryLabel
@onready var melt_button: Button = $ItemStatsPanel/MeltButton
@onready var equip_button: Button = $ItemStatsPanel/EquipButton
@onready var forge_error_toast: PanelContainer = $ForgeErrorToast
@onready var forge_error_label: Label = $ForgeErrorToast/Label

# Currency instances — each UI button key maps to its matching hammer class
var currencies: Dictionary = {
	"transmute": RunicHammer.new(),
	"augment": AugmentHammer.new(),
	"alchemy": AlchemyHammer.new(),
	"alteration": TackHammer.new(),
	"regal": GrandHammer.new(),
	"chaos": ChaosHammer.new(),
	"exalt": ExaltHammer.new(),
	"divine": DivineHammer.new(),
	"annulment": AnnulmentHammer.new(),
	"fire": TagHammer.new(Tag.FIRE, "Fire Hammer"),
	"cold": TagHammer.new(Tag.COLD, "Cold Hammer"),
	"lightning": TagHammer.new(Tag.LIGHTNING, "Lightning Hammer"),
	"defense": TagHammer.new(Tag.DEFENSE, "Defense Hammer"),
	"physical": TagHammer.new(Tag.PHYSICAL, "Physical Hammer"),
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

# Melt confirmation state
var melt_confirm_pending: bool = false
var melt_timer: Timer

# Hero display state
var equip_hover_active: bool = false

# Hammer tooltip descriptions (shown on hover)
var hammer_descriptions: Dictionary = {
	"transmute": "Turns a normal item into a magic item\nwith 1-2 random mods.\nRequires: Normal rarity",
	"augment": "Adds 1 random mod to a Magic item\nthat has room for another mod.\nRequires: Magic rarity with < max mods",
	"alchemy": "Converts a Normal item to Rare\nwith 4-6 random mods.\nRequires: Normal rarity",
	"alteration": "Rerolls all mods on a magic item.\nRequires: Magic rarity",
	"regal": "Upgrades a magic item to rare\nby adding one mod.\nRequires: Magic rarity",
	"chaos": "Rerolls all mods on a Rare item\nwith 4-6 new random mods.\nRequires: Rare rarity",
	"exalt": "Adds 1 random mod to a Rare item\nthat has room for another mod.\nRequires: Rare rarity with < max mods",
	"divine": "Rerolls mod values within their\ntier ranges.\nRequires: At least one mod",
	"annulment": "Removes 1 random mod from a\nMagic or Rare item.\nRequires: Magic or Rare rarity with at least one mod",
	"fire": "Turns a normal item into a rare item\nwith 4-6 random mods,\nguaranteeing at least one fire mod.\nRequires: Normal rarity, fire mods available",
	"cold": "Turns a normal item into a rare item\nwith 4-6 random mods,\nguaranteeing at least one cold mod.\nRequires: Normal rarity, cold mods available",
	"lightning": "Turns a normal item into a rare item\nwith 4-6 random mods,\nguaranteeing at least one lightning mod.\nRequires: Normal rarity, lightning mods available",
	"defense": "Turns a normal item into a rare item\nwith 4-6 random mods,\nguaranteeing at least one defense mod.\nRequires: Normal rarity, defense mods available",
	"physical": "Turns a normal item into a rare item\nwith 4-6 random mods,\nguaranteeing at least one physical mod.\nRequires: Normal rarity, physical mods available",
}

# 2-letter placeholder codes shown on every hammer button
# (text label overlay; used as primary display when no icon exists)
var hammer_codes: Dictionary = {
	"transmute": "TR",
	"augment": "AU",
	"alchemy": "AL",
	"alteration": "AT",
	"regal": "RG",
	"chaos": "CH",
	"exalt": "EX",
	"divine": "DI",
	"annulment": "AN",
	"fire": "FI",
	"cold": "CO",
	"lightning": "LG",
	"defense": "DF",
	"physical": "PH",
}


func _ready() -> void:
	# Initialize currency button mapping — every key routes to its matching-labeled button
	currency_buttons = {
		"transmute": runic_btn,
		"augment": augment_btn,
		"alchemy": alchemy_btn,
		"alteration": tack_btn,
		"regal": grand_btn,
		"chaos": chaos_btn,
		"exalt": exalt_btn,
		"divine": divine_btn,
		"annulment": annulment_btn,
	}
	currency_buttons["fire"] = fire_hammer_btn
	currency_buttons["cold"] = cold_hammer_btn
	currency_buttons["lightning"] = lightning_hammer_btn
	currency_buttons["defense"] = defense_hammer_btn
	currency_buttons["physical"] = physical_hammer_btn

	# Connect currency button signals
	runic_btn.pressed.connect(_on_currency_selected.bind("transmute"))
	augment_btn.pressed.connect(_on_currency_selected.bind("augment"))
	alchemy_btn.pressed.connect(_on_currency_selected.bind("alchemy"))
	tack_btn.pressed.connect(_on_currency_selected.bind("alteration"))
	grand_btn.pressed.connect(_on_currency_selected.bind("regal"))
	chaos_btn.pressed.connect(_on_currency_selected.bind("chaos"))
	exalt_btn.pressed.connect(_on_currency_selected.bind("exalt"))
	divine_btn.pressed.connect(_on_currency_selected.bind("divine"))
	annulment_btn.pressed.connect(_on_currency_selected.bind("annulment"))

	# Connect tag hammer button signals
	fire_hammer_btn.pressed.connect(_on_currency_selected.bind("fire"))
	cold_hammer_btn.pressed.connect(_on_currency_selected.bind("cold"))
	lightning_hammer_btn.pressed.connect(_on_currency_selected.bind("lightning"))
	defense_hammer_btn.pressed.connect(_on_currency_selected.bind("defense"))
	physical_hammer_btn.pressed.connect(_on_currency_selected.bind("physical"))

	# Set 2-letter placeholder code on every hammer button (visible as text overlay)
	for currency_type in currency_buttons:
		var btn: Button = currency_buttons[currency_type]
		btn.text = hammer_codes[currency_type]

	# Gate tag section on prestige and connect signals
	_update_tag_section_visibility()
	GameEvents.tag_currency_dropped.connect(_on_tag_currency_dropped)
	GameEvents.prestige_completed.connect(_on_prestige_completed)

	# Connect item image click for applying currency
	item_image.gui_input.connect(update_item)

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

	# Create melt confirmation timer
	melt_timer = Timer.new()
	melt_timer.name = "MeltTimer"
	melt_timer.one_shot = true
	melt_timer.wait_time = 3.0
	melt_timer.timeout.connect(_on_melt_timer_timeout)
	add_child(melt_timer)

	# Load current bench item from GameState
	current_item = GameState.crafting_bench

	# Populate stash slot button dictionary from scene tree
	stash_slot_buttons = {
		"weapon": [
			$StashDisplay/WeaponGroup/WeaponSlots/WeaponSlot0,
			$StashDisplay/WeaponGroup/WeaponSlots/WeaponSlot1,
			$StashDisplay/WeaponGroup/WeaponSlots/WeaponSlot2,
		],
		"helmet": [
			$StashDisplay/HelmetGroup/HelmetSlots/HelmetSlot0,
			$StashDisplay/HelmetGroup/HelmetSlots/HelmetSlot1,
			$StashDisplay/HelmetGroup/HelmetSlots/HelmetSlot2,
		],
		"armor": [
			$StashDisplay/ArmorGroup/ArmorSlots/ArmorSlot0,
			$StashDisplay/ArmorGroup/ArmorSlots/ArmorSlot1,
			$StashDisplay/ArmorGroup/ArmorSlots/ArmorSlot2,
		],
		"boots": [
			$StashDisplay/BootsGroup/BootsSlots/BootsSlot0,
			$StashDisplay/BootsGroup/BootsSlots/BootsSlot1,
			$StashDisplay/BootsGroup/BootsSlots/BootsSlot2,
		],
		"ring": [
			$StashDisplay/RingGroup/RingSlots/RingSlot0,
			$StashDisplay/RingGroup/RingSlots/RingSlot1,
			$StashDisplay/RingGroup/RingSlots/RingSlot2,
		],
	}

	# Wire stash slot buttons with tap-to-bench handler
	for slot_type in stash_slot_buttons:
		for i in range(3):
			stash_slot_buttons[slot_type][i].pressed.connect(_on_stash_slot_pressed.bind(slot_type, i))

	# Connect stash_updated signal for live refresh during combat
	GameEvents.stash_updated.connect(_on_stash_updated)

	# Update all displays
	update_inventory_display()
	update_currency_button_states()
	update_item_stats_display()
	update_hero_stats_display()
	update_melt_equip_states()
	_update_stash_display()


# --- Currency selection and application ---


func _on_currency_selected(currency_type: String) -> void:
	# Reset equip confirmation when selecting currency
	if equip_confirm_pending:
		equip_confirm_pending = false
		equip_timer.stop()
		equip_button.text = "Equip"

	# Reset melt confirmation when selecting currency
	if melt_confirm_pending:
		melt_confirm_pending = false
		melt_timer.stop()
		melt_button.text = "Melt"

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
		var msg := selected_currency.get_error_message(current_item)
		if msg != "":
			_show_forge_error(msg)
		return

	# Try to spend the currency (tag currencies use separate spend path)
	var spent: bool = false
	if selected_currency_type in ["fire", "cold", "lightning", "defense", "physical"]:
		spent = GameState.spend_tag_currency(selected_currency_type)
	else:
		spent = GameState.spend_currency(selected_currency_type)
	if not spent:
		print("No " + selected_currency.currency_name + " remaining!")
		return

	# Apply the currency effect
	selected_currency.apply(current_item)
	print("Applied " + selected_currency.currency_name)

	# Update UI
	update_item_stats_display()
	update_currency_button_states()
	current_item.display()


func _update_tag_section_visibility() -> void:
	tag_hammer_section.visible = (GameState.prestige_level >= 1)


# --- Debug shortcuts ---
# F1: grant 1000 of every base hammer (standard currencies)
# F2: grant 1000 of every tag hammer
func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1:
			for currency_type in ["transmute", "augment", "alchemy", "alteration", "regal", "chaos", "exalt", "divine", "annulment"]:
				GameState.currency_counts[currency_type] = 1000
			update_currency_button_states()
			print("DEBUG: +1000 of every base hammer")
			get_viewport().set_input_as_handled()
		KEY_F2:
			for tag_type in ["fire", "cold", "lightning", "defense", "physical"]:
				GameState.tag_currency_counts[tag_type] = 1000
			update_currency_button_states()
			print("DEBUG: +1000 of every tag hammer")
			get_viewport().set_input_as_handled()


func _on_tag_currency_dropped(_drops: Dictionary) -> void:
	update_currency_button_states()


func _on_prestige_completed(_new_level: int) -> void:
	_update_tag_section_visibility()
	update_currency_button_states()


func _show_forge_error(message: String) -> void:
	forge_error_label.text = message
	forge_error_toast.modulate = Color(1.0, 0.4, 0.4, 1.0)
	forge_error_toast.visible = true
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(forge_error_toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): forge_error_toast.visible = false)


func update_currency_button_states() -> void:
	# Update standard currency buttons based on counts from GameState
	var standard_types: Array = ["transmute", "augment", "alchemy", "alteration", "regal", "chaos", "exalt", "divine", "annulment"]
	for currency_type in standard_types:
		var count: int = GameState.currency_counts.get(currency_type, 0)
		var button: Button = currency_buttons[currency_type]

		# Disable button if no currency available
		button.disabled = (count <= 0)

		# Icon-only buttons: update count overlay label, full info on hover
		var count_label: Label = button.get_node("CountLabel")
		count_label.text = str(count)
		button.tooltip_text = currencies[currency_type].currency_name + " (" + str(count) + ")\n" + hammer_descriptions[currency_type]

	# If selected standard currency count is 0, deselect it
	if selected_currency != null and selected_currency_type in standard_types:
		var selected_count: int = GameState.currency_counts.get(selected_currency_type, 0)
		if selected_count <= 0:
			selected_currency = null
			selected_currency_type = ""
			# Untoggle all buttons
			for btn_type in currency_buttons:
				currency_buttons[btn_type].button_pressed = false

	# Tag currency buttons (only relevant when prestige >= 1)
	for tag_type in ["fire", "cold", "lightning", "defense", "physical"]:
		var count: int = GameState.tag_currency_counts.get(tag_type, 0)
		var button: Button = currency_buttons[tag_type]
		button.disabled = (count <= 0)
		button.text = hammer_codes[tag_type] + " (" + str(count) + ")"
		button.tooltip_text = currencies[tag_type].currency_name + " (" + str(count) + ")\n" + hammer_descriptions[tag_type]

	# Deselect if selected tag currency is now 0
	if selected_currency_type in ["fire", "cold", "lightning", "defense", "physical"]:
		if GameState.tag_currency_counts.get(selected_currency_type, 0) <= 0:
			selected_currency = null
			selected_currency_type = ""
			for btn_type in currency_buttons:
				currency_buttons[btn_type].button_pressed = false


# --- Stash display ---


func _get_item_abbreviation(item: Item) -> String:
	if item is Broadsword: return "BS"
	if item is Battleaxe: return "BA"
	if item is Warhammer: return "WH"
	if item is Dagger: return "DA"
	if item is VenomBlade: return "VB"
	if item is Shortbow: return "SB"
	if item is Wand: return "WN"
	if item is LightningRod: return "LR"
	if item is Sceptre: return "SC"
	if item is IronHelm: return "IH"
	if item is LeatherHood: return "LH"
	if item is Circlet: return "CI"
	if item is IronPlate: return "IP"
	if item is LeatherVest: return "LV"
	if item is SilkRobe: return "SR"
	if item is IronGreaves: return "IG"
	if item is LeatherBoots: return "LB"
	if item is SilkSlippers: return "SS"
	if item is IronBand: return "IB"
	if item is JadeRing: return "JR"
	if item is SapphireRing: return "SP"
	return "??"


func _build_stash_tooltip(item: Item) -> String:
	return item.get_display_text()


func _update_stash_display() -> void:
	for slot_type in stash_slot_buttons:
		var items: Array = GameState.stash.get(slot_type, [])
		for i in range(3):
			var btn: Button = stash_slot_buttons[slot_type][i]
			if i < items.size() and items[i] != null:
				var item: Item = items[i]
				btn.text = _get_item_abbreviation(item)
				btn.tooltip_text = _build_stash_tooltip(item)
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
				btn.disabled = false
			else:
				btn.text = ""
				btn.tooltip_text = ""
				btn.modulate = Color(0.4, 0.4, 0.4, 1.0)
				btn.disabled = true


func _on_stash_updated(_slot: String) -> void:
	_update_stash_display()


func _on_stash_slot_pressed(slot_type: String, index: int) -> void:
	# D-05: bench must be empty to load from stash
	if GameState.crafting_bench != null:
		_show_forge_error("Melt or equip first")
		return

	var items: Array = GameState.stash.get(slot_type, [])
	if index >= items.size() or items[index] == null:
		return  # Empty slot guard

	# Transfer item from stash to bench
	var item: Item = items[index]
	# D-08: set null to leave a gap — remaining items do not shift to fill it
	items[index] = null
	GameState.crafting_bench = item
	current_item = item

	# Refresh all displays
	update_current_item()
	_update_stash_display()
	update_melt_equip_states()
	update_inventory_display()


func _pulse_stash_slots() -> void:
	# Defer by one frame so the disabled->enabled theme transition completes before tween starts,
	# preventing a visual double-pulse (theme pop + tween pulse).
	call_deferred("_pulse_stash_slots_impl")


func _pulse_stash_slots_impl() -> void:
	for slot_type in stash_slot_buttons:
		for i in range(3):
			var btn: Button = stash_slot_buttons[slot_type][i]
			if not btn.disabled:
				# Reset modulate to a known clean state before tweening to avoid theme-transition pop
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
				var tween := create_tween()
				tween.tween_property(btn, "modulate:a", 0.4, 0.15)
				tween.tween_property(btn, "modulate:a", 1.0, 0.15)


func update_current_item() -> void:
	current_item = GameState.crafting_bench
	if current_item != null:
		print("Selected ", current_item.item_name, " for crafting")
	else:
		print("No item on bench")
	update_item_stats_display()


func get_selected_item_type() -> String:
	if GameState.crafting_bench == null:
		return ""
	return get_item_type(GameState.crafting_bench)


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

	# Two-click confirmation (mirrors equip confirmation pattern)
	if not melt_confirm_pending:
		melt_confirm_pending = true
		melt_button.text = "Confirm Melt?"
		melt_timer.start()
		return

	# Second click — execute melt
	melt_confirm_pending = false
	melt_timer.stop()
	melt_button.text = "Melt"

	var slot_name: String = get_item_type(current_item)
	print("Melted: ", current_item.item_name)

	# Clear the bench
	GameState.crafting_bench = null
	current_item = null

	# Reset equip confirm state if active
	equip_confirm_pending = false
	equip_timer.stop()
	equip_button.text = "Equip"

	update_item_stats_display()
	update_melt_equip_states()
	update_inventory_display()
	_update_stash_display()
	_pulse_stash_slots()


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

	# Reset melt confirm if active
	melt_confirm_pending = false
	melt_timer.stop()
	melt_button.text = "Melt"

	# Second click (confirmed) or empty slot — do the equip
	equip_confirm_pending = false
	equip_timer.stop()
	equip_button.text = "Equip"

	# Equip the item (old item in slot is destroyed)
	GameState.hero.equip_item(current_item, slot_name)
	GameEvents.equipment_changed.emit(slot_name, current_item)
	GameEvents.item_crafted.emit(current_item)
	print("Equipped: ", current_item.item_name, " to ", slot_name)

	# Clear bench after equip
	GameState.crafting_bench = null
	current_item = null

	# Update all displays
	update_hero_stats_display()
	update_item_stats_display()
	update_melt_equip_states()
	update_inventory_display()
	_update_stash_display()
	_pulse_stash_slots()
	equipment_changed.emit()


func _on_equip_timer_timeout() -> void:
	equip_confirm_pending = false
	equip_button.text = "Equip"


func _on_melt_timer_timeout() -> void:
	melt_confirm_pending = false
	melt_button.text = "Melt"


func update_melt_equip_states() -> void:
	var has_item: bool = current_item != null
	melt_button.disabled = not has_item
	equip_button.disabled = not has_item


# --- Inventory management ---


func add_item_to_inventory(_item: Item) -> void:
	# Phase 55: dead code — drops route through GameState.add_item_to_stash
	# Kept as stub for Phase 57 potential reuse
	push_warning("ForgeView.add_item_to_inventory called — should use GameState.add_item_to_stash")


func set_new_item_base(_item_base: Item) -> void:
	# Phase 55: dead code — drops route through GameState.add_item_to_stash via MainView
	push_warning("ForgeView.set_new_item_base called — should use GameState.add_item_to_stash")


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


func get_best_item(slot_name: String) -> Item:
	## Returns the bench item if it matches the slot, or null.
	if GameState.crafting_bench != null and get_item_type(GameState.crafting_bench) == slot_name:
		return GameState.crafting_bench
	return null


# --- Display updates ---


func update_inventory_display() -> void:
	if inventory_label == null:
		return

	if GameState.crafting_bench != null:
		var item: Item = GameState.crafting_bench
		var rarity_name: String = "Normal"
		match item.rarity:
			Item.Rarity.MAGIC:
				rarity_name = "Magic"
			Item.Rarity.RARE:
				rarity_name = "Rare"
		inventory_label.text = "Bench: " + item.item_name + " (" + rarity_name + ")"
	else:
		inventory_label.text = "Bench: Empty"


func update_item_stats_display() -> void:
	if item_stats_label == null:
		return

	if current_item != null:
		item_stats_label.text = get_item_stats_text(current_item)
		item_stats_label.modulate = current_item.get_rarity_color()
	else:
		item_stats_label.text = "No item on bench"
		item_stats_label.modulate = Color.WHITE


func update_hero_stats_display() -> void:
	if hero_stats_label == null:
		return

	# If hovering the Equip button, show stat comparison
	if equip_hover_active and current_item != null:
		hero_stats_label.text = get_stat_comparison_text()
		return

	# Default: show aggregate hero stats
	var hero: Hero = GameState.hero

	# Reset color to white for default view
	hero_stats_label.modulate = Color.WHITE

	# Hero archetype section (per D-01: before Offense, per D-04: null = no section)
	var archetype: HeroArchetype = GameState.hero_archetype
	if archetype != null:
		var hex: String = archetype.color.to_html(false)
		hero_stats_label.text = "[color=#%s]%s[/color]\n" % [hex, archetype.title]
		hero_stats_label.text += "Passive:\n"
		for line in HeroArchetype.format_bonuses(archetype.passive_bonuses):
			hero_stats_label.text += "  %s\n" % line
		hero_stats_label.text += "\n"
	else:
		hero_stats_label.text = ""

	# Offense section
	hero_stats_label.text += "Offense:\n"
	var attack_dps := hero.get_total_dps()
	var spell_dps_val := hero.get_total_spell_dps()
	if attack_dps > 0 or spell_dps_val == 0:
		hero_stats_label.text += "Attack DPS: %.1f\n" % attack_dps
	if spell_dps_val > 0:
		hero_stats_label.text += "Spell DPS: %.1f\n" % spell_dps_val
	var dot_dps_val := hero.get_total_dot_dps()
	if dot_dps_val > 0:
		hero_stats_label.text += "DoT DPS: %.1f\n" % dot_dps_val
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

	var total_chaos_res: int = hero.get_total_chaos_resistance()
	if total_chaos_res > 0:
		hero_stats_label.text += "Chaos Resistance: %d\n" % total_chaos_res
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
		var eq_spell_dps: float = 0.0
		var eq_crit_chance: float = 5.0
		var eq_crit_damage: float = 150.0
		if equipped != null and equipped is Weapon:
			var eq_weapon: Weapon = equipped as Weapon
			eq_dps = eq_weapon.dps
			eq_spell_dps = eq_weapon.spell_dps
			eq_crit_chance = eq_weapon.crit_chance
			eq_crit_damage = eq_weapon.crit_damage
		text += format_stat_delta("Attack DPS", eq_dps, crafted.dps) + "\n"
		if crafted.spell_dps > 0 or eq_spell_dps > 0:
			text += format_stat_delta("Spell DPS", eq_spell_dps, crafted.spell_dps) + "\n"
		text += "Damage: %d-%d" % [crafted.base_damage_min, crafted.base_damage_max]
		if equipped != null and equipped is Weapon:
			var eq_w: Weapon = equipped as Weapon
			text += " (was %d-%d)" % [eq_w.base_damage_min, eq_w.base_damage_max]
		text += "\n"
		text += format_stat_delta("Crit Chance", eq_crit_chance, crafted.crit_chance, "%.1f%%") + "\n"
		text += format_stat_delta("Crit Damage", eq_crit_damage, crafted.crit_damage, "%.1f%%") + "\n"

	# Ring stats (same as weapon — DPS and crit)
	elif current_item is Ring:
		var crafted: Ring = current_item as Ring
		var eq_dps: float = 0.0
		var eq_spell_dps: float = 0.0
		var eq_crit_chance: float = 5.0
		var eq_crit_damage: float = 150.0
		if equipped != null and equipped is Ring:
			var eq_ring: Ring = equipped as Ring
			eq_dps = eq_ring.dps
			eq_spell_dps = eq_ring.spell_dps
			eq_crit_chance = eq_ring.crit_chance
			eq_crit_damage = eq_ring.crit_damage
		text += format_stat_delta("Attack DPS", eq_dps, crafted.dps) + "\n"
		if crafted.spell_dps > 0 or eq_spell_dps > 0:
			text += format_stat_delta("Spell DPS", eq_spell_dps, crafted.spell_dps) + "\n"
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
			eq_armor = eq_item.computed_armor
			eq_evasion = eq_item.computed_evasion
			eq_es = eq_item.computed_energy_shield
			eq_health = eq_item.computed_health
		text += format_stat_delta_int("Armor", eq_armor, crafted.computed_armor) + "\n"
		if crafted.computed_evasion > 0 or eq_evasion > 0:
			text += format_stat_delta_int("Evasion", eq_evasion, crafted.computed_evasion) + "\n"
		if crafted.computed_energy_shield > 0 or eq_es > 0:
			text += format_stat_delta_int("Energy Shield", eq_es, crafted.computed_energy_shield) + "\n"
		if crafted.computed_health > 0 or eq_health > 0:
			text += format_stat_delta_int("Health", eq_health, crafted.computed_health) + "\n"

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
			eq_armor = eq_item.computed_armor
			eq_evasion = eq_item.computed_evasion
			eq_es = eq_item.computed_energy_shield
			eq_health = eq_item.computed_health
			eq_mana = eq_item.computed_mana
		text += format_stat_delta_int("Armor", eq_armor, crafted.computed_armor) + "\n"
		if crafted.computed_evasion > 0 or eq_evasion > 0:
			text += format_stat_delta_int("Evasion", eq_evasion, crafted.computed_evasion) + "\n"
		if crafted.computed_energy_shield > 0 or eq_es > 0:
			text += format_stat_delta_int("Energy Shield", eq_es, crafted.computed_energy_shield) + "\n"
		if crafted.computed_health > 0 or eq_health > 0:
			text += format_stat_delta_int("Health", eq_health, crafted.computed_health) + "\n"
		if crafted.computed_mana > 0 or eq_mana > 0:
			text += format_stat_delta_int("Mana", eq_mana, crafted.computed_mana) + "\n"

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
			eq_armor = eq_item.computed_armor
			eq_evasion = eq_item.computed_evasion
			eq_es = eq_item.computed_energy_shield
			eq_health = eq_item.computed_health
			eq_ms = eq_item.computed_movement_speed
		text += format_stat_delta_int("Armor", eq_armor, crafted.computed_armor) + "\n"
		if crafted.computed_evasion > 0 or eq_evasion > 0:
			text += format_stat_delta_int("Evasion", eq_evasion, crafted.computed_evasion) + "\n"
		if crafted.computed_energy_shield > 0 or eq_es > 0:
			text += format_stat_delta_int("Energy Shield", eq_es, crafted.computed_energy_shield) + "\n"
		if crafted.computed_movement_speed > 0 or eq_ms > 0:
			text += format_stat_delta_int("Movement Speed", eq_ms, crafted.computed_movement_speed) + "\n"
		if crafted.computed_health > 0 or eq_health > 0:
			text += format_stat_delta_int("Health", eq_health, crafted.computed_health) + "\n"

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


func _format_affix_line(affix: Affix) -> String:
	var tier_suffix := " (T%d)" % affix.tier
	var flat_damage_stats := [
		Tag.StatType.FLAT_DAMAGE,
		Tag.StatType.FLAT_SPELL_DAMAGE,
		Tag.StatType.BLEED_DAMAGE,
		Tag.StatType.POISON_DAMAGE,
		Tag.StatType.BURN_DAMAGE,
	]
	var has_flat_damage := false
	for stat in affix.stat_types:
		if stat in flat_damage_stats:
			has_flat_damage = true
			break
	if has_flat_damage and (affix.add_min > 0 or affix.add_max > 0):
		var element_name := _get_affix_element_name(affix.tags)
		return "Adds %d to %d %s Damage%s" % [affix.add_min, affix.add_max, element_name, tier_suffix]
	return affix.affix_name + ": " + str(affix.value) + tier_suffix


func _get_affix_element_name(tags: Array) -> String:
	if Tag.SPELL in tags:
		return "Spell"
	if Tag.DOT in tags:
		if Tag.CHAOS in tags:
			return "Poison"
		if Tag.FIRE in tags:
			return "Burn"
		if Tag.PHYSICAL in tags:
			return "Bleed"
		return "DoT"
	if Tag.FIRE in tags:
		return "Fire"
	if Tag.COLD in tags:
		return "Cold"
	if Tag.LIGHTNING in tags:
		return "Lightning"
	return "Physical"


func get_item_stats_text(item: Item) -> String:
	var rarity_name: String = "Normal"
	match item.rarity:
		Item.Rarity.MAGIC:
			rarity_name = "Magic"
		Item.Rarity.RARE:
			rarity_name = "Rare"
	var tier_label: String = ""
	if GameState.prestige_level >= 1:
		tier_label = " — T%d" % item.tier
	var stats_text: String = item.item_name + " (" + rarity_name + ")" + tier_label + "\n\n"

	if item is Weapon:
		var weapon: Weapon = item as Weapon
		stats_text += "DPS: %.1f\n" % weapon.dps
		stats_text += "Damage: %d to %d\n" % [weapon.base_damage_min, weapon.base_damage_max]
		stats_text += "Base Speed: %.1f\n" % weapon.base_speed
		if weapon.base_spell_damage_min > 0 or weapon.base_spell_damage_max > 0:
			stats_text += "Spell Damage: %d to %d\n" % [weapon.base_spell_damage_min, weapon.base_spell_damage_max]
		if weapon.base_cast_speed > 0:
			stats_text += "Cast Speed: %.1f\n" % weapon.base_cast_speed
		if weapon.spell_dps > 0:
			stats_text += "Spell DPS: %.1f\n" % weapon.spell_dps
		stats_text += "Crit Chance: %.1f%%\n" % weapon.crit_chance
		stats_text += "Crit Damage: %.1f%%\n" % weapon.crit_damage

		if weapon.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += weapon.implicit.affix_name + ": " + str(weapon.implicit.value) + "\n"

		if weapon.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in weapon.prefixes:
				stats_text += _format_affix_line(prefix) + "\n"

		if weapon.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in weapon.suffixes:
				stats_text += _format_affix_line(suffix) + "\n"
	elif item is Armor:
		var armor_item: Armor = item as Armor
		stats_text += "Armor: %d\n" % armor_item.computed_armor
		if armor_item.computed_evasion > 0:
			stats_text += "Evasion: %d\n" % armor_item.computed_evasion
		if armor_item.computed_energy_shield > 0:
			stats_text += "Energy Shield: %d\n" % armor_item.computed_energy_shield
		if armor_item.computed_health > 0:
			stats_text += "Health: %d\n" % armor_item.computed_health

		if armor_item.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += armor_item.implicit.affix_name + ": " + str(armor_item.implicit.value) + "\n"

		if armor_item.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in armor_item.prefixes:
				stats_text += _format_affix_line(prefix) + "\n"

		if armor_item.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in armor_item.suffixes:
				stats_text += _format_affix_line(suffix) + "\n"
	elif item is Boots:
		var boots_item: Boots = item as Boots
		stats_text += "Armor: %d\n" % boots_item.computed_armor
		if boots_item.computed_evasion > 0:
			stats_text += "Evasion: %d\n" % boots_item.computed_evasion
		if boots_item.computed_energy_shield > 0:
			stats_text += "Energy Shield: %d\n" % boots_item.computed_energy_shield
		stats_text += "Movement Speed: %d\n" % boots_item.computed_movement_speed
		if boots_item.computed_health > 0:
			stats_text += "Health: %d\n" % boots_item.computed_health

		if boots_item.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += boots_item.implicit.affix_name + ": " + str(boots_item.implicit.value) + "\n"

		if boots_item.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in boots_item.prefixes:
				stats_text += _format_affix_line(prefix) + "\n"

		if boots_item.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in boots_item.suffixes:
				stats_text += _format_affix_line(suffix) + "\n"
	elif item is Helmet:
		var helmet_item: Helmet = item as Helmet
		stats_text += "Armor: %d\n" % helmet_item.computed_armor
		if helmet_item.computed_evasion > 0:
			stats_text += "Evasion: %d\n" % helmet_item.computed_evasion
		if helmet_item.computed_energy_shield > 0:
			stats_text += "Energy Shield: %d\n" % helmet_item.computed_energy_shield
		if helmet_item.computed_mana > 0:
			stats_text += "Mana: %d\n" % helmet_item.computed_mana
		if helmet_item.computed_health > 0:
			stats_text += "Health: %d\n" % helmet_item.computed_health

		if helmet_item.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += helmet_item.implicit.affix_name + ": " + str(helmet_item.implicit.value) + "\n"

		if helmet_item.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in helmet_item.prefixes:
				stats_text += _format_affix_line(prefix) + "\n"

		if helmet_item.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in helmet_item.suffixes:
				stats_text += _format_affix_line(suffix) + "\n"
	elif item is Ring:
		var ring_item: Ring = item as Ring
		stats_text += "DPS: %.1f\n" % ring_item.dps
		if ring_item.base_cast_speed > 0:
			stats_text += "Cast Speed: %.1f\n" % ring_item.base_cast_speed
		if ring_item.spell_dps > 0:
			stats_text += "Spell DPS: %.1f\n" % ring_item.spell_dps
		stats_text += "Crit Chance: %.1f%%\n" % ring_item.crit_chance
		stats_text += "Crit Damage: %.1f%%\n" % ring_item.crit_damage

		if ring_item.implicit:
			stats_text += "\nImplicit:\n"
			stats_text += ring_item.implicit.affix_name + ": " + str(ring_item.implicit.value) + "\n"

		if ring_item.prefixes.size() > 0:
			stats_text += "\nPrefixes:\n"
			for prefix in ring_item.prefixes:
				stats_text += _format_affix_line(prefix) + "\n"

		if ring_item.suffixes.size() > 0:
			stats_text += "\nSuffixes:\n"
			for suffix in ring_item.suffixes:
				stats_text += _format_affix_line(suffix) + "\n"
	else:
		stats_text += "(Unknown item type)"

	return stats_text
