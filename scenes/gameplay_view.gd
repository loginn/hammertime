extends Node2D

signal item_base_found(item_base: Item)
signal currencies_found(drops: Dictionary)

@onready var start_clearing_button: Button = $StartClearingButton
@onready var next_area_button: Button = $NextAreaButton
@onready var clearing_timer: Timer = $ClearingTimer
@onready var materials_label: Label = $MaterialsLabel
@onready var area_label: Label = $AreaLabel

var hero_clearing: bool = false
var current_area: String = "Forest"
var item_bases_collected: Array = []
var base_clearing_time: float = 3.0  # Base time in seconds

# Area scaling system
var area_level: int = 1
var area_difficulty_multiplier: float = 1.0


func _ready() -> void:
	item_bases_collected = []
	update_area_difficulty()
	start_clearing_button.pressed.connect(_on_start_clearing_pressed)
	next_area_button.pressed.connect(_on_next_area_pressed)
	clearing_timer.timeout.connect(_on_clearing_timer_timeout)
	update_display()


func _on_start_clearing_pressed() -> void:
	if not hero_clearing:
		start_clearing()
	else:
		stop_clearing()


func _on_next_area_pressed() -> void:
	# Manually advance to next area
	area_level += 1
	update_area_difficulty()
	update_clearing_speed()
	update_display()
	print("Manually advanced to ", current_area, "!")


func start_clearing() -> void:
	hero_clearing = true
	print("Hero started clearing ", current_area)

	# Calculate clearing speed based on hero DPS
	update_clearing_speed()

	# Start the clearing timer
	clearing_timer.start()
	print("Clearing timer started with wait time: ", clearing_timer.wait_time)

	# Update button text
	start_clearing_button.text = "Stop Clearing"

	update_display()


func stop_clearing() -> void:
	hero_clearing = false
	print("Hero stopped clearing")

	# Stop the clearing timer
	clearing_timer.stop()

	# Update button text
	start_clearing_button.text = "Start Clearing"

	update_display()


func _on_clearing_timer_timeout() -> void:
	# Hero clears an area and gets materials
	print("Clearing timer timeout! Hero clearing area...")
	clear_area()


func clear_area() -> void:
	# Hero takes damage while clearing
	take_damage()

	# If hero died, don't continue
	if not GameState.hero.is_healthy():
		return

	# Recharge ES between fights (33% of max)
	GameState.hero.recharge_energy_shield()

	# Determine how many items drop this clear (scales with area level)
	var item_count: int = LootTable.get_item_drop_count(area_level)

	for i in range(item_count):
		# Generate and drop an item base
		var item_base: Item = get_random_item_base()

		if item_base != null:
			# Add item base to collection
			item_bases_collected.append(item_base)
			print("Hero cleared area and found: ", item_base.item_name)

			# Give the item base to crafting view (emits per item)
			item_base_found.emit(item_base)

	# Emit area cleared signal once per clear (not per item)
	GameEvents.area_cleared.emit(area_level)

	# Hero finds random hammers in the area (once per clear)
	give_hammer_rewards()

	# Chance to advance to next area level
	check_area_progression()

	update_display()


func give_hammer_rewards() -> void:
	# Roll currency drops based on area level
	var drops = LootTable.roll_currency_drops(area_level)

	# Store drops in GameState
	GameState.add_currencies(drops)

	# Print what dropped
	print("Currency drops:")
	for currency_name in drops:
		print("  ", currency_name, ": ", drops[currency_name])

	# Emit signal for UI update
	currencies_found.emit(drops)


func check_area_progression() -> void:
	# 10% chance to advance to next area level when clearing an area
	if randf() < 0.1:
		area_level += 1
		update_area_difficulty()
		update_clearing_speed()  # Update clearing speed for new difficulty
		print("Hero advanced to ", current_area, "!")


func get_random_item_base() -> Item:
	# Randomly generate different item types
	var item_types = [LightSword, BasicHelmet, BasicArmor, BasicBoots, BasicRing]
	var random_type = item_types[randi() % item_types.size()]
	var item = random_type.new()

	# Roll rarity based on area level
	var rarity = LootTable.roll_rarity(area_level)

	# Apply rarity and mods
	LootTable.spawn_item_with_mods(item, rarity)

	# Print drop result
	var rarity_name = ""
	match rarity:
		Item.Rarity.NORMAL:
			rarity_name = "Normal"
		Item.Rarity.MAGIC:
			rarity_name = "Magic"
		Item.Rarity.RARE:
			rarity_name = "Rare"

	print("Dropped: ", item.item_name, " (", rarity_name, ")")

	return item


func update_clearing_speed() -> void:
	# Get hero's total DPS from the hero instance
	var hero_dps = GameState.hero.get_total_dps()
	print("Hero DPS calculated: ", hero_dps)

	# Calculate clearing time based on DPS and area difficulty
	# Higher DPS = faster clearing (lower time)
	# Higher area level = slower clearing (higher time)
	# Formula: clearing_time = (base_time * area_difficulty_multiplier) / (1 + dps/10)
	var base_time_with_difficulty = base_clearing_time * area_difficulty_multiplier
	var clearing_time = base_time_with_difficulty / (1.0 + hero_dps / 10.0)

	# Set minimum clearing time to prevent it from being too fast
	clearing_time = max(clearing_time, 0.3)

	# Update the timer
	clearing_timer.wait_time = clearing_time

	print(
		"Area Level: ",
		area_level,
		" (",
		area_difficulty_multiplier,
		"x) - Hero DPS: ",
		hero_dps,
		" - Clearing time: ",
		clearing_time,
		" seconds"
	)


