extends Node2D

signal prestige_triggered()

@onready var current_level_label: Label = $CurrentLevelLabel
@onready var next_info_label: Label = $NextInfoLabel
@onready var next_reward_label: Label = $NextRewardLabel
@onready var unlock_table: VBoxContainer = $UnlockTable
@onready var prestige_button: Button = $PrestigeButton

var prestige_confirm_pending: bool = false
var prestige_timer: Timer


func _ready() -> void:
	prestige_button.pressed.connect(_on_prestige_pressed)

	# Create prestige confirmation timer
	prestige_timer = Timer.new()
	prestige_timer.name = "PrestigeTimer"
	prestige_timer.one_shot = true
	prestige_timer.wait_time = 3.0
	prestige_timer.timeout.connect(_on_prestige_timer_timeout)
	add_child(prestige_timer)

	_update_display()
	GameEvents.currency_dropped.connect(_on_currency_changed)


func _update_display() -> void:
	current_level_label.text = "Current Prestige: P" + str(GameState.prestige_level)

	if GameState.prestige_level >= PrestigeManager.MAX_PRESTIGE_LEVEL:
		next_info_label.text = "Max Prestige Reached"
		next_reward_label.text = ""
	else:
		var next_level: int = GameState.prestige_level + 1
		var cost: Dictionary = PrestigeManager.get_next_prestige_cost()
		var cost_string: String = "Next: " + str(cost["forge"]) + " Forge Hammers"
		next_info_label.text = cost_string

		var tier_unlock: int = PrestigeManager.ITEM_TIERS_BY_PRESTIGE[next_level]
		var reward_text: String = "Unlocks: Item Tier " + str(tier_unlock)
		if next_level == 1:
			reward_text += " + Tag Hammers"
		next_reward_label.text = reward_text

	_build_unlock_table()
	_update_button_state()


func _build_unlock_table() -> void:
	# Clear existing rows
	for child in unlock_table.get_children():
		child.queue_free()

	for level in range(1, PrestigeManager.MAX_PRESTIGE_LEVEL + 1):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 35

		# Determine row state
		var state: String
		if level <= GameState.prestige_level:
			state = "completed"
		elif level == GameState.prestige_level + 1:
			state = "next"
		else:
			state = "future"

		# Status column (60px)
		var status_label := Label.new()
		status_label.custom_minimum_size.x = 60
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if state == "completed":
			status_label.text = "\u2713"
		elif state == "next":
			status_label.text = ">"
		else:
			status_label.text = "-"
		row.add_child(status_label)

		# Level column (80px)
		var level_label := Label.new()
		level_label.custom_minimum_size.x = 80
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.text = "P" + str(level)
		row.add_child(level_label)

		# Tier column (160px)
		var tier_label := Label.new()
		tier_label.custom_minimum_size.x = 160
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_label.text = "Tier " + str(PrestigeManager.ITEM_TIERS_BY_PRESTIGE[level])
		row.add_child(tier_label)

		# Reward column (200px)
		var reward_label := Label.new()
		reward_label.custom_minimum_size.x = 200
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if level == 1:
			reward_label.text = "Tag Hammers"
		else:
			reward_label.text = "-"
		row.add_child(reward_label)

		# Cost column (200px)
		var cost_label := Label.new()
		cost_label.custom_minimum_size.x = 200
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if state == "completed" or state == "next":
			cost_label.text = str(PrestigeManager.PRESTIGE_COSTS[level]["forge"]) + " Forge"
		else:
			cost_label.text = "???"
		row.add_child(cost_label)

		# Apply row coloring
		if state == "completed":
			row.modulate = Color(0.4, 0.7, 0.4, 1)
		elif state == "next":
			row.modulate = Color(1.0, 1.0, 1.0, 1)
		else:
			row.modulate = Color(0.5, 0.5, 0.5, 1)

		unlock_table.add_child(row)


func _update_button_state() -> void:
	if GameState.prestige_level >= PrestigeManager.MAX_PRESTIGE_LEVEL:
		prestige_button.disabled = true
		prestige_button.text = "Max Prestige"
	else:
		prestige_button.disabled = not PrestigeManager.can_prestige()
		if not prestige_confirm_pending:
			prestige_button.text = "Upgrade your forge"


func _on_prestige_pressed() -> void:
	if not PrestigeManager.can_prestige():
		return
	if not prestige_confirm_pending:
		prestige_confirm_pending = true
		prestige_button.text = "Reset progress?"
		prestige_timer.start()
	else:
		prestige_confirm_pending = false
		prestige_timer.stop()
		_execute_prestige()


func _execute_prestige() -> void:
	PrestigeManager.execute_prestige()
	SaveManager.save_game()
	prestige_triggered.emit()


func _on_prestige_timer_timeout() -> void:
	prestige_confirm_pending = false
	_update_button_state()


func _on_currency_changed(_drops: Dictionary) -> void:
	_update_button_state()


func reset_state() -> void:
	prestige_confirm_pending = false
	prestige_timer.stop()
	_update_button_state()
