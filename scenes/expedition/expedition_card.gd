class_name ExpeditionCard extends PanelContainer

signal expedition_send_requested(config: ExpeditionConfig)
signal expedition_collect_requested(config: ExpeditionConfig)
signal expedition_recall_requested(config: ExpeditionConfig)

enum CardState { IDLE, IN_PROGRESS, COMPLETED, BUSY }

const POLL_INTERVAL: float = 0.1

var _config: ExpeditionConfig = null
var _resolver: ExpeditionResolver = null
var _poll_accumulator: float = 0.0
var _state: CardState = CardState.IDLE
var _hovering: bool = false

@onready var _name: Label = %CardName
@onready var _stars: Label = %CardStars
@onready var _duration: Label = %CardDuration
@onready var _rewards: VBoxContainer = %CardRewards
@onready var _action_btn: Button = %ActionButton
@onready var _fill_overlay: ColorRect = %FillOverlay
@onready var _btn_label: Label = %ButtonLabel


func setup(config: ExpeditionConfig, resolver: ExpeditionResolver, _card_index: int = 0) -> void:
	_config = config
	_resolver = resolver

	var star_str := ""
	for i in range(1, 4):
		star_str += "★" if i <= config.difficulty else "☆"
	_stars.text = star_str

	_name.text = config.expedition_name
	_refresh_time()
	_populate_rewards()

	_action_btn.pressed.connect(_on_button_pressed)
	_action_btn.mouse_entered.connect(func() -> void:
		_hovering = true
		_update_button_display()
	)
	_action_btn.mouse_exited.connect(func() -> void:
		_hovering = false
		_update_button_display()
	)


func update_state(state: CardState) -> void:
	_state = state
	_hovering = false
	_update_button_display()


func show_status(text: String) -> void:
	_duration.text = text
	_duration.add_theme_color_override("font_color", Color(1, 0.7, 0.36, 1))


func hide_status() -> void:
	_refresh_time()
	_duration.add_theme_color_override("font_color", Color(0.54, 0.46, 0.38, 1))


func refresh_time() -> void:
	_refresh_time()


func _process(delta: float) -> void:
	if _resolver == null or _config == null:
		return
	if not _resolver.is_active:
		return
	if _resolver.active_config == null or _resolver.active_config.expedition_id != _config.expedition_id:
		return

	var progress := _resolver.get_progress()
	_update_fill(progress)

	_poll_accumulator += delta
	if _poll_accumulator < POLL_INTERVAL:
		return
	_poll_accumulator = 0.0

	if not _hovering:
		var remaining := _resolver.get_remaining_seconds()
		_btn_label.text = "%ds" % ceili(remaining)

	if _resolver.is_completed() and _state != CardState.COMPLETED:
		update_state(CardState.COMPLETED)


func _on_button_pressed() -> void:
	match _state:
		CardState.IDLE:
			expedition_send_requested.emit(_config)
		CardState.IN_PROGRESS:
			expedition_recall_requested.emit(_config)
		CardState.COMPLETED:
			expedition_collect_requested.emit(_config)


func _update_button_display() -> void:
	_action_btn.text = ""
	match _state:
		CardState.IDLE:
			_action_btn.disabled = false
			_btn_label.visible = true
			_btn_label.text = "Send Hero"
			_btn_label.add_theme_color_override("font_color", Color(0.1, 0.03, 0.01, 1))
			_fill_overlay.visible = false
			_set_btn_bg(Color(0.91, 0.53, 0.29, 1))
		CardState.IN_PROGRESS:
			_action_btn.disabled = false
			_btn_label.visible = true
			_fill_overlay.visible = true
			if _hovering:
				_btn_label.text = "Recall"
				_btn_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.5, 1))
			else:
				_btn_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
			_set_btn_bg(Color(0.15, 0.1, 0.07, 1))
		CardState.COMPLETED:
			_action_btn.disabled = false
			_btn_label.visible = true
			_btn_label.text = "Collect"
			_btn_label.add_theme_color_override("font_color", Color(0.1, 0.03, 0.01, 1))
			_fill_overlay.visible = true
			_update_fill(1.0)
			_set_btn_bg(Color(0.15, 0.1, 0.07, 1))
		CardState.BUSY:
			_action_btn.disabled = true
			_btn_label.visible = true
			_btn_label.text = "Hero Busy"
			_btn_label.add_theme_color_override("font_color", Color(0.54, 0.46, 0.38, 1))
			_fill_overlay.visible = false
			_set_btn_bg(Color(0.24, 0.21, 0.19, 1))


func _update_fill(ratio: float) -> void:
	var btn_width := _action_btn.size.x
	_fill_overlay.offset_right = btn_width * clampf(ratio, 0.0, 1.0)


func _set_btn_bg(color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 8.0
	style.content_margin_top = 4.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 4.0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0, 0, 0, 1)
	_action_btn.add_theme_stylebox_override("normal", style)
	_action_btn.add_theme_stylebox_override("hover", style)
	_action_btn.add_theme_stylebox_override("pressed", style)


func _refresh_time() -> void:
	if _config == null or _resolver == null:
		return
	var effective_duration: float
	if _resolver.is_active and _resolver.active_config != null and _resolver.active_config.expedition_id == _config.expedition_id:
		effective_duration = _resolver.get_effective_duration()
	else:
		var hero_power := GameState.hero.get_hero_power()
		effective_duration = _config.duration_seconds / (1.0 + hero_power * BalanceConfig.EXPEDITION_HERO_POWER_SCALING)
	_duration.text = _format_duration(effective_duration)


func _populate_rewards() -> void:
	for child in _rewards.get_children():
		child.queue_free()
	if _config.drop_table == null:
		return
	for entry: Dictionary in _config.drop_table.entries:
		var reward_label := Label.new()
		var is_guaranteed: bool = entry["guaranteed"]
		if entry["type"] == "currency":
			var display_name: String = GameState.CURRENCY_DISPLAY_NAMES.get(entry["key"], entry["key"])
			if is_guaranteed:
				reward_label.text = "· %d-%d %s" % [entry["qty_min"], entry["qty_max"], display_name]
			else:
				reward_label.text = "· %d-%d %s (chance)" % [entry["qty_min"], entry["qty_max"], display_name]
		else:
			reward_label.text = "· Item drop (T%d)" % entry["material_tier"]
		var color := Color(0.93, 0.88, 0.78) if is_guaranteed else Color(0.65, 0.58, 0.48)
		reward_label.add_theme_color_override("font_color", color)
		reward_label.add_theme_font_size_override("font_size", 10)
		_rewards.add_child(reward_label)


func _format_duration(seconds: float) -> String:
	var s := int(seconds)
	if s >= 3600:
		return "%dh %dm" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%dm %ds" % [s / 60, s % 60]
	return "%ds" % s
