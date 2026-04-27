extends Control

const HAMMER_GLYPHS: Dictionary = {
	"tack": "⬦", "tuning": "◈", "forge": "◆", "grand": "✦",
	"runic": "⚒", "scour": "◎", "claw": "✕",
}

@onready var _sacrifice_list: VBoxContainer = %SacrificeList
@onready var _reward_list: VBoxContainer = %RewardList
@onready var _total_label: Label = %TotalLabel
@onready var _have_count: Label = %HaveCount
@onready var _need_count: Label = %NeedCount
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _gauge_footer: Label = %GaugeFooter
@onready var _gauge_header: Label = %GaugeHeader
@onready var _reforge_button: Button = %ReforgeButton
@onready var _prestige_count_label: Label = %PrestigeCount
@onready var _max_label: Label = %MaxLabel
@onready var _confirm_dialog: ConfirmationDialog = %ConfirmDialog


func _ready() -> void:
	_reforge_button.pressed.connect(_on_reforge_pressed)
	_confirm_dialog.confirmed.connect(_on_confirm_accepted)
	GameEvents.prestige_completed.connect(_on_prestige_completed)
	GameEvents.currency_changed.connect(_on_currency_changed)
	GameEvents.inventory_changed.connect(func(_s): _refresh_sacrifice_panel())
	_refresh_all()


func _refresh_all() -> void:
	_refresh_sacrifice_panel()
	_refresh_gauge()
	_refresh_reward_panel()
	_refresh_prestige_count()


func _refresh_sacrifice_panel() -> void:
	for child in _sacrifice_list.get_children():
		_sacrifice_list.remove_child(child)
		child.queue_free()

	var item_count := 0
	var magic_count := 0
	var rare_count := 0
	var normal_count := 0
	for slot: int in Tag.ALL_SLOTS:
		var items: Array = GameState.crafting_inventory.get(slot, [])
		for item: Item in items:
			item_count += 1
			match item.rarity:
				Tag.Rarity.MAGIC: magic_count += 1
				Tag.Rarity.RARE: rare_count += 1
				_: normal_count += 1

	var sub_parts: Array[String] = []
	if magic_count > 0: sub_parts.append("%d magic" % magic_count)
	if rare_count > 0: sub_parts.append("%d rare" % rare_count)
	if normal_count > 0: sub_parts.append("%d normal" % normal_count)
	var item_sub := " · ".join(sub_parts) if sub_parts.size() > 0 else "none"

	_add_sacrifice_row("All crafted items", str(item_count), item_sub)

	var equipped_count := 0
	for slot: int in Tag.ALL_SLOTS:
		if GameState.hero.get_equipped(slot) != null:
			equipped_count += 1
	_add_sacrifice_row("Equipped gear", str(equipped_count), "%d / 5 slots" % equipped_count)

	var expedition_status := "will reset"
	if GameState.expedition_resolver and GameState.expedition_resolver.is_active:
		expedition_status = "active — will reset"
	_add_sacrifice_row("Expedition progress", "—", expedition_status)

	for key: String in GameState.CURRENCY_KEYS:
		if key in BalanceConfig.HIDDEN_CURRENCIES:
			continue
		var count: int = GameState.currency_counts.get(key, 0)
		if count > 0:
			_add_sacrifice_row(GameState.CURRENCY_DISPLAY_NAMES[key], str(count), "stockpile")


func _add_sacrifice_row(label_text: String, value_text: String, sub_text: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 28

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.93, 0.88, 0.78))
	left.add_child(name_label)

	var sub_label := Label.new()
	sub_label.text = sub_text
	sub_label.add_theme_font_size_override("font_size", 9)
	sub_label.add_theme_color_override("font_color", Color(0.4, 0.38, 0.3))
	left.add_child(sub_label)

	row.add_child(left)

	var val_label := Label.new()
	val_label.text = value_text
	val_label.add_theme_font_size_override("font_size", 18)
	val_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_label)

	_sacrifice_list.add_child(row)


