extends Control

@onready var _header_label: Label = %HeaderLabel
@onready var _tack_label: Label = %TackLabel
@onready var _unlock_table: VBoxContainer = %UnlockTable
@onready var _action_panel: VBoxContainer = %ActionPanel
@onready var _next_cost_label: Label = %NextCostLabel
@onready var _next_reward_label: Label = %NextRewardLabel
@onready var _next_unlock_label: Label = %NextUnlockLabel
@onready var _next_resets_label: Label = %NextResetsLabel
@onready var _prestige_button: Button = %PrestigeButton
@onready var _confirm_dialog: ConfirmationDialog = %ConfirmDialog
@onready var _max_label: Label = %MaxLabel


func _ready() -> void:
	_build_unlock_table()
	_refresh_display()
	_prestige_button.pressed.connect(_on_prestige_button_pressed)
	_confirm_dialog.confirmed.connect(_on_confirm_accepted)
	GameEvents.prestige_completed.connect(_on_prestige_completed)
	GameEvents.currency_changed.connect(_on_currency_changed)


func _build_unlock_table() -> void:
	for child in _unlock_table.get_children():
		child.queue_free()

	var header_row := HBoxContainer.new()
	_add_table_cell(header_row, "Level", 60, Color(0.7, 0.65, 0.55))
	_add_table_cell(header_row, "Cost", 100, Color(0.7, 0.65, 0.55))
	_add_table_cell(header_row, "Unlocks", 200, Color(0.7, 0.65, 0.55))
	_add_table_cell(header_row, "Status", 80, Color(0.7, 0.65, 0.55))
	_unlock_table.add_child(header_row)

	for entry: Dictionary in BalanceConfig.PRESTIGE_LEVELS:
		var row := HBoxContainer.new()
		_add_table_cell(row, str(entry.level), 60, Color(0.93, 0.88, 0.78))
		_add_table_cell(row, "%d Tack" % entry.cost, 100, Color(0.93, 0.88, 0.78))
		_add_table_cell(row, entry.description, 200, Color(0.93, 0.88, 0.78))

		var status_text := ""
		if PrestigeManager.prestige_count >= entry.level:
			status_text = "✓"
		else:
			status_text = "🔒"
		_add_table_cell(row, status_text, 80, Color(0.93, 0.88, 0.78))

		_unlock_table.add_child(row)


func _add_table_cell(row: HBoxContainer, text: String, min_width: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = min_width
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)


func _refresh_display() -> void:
	_header_label.text = "Prestige Level: %d" % PrestigeManager.prestige_count

	var tack_count: int = GameState.currency_counts.get("tack", 0)
	_tack_label.text = "Tack Hammers: %d" % tack_count

	_rebuild_status_indicators()

	if PrestigeManager.is_max_prestige():
		_action_panel.visible = false
		_max_label.visible = true
		_max_label.text = "MAX PRESTIGE"
	else:
		_action_panel.visible = true
		_max_label.visible = false
		var data: Dictionary = PrestigeManager.get_next_level_data()
		_next_cost_label.text = "Cost: %d Tack Hammers" % data.cost
		_next_reward_label.text = "Reward: %d of each currency" % data.reward_amount
		_next_unlock_label.text = "Unlocks: %s" % data.description
		_next_resets_label.text = "Resets: All currencies, inventory, hero equipment, area level"
		_prestige_button.disabled = not PrestigeManager.can_prestige()


func _rebuild_status_indicators() -> void:
	var rows := _unlock_table.get_children()
	for i in range(1, rows.size()):
		var row: HBoxContainer = rows[i]
		var status_label: Label = row.get_child(3)
		var level_index: int = i - 1
		var entry: Dictionary = BalanceConfig.PRESTIGE_LEVELS[level_index]
		if PrestigeManager.prestige_count >= entry.level:
			status_label.text = "✓"
		else:
			status_label.text = "🔒"


func _on_prestige_button_pressed() -> void:
	var data: Dictionary = PrestigeManager.get_next_level_data()
	var next_level: int = data.level
	_confirm_dialog.dialog_text = "Prestige to Level %d?\n\nCost: %d Tack Hammers\nReward: %d of each currency\nUnlocks: %s\n\nThis will RESET:\n- All currencies\n- All inventory items\n- Hero equipment\n- Area level" % [next_level, data.cost, data.reward_amount, data.description]
	_confirm_dialog.popup_centered()


func _on_confirm_accepted() -> void:
	PrestigeManager.execute_prestige()


func _on_prestige_completed() -> void:
	_refresh_display()


func _on_currency_changed(_key: String, _amount: int) -> void:
	var tack_count: int = GameState.currency_counts.get("tack", 0)
	_tack_label.text = "Tack Hammers: %d" % tack_count
	if not PrestigeManager.is_max_prestige():
		_prestige_button.disabled = not PrestigeManager.can_prestige()