func update_display() -> void:
	# Update item bases display
	var display_text = "Item Bases Found:\n\n"

	if item_bases_collected.size() > 0:
		# Count each type of item base
		var item_counts = {}
		for item_base in item_bases_collected:
			var item_name = item_base.item_name
			if item_name in item_counts:
				item_counts[item_name] += 1
			else:
				item_counts[item_name] = 1

		# Display counts
		for item_name in item_counts:
			display_text += item_name + ": " + str(item_counts[item_name]) + "\n"
	else:
		display_text += "No item bases found yet\n"

	display_text += "\n"

	# Show hero health
	display_text += (
		"Hero Health: " + "%.0f" % GameState.hero.health + "/" + "%.0f" % GameState.hero.max_health + "\n"
	)
	display_text += "Area: " + current_area + " (Level " + str(area_level) + ")\n"

	# Show monster damage and defense info
	var base_monster_damage := 10.0 * area_difficulty_multiplier
	display_text += "Monster Damage: " + "%.1f" % base_monster_damage + " (raw)\n"

	# Show defense summary
	var hero := GameState.hero
	if hero.get_total_armor() > 0:
		var armor_red := DefenseCalculator.calculate_armor_reduction(
			hero.get_total_armor(), base_monster_damage
		)
		display_text += (
			"Armor: " + str(hero.get_total_armor()) + " (%.0f%% vs current hits)\n" % [armor_red * 100.0]
		)
	if hero.get_total_evasion() > 0:
		var dodge := DefenseCalculator.calculate_dodge_chance(hero.get_total_evasion())
		display_text += (
			"Evasion: " + str(hero.get_total_evasion()) + " (%.0f%% dodge)\n" % [dodge * 100.0]
		)
	if hero.get_total_energy_shield() > 0:
		display_text += (
			"ES: "
			+ "%.0f" % hero.get_current_energy_shield()
			+ "/"
			+ str(hero.get_total_energy_shield())
			+ "\n"
		)
	display_text += "\n"

	if hero_clearing:
		var clearing_time = clearing_timer.wait_time
		display_text += "Hero is clearing " + current_area + "...\n"
		display_text += "Clearing time: " + "%.1f" % clearing_time + "s"
	else:
		display_text += "Hero is resting"

	materials_label.text = display_text

	# Update area display
	area_label.text = "Current Area: " + current_area


func refresh_clearing_speed() -> void:
	# Update clearing speed if hero is currently clearing
	if hero_clearing:
		update_clearing_speed()

	# Update display to show new damage values
	update_display()


func update_area_difficulty() -> void:
	# Calculate area difficulty multiplier based on area level
	# Gentler scaling for expanded 1-300+ area range
	area_difficulty_multiplier = 1.0 + (area_level - 1) * 0.02

	# Update area name based on tier thresholds
	if area_level < 100:
		current_area = "Forest"
	elif area_level < 200:
		current_area = "Dark Forest"
	elif area_level < 300:
		current_area = "Cursed Woods"
	else:
		current_area = "Shadow Realm"

	print(
		"Area difficulty updated: Level ",
		area_level,
		" - ",
		current_area,
		" (",
		area_difficulty_multiplier,
		"x difficulty)"
	)


func calculate_and_apply_damage() -> void:
	# Base monster damage scales with area difficulty
	var base_monster_damage := 10.0 * area_difficulty_multiplier

	# For now, all damage is physical attacks (Phase 14 adds elemental types)
	var damage_type := "physical"
	var is_spell := false

	# Get hero defense stats
	var hero := GameState.hero
	var result := DefenseCalculator.calculate_damage_taken(
		base_monster_damage,
		damage_type,
		is_spell,
		hero.get_total_armor(),
		hero.get_total_evasion(),
		hero.get_total_energy_shield(),
		hero.get_total_fire_resistance(),
		hero.get_total_cold_resistance(),
		hero.get_total_lightning_resistance(),
		hero.get_current_energy_shield()
	)

	if result["dodged"]:
		print("Hero dodged the attack!")
		return

	# Apply defense-aware damage split
	hero.apply_damage(result["life_damage"], result["es_damage"])

	# Print combat feedback
	if result["es_damage"] > 0.0:
		print(
			"Hero took %.1f life damage and %.1f ES damage (%.1f total mitigated from %.1f raw)"
			% [
				result["life_damage"],
				result["es_damage"],
				result["life_damage"] + result["es_damage"],
				base_monster_damage,
			]
		)
	else:
		print(
			"Hero took %.1f damage (mitigated from %.1f raw)"
			% [result["life_damage"], base_monster_damage]
		)


func take_damage() -> void:
	# Hero takes damage from monsters while clearing
	calculate_and_apply_damage()

	# Check if hero died
	if not GameState.hero.is_healthy():
		hero_died()


func hero_died() -> void:
	print("Hero died! Stopping clearing.")
	stop_clearing()
	GameState.hero.revive()  # Resurrect with full health
	print("Hero resurrected with full health!")
