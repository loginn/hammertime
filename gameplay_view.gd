extends Node2D

var hero_clearing: bool = false
var current_area: String = "Forest"
var item_bases_collected: Array = []
var hero_view: Node = null
var crafting_view: Node = null
var base_clearing_time: float = 3.0  # Base time in seconds

# Area scaling system
var area_level: int = 1
var area_difficulty_multiplier: float = 1.0

# Hero instance
var hero: Hero

func _ready():
	# Try to find other views
	hero_view = get_node_or_null("../HeroView")
	if hero_view == null:
		hero_view = get_node_or_null("HeroView")
	
	crafting_view = get_node_or_null("../CraftingView")
	if crafting_view == null:
		crafting_view = get_node_or_null("CraftingView")
	
	# Get hero instance from hero_view
	if hero_view:
		hero = hero_view.hero
	
	# Initialize item bases collection
	item_bases_collected = []
	
	# Initialize area scaling
	update_area_difficulty()
	
	# Connect buttons
	if has_node("StartClearingButton"):
		$StartClearingButton.connect("pressed", _on_start_clearing_pressed)
	
	if has_node("NextAreaButton"):
		$NextAreaButton.connect("pressed", _on_next_area_pressed)
	
	# Manually connect the timer signal to make sure it works
	if has_node("ClearingTimer"):
		$ClearingTimer.connect("timeout", _on_clearing_timer_timeout)
		print("ClearingTimer signal connected manually")
	
	update_display()

func _on_start_clearing_pressed():
	if not hero_clearing:
		start_clearing()
	else:
		stop_clearing()

func _on_next_area_pressed():
	# Manually advance to next area
	area_level += 1
	update_area_difficulty()
	update_clearing_speed()
	update_display()
	print("Manually advanced to ", current_area, "!")

func start_clearing():
	hero_clearing = true
	print("Hero started clearing ", current_area)
	
	# Check if hero view is found
	if hero_view == null:
		print("ERROR: Hero view not found! Cannot calculate DPS.")
		return
	
	# Calculate clearing speed based on hero DPS
	update_clearing_speed()
	
	# Start the clearing timer
	$ClearingTimer.start()
	print("Clearing timer started with wait time: ", $ClearingTimer.wait_time)
	
	# Update button text
	if has_node("StartClearingButton"):
		$StartClearingButton.text = "Stop Clearing"
	
	update_display()

func stop_clearing():
	hero_clearing = false
	print("Hero stopped clearing")
	
	# Stop the clearing timer
	$ClearingTimer.stop()
	
	# Update button text
	if has_node("StartClearingButton"):
		$StartClearingButton.text = "Start Clearing"
	
	update_display()

func _on_clearing_timer_timeout():
	# Hero clears an area and gets materials
	print("Clearing timer timeout! Hero clearing area...")
	clear_area()

func clear_area():
	# Hero takes damage while clearing
	take_damage()
	
	# If hero died, don't continue
	if not hero.is_healthy():
		return
	
	# Simulate clearing an area and getting an item base
	var item_base = get_random_item_base()
	
	if item_base != null:
		# Add item base to collection
		item_bases_collected.append(item_base)
		print("Hero cleared area and found: ", item_base.item_name)
		
		# Give the item base to crafting view
		if crafting_view:
			crafting_view.set_new_item_base(item_base)
		
		# Hero finds random hammers in the area
		give_hammer_rewards()
		
		# Chance to advance to next area level
		check_area_progression()
	
	update_display()

func give_hammer_rewards():
	# Hero finds random hammers in the area
	var implicit_hammers = randi_range(1, 3)  # 1-3 implicit hammers
	var prefix_hammers = randi_range(1, 2)    # 1-2 prefix hammers
	var suffix_hammers = randi_range(1, 2)    # 1-2 suffix hammers
	
	# Give hammers to crafting view
	if crafting_view:
		crafting_view.add_hammers(implicit_hammers, prefix_hammers, suffix_hammers)

func check_area_progression():
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
	return random_type.new()

func update_clearing_speed():
	if hero_view == null:
		print("ERROR: Hero view is null in update_clearing_speed()")
		return
	
	# Get hero's total DPS from the hero instance
	var hero_dps = hero.get_total_dps()
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
	$ClearingTimer.wait_time = clearing_time
	
	print("Area Level: ", area_level, " (", area_difficulty_multiplier, "x) - Hero DPS: ", hero_dps, " - Clearing time: ", clearing_time, " seconds")

func update_display():
	# Update item bases display
	if has_node("MaterialsLabel"):
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
		display_text += "Hero Health: " + "%.0f" % hero.health + "/" + "%.0f" % hero.max_health + "\n"
		display_text += "Area: " + current_area + " (Level " + str(area_level) + ")\n"
		
		# Show monster damage info
		var monster_damage = calculate_monster_damage()
		display_text += "Monster Damage: " + "%.1f" % monster_damage + "\n\n"
		
		if hero_clearing:
			var clearing_time = $ClearingTimer.wait_time
			display_text += "Hero is clearing " + current_area + "...\n"
			display_text += "Clearing time: " + "%.1f" % clearing_time + "s"
		else:
			display_text += "Hero is resting"
		
		$MaterialsLabel.text = display_text
	
	# Update area display
	if has_node("AreaLabel"):
		$AreaLabel.text = "Current Area: " + current_area

func refresh_clearing_speed():
	# Update clearing speed if hero is currently clearing
	if hero_clearing:
		update_clearing_speed()
	
	# Update display to show new damage values
	update_display()

func update_area_difficulty():
	# Calculate area difficulty multiplier based on area level
	# Each level increases difficulty by 1.5x
	area_difficulty_multiplier = 1.0 + (area_level - 1) * 0.5
	
	# Update area name based on level
	match area_level:
		1:
			current_area = "Forest"
		2:
			current_area = "Dark Forest"
		3:
			current_area = "Cursed Woods"
		4:
			current_area = "Shadow Realm"
		_:
			current_area = "Area Level " + str(area_level)
	
	print("Area difficulty updated: Level ", area_level, " - ", current_area, " (", area_difficulty_multiplier, "x difficulty)")

func calculate_monster_damage() -> float:
	# Get hero's total defense from the hero instance
	var hero_defense = hero.get_total_defense()
	
	# Calculate monster damage based on area level and hero defense
	# Base monster damage increases with area level
	var base_monster_damage = 10.0 * area_difficulty_multiplier
	
	# Calculate damage reduction percentage based on armor
	# Formula: Damage Reduction = Armor / (Armor + 100)
	# This gives diminishing returns - more armor is always better, but each point is less effective
	var damage_reduction_percent = hero_defense / (hero_defense + 100.0)
	
	# Apply damage reduction
	var damage_after_defense = base_monster_damage * (1.0 - damage_reduction_percent)
	
	# Ensure minimum damage of 1
	damage_after_defense = max(1.0, damage_after_defense)
	
	return damage_after_defense

func take_damage():
	# Hero takes damage from monsters while clearing
	var damage = calculate_monster_damage()
	hero.take_damage(damage)
	
	# Check if hero died
	if not hero.is_healthy():
		hero_died()

func hero_died():
	print("Hero died! Stopping clearing.")
	stop_clearing()
	hero.revive()  # Resurrect with full health
	print("Hero resurrected with full health!")