func _refresh_gauge() -> void:
	if PrestigeManager.is_max_prestige():
		_have_count.text = "—"
		_need_count.text = "—"
		_progress_bar.value = 100
		_gauge_footer.text = "MAX PRESTIGE REACHED"
		_gauge_header.text = "COMPLETE"
		_reforge_button.visible = false
		_max_label.visible = true
		return

	_reforge_button.visible = true
	_max_label.visible = false

	var data: Dictionary = PrestigeManager.get_next_level_data()
	var currency_key: String = data.cost_currency
	var display_name: String = GameState.CURRENCY_DISPLAY_NAMES.get(currency_key, currency_key.to_upper())
	var have: int = GameState.currency_counts.get(currency_key, 0)
	var need: int = data.cost
	var pct: float = min(100.0, float(have) / float(need) * 100.0)
	var ready: bool = have >= need
	var glyph: String = HAMMER_GLYPHS.get(currency_key, "·")

	_gauge_header.text = "%s %s" % [glyph, display_name.to_upper()]
	_have_count.text = str(have)
	_need_count.text = str(need)
	_progress_bar.value = pct

	if ready:
		_have_count.add_theme_color_override("font_color", Color(0.9, 0.55, 0.25))
		_gauge_footer.text = "◆ READY TO REFORGE"
		_gauge_footer.add_theme_color_override("font_color", Color(0.9, 0.55, 0.25))
		_reforge_button.text = "REFORGE · PRESTIGE %d" % data.level
		_reforge_button.disabled = false
	else:
		_have_count.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
		_gauge_footer.text = "%d MORE NEEDED" % (need - have)
		_gauge_footer.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
		_reforge_button.text = "REFORGE ⚒ (LOCKED)"
		_reforge_button.disabled = true


func _refresh_reward_panel() -> void:
	for child in _reward_list.get_children():
		_reward_list.remove_child(child)
		child.queue_free()

	_total_label.text = ""

	if PrestigeManager.is_max_prestige():
		var done_label := Label.new()
		done_label.text = "All prestiges complete"
		done_label.add_theme_font_size_override("font_size", 14)
		done_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
		_reward_list.add_child(done_label)
		return

	var data: Dictionary = PrestigeManager.get_next_level_data()

	var header_label := Label.new()
	header_label.text = "UNLOCK"
	header_label.add_theme_font_size_override("font_size", 10)
	header_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward_list.add_child(header_label)

	var unlock_label := Label.new()
	unlock_label.text = data.description
	unlock_label.add_theme_font_size_override("font_size", 14)
	unlock_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_list.add_child(unlock_label)

	var reset_label := Label.new()
	reset_label.text = "All currencies, gear, and expedition progress will reset."
	reset_label.add_theme_font_size_override("font_size", 10)
	reset_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3))
	reset_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_list.add_child(reset_label)



func _refresh_prestige_count() -> void:
	var count: int = PrestigeManager.prestige_count
	var suffix := "FIRST REFORGE" if count == 0 else ""
	if count > 0:
		suffix = "REFORGES"
	_prestige_count_label.text = "PRESTIGE COUNT · %d · %s" % [count, suffix]



func _on_reforge_pressed() -> void:
	var data: Dictionary = PrestigeManager.get_next_level_data()
	var currency_name: String = GameState.CURRENCY_DISPLAY_NAMES.get(data.cost_currency, data.cost_currency)
	_confirm_dialog.dialog_text = "Prestige to Level %d?\n\nCost: %d %s\nUnlocks: %s\n\nThis will RESET:\n- All currencies\n- All inventory items\n- Hero equipment" % [data.level, data.cost, currency_name, data.description]
	_confirm_dialog.popup_centered()


func _on_confirm_accepted() -> void:
	PrestigeManager.execute_prestige()


func _on_prestige_completed() -> void:
	_refresh_all()


func _on_currency_changed(_key: String, _amount: int) -> void:
	_refresh_gauge()
	_refresh_reward_panel()
