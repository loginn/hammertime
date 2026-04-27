class_name ExpeditionCard extends PanelContainer

signal expedition_send_requested(config: ExpeditionConfig)
signal expedition_collect_requested(config: ExpeditionConfig)
signal expedition_recall_requested(config: ExpeditionConfig)

enum CardState { IDLE, IN_PROGRESS, COMPLETED, BUSY }

const POLL_INTERVAL: float = 0.1

var _config: ExpeditionConfig = null
var _resolver: ExpeditionResolver = null
var _poll_accumulator: float = 0.0

@onready var _header: Label = %Header
@onready var _name: Label = %CardName
@onready var _desc: Label = %CardDesc
@onready var _material: Label = %CardMaterial
@onready var _time: Label = %CardTime
@onready var _rewards: VBoxContainer = %CardRewards
@onready var _progress: ProgressBar = %CardProgress
@onready var _countdown: Label = %CardCountdown
@onready var _status: Label = %CardStatus
@onready var _send_btn: Button = %CardSend
@onready var _busy_btn: Button = %CardBusy
@onready var _collect_btn: Button = %CardCollect
@onready var _recall_btn: Button = %CardRecall


func setup(config: ExpeditionConfig, resolver: ExpeditionResolver, card_index: int = 0) -> void:
	_config = config
	_resolver = resolver

	var roman := ["I", "II", "III", "IV", "V", "VI"]
	var stars := ""
	for i in range(1, 4):
		stars += "★" if i <= config.difficulty else "☆"
	_header.text = "EXPEDITION %s  %s" % [roman[card_index] if card_index < roman.size() else str(card_index + 1), stars]

	_name.text = config.expedition_name
	_desc.text = config.description

	var material_name := "Iron" if config.reward_tier == 1 else "Steel"
	_material.text = material_name

	_refresh_time()
	_populate_rewards()

	_send_btn.pressed.connect(func() -> void: expedition_send_requested.emit(_config))
	_collect_btn.pressed.connect(func() -> void: expedition_collect_requested.emit(_config))
	_recall_btn.pressed.connect(func() -> void: expedition_recall_requested.emit(_config))


func update_state(state: CardState) -> void:
	match state:
		CardState.COMPLETED:
			_send_btn.visible = false
			_busy_btn.visible = false
			_collect_btn.visible = true
			_recall_btn.visible = false
			_progress.visible = true
			_progress.value = 1.0
			_countdown.visible = false
			_status.text = "COMPLETE"
			_status.visible = true
		CardState.IN_PROGRESS:
			_send_btn.visible = false
			_busy_btn.visible = false
			_collect_btn.visible = false
			_recall_btn.visible = true
			_progress.visible = true
			_countdown.visible = true
			_status.text = "IN PROGRESS"
			_status.visible = true
		CardState.BUSY:
			_send_btn.visible = false
			_busy_btn.visible = true
			_collect_btn.visible = false
			_recall_btn.visible = false
			_progress.visible = false
			_countdown.visible = false
			_status.visible = false
		CardState.IDLE:
			_send_btn.visible = true
			_busy_btn.visible = false
			_collect_btn.visible = false
			_recall_btn.visible = false
			_progress.visible = false
			_countdown.visible = false
			_status.visible = false


func show_status(text: String) -> void:
	_status.text = text
	_status.visible = true


func hide_status() -> void:
	_status.visible = false


func refresh_time() -> void:
	_refresh_time()


func _process(delta: float) -> void:
	if _resolver == null or _config == null:
		return
	if not _resolver.is_active:
		return
	if _resolver.active_config == null or _resolver.active_config.expedition_id != _config.expedition_id:
		return

	_progress.value = _resolver.get_progress()

	_poll_accumulator += delta
	if _poll_accumulator < POLL_INTERVAL:
		return
	_poll_accumulator = 0.0

	var remaining := _resolver.get_remaining_seconds()
	_countdown.text = "%ds" % ceili(remaining)


func _refresh_time() -> void:
	if _config == null or _resolver == null:
		return
	var effective_duration: float
	if _resolver.is_active and _resolver.active_config != null and _resolver.active_config.expedition_id == _config.expedition_id:
		effective_duration = _resolver.get_effective_duration()
	else:
		var hero_power := GameState.hero.get_hero_power()
		effective_duration = _config.duration_seconds / (1.0 + hero_power * BalanceConfig.EXPEDITION_HERO_POWER_SCALING)
	_time.text = _format_duration(effective_duration)


func _populate_rewards() -> void:
	for child in _rewards.get_children():
		child.queue_free()
	if _config.drop_table == null:
		return
	for entry: Dictionary in _config.drop_table.entries:
		if not entry["guaranteed"]:
			continue
		var reward_label := Label.new()
		if entry["type"] == "currency":
			var display_name: String = GameState.CURRENCY_DISPLAY_NAMES.get(entry["key"], entry["key"])
			reward_label.text = "· %d-%d %s" % [entry["qty_min"], entry["qty_max"], display_name]
		else:
			reward_label.text = "· Item drop (T%d)" % entry["material_tier"]
		reward_label.add_theme_color_override("font_color", Color(0.93, 0.88, 0.78))
		reward_label.add_theme_font_size_override("font_size", 12)
		_rewards.add_child(reward_label)


func _format_duration(seconds: float) -> String:
	var s := int(seconds)
	if s >= 60:
		return "%dm %ds" % [s / 60, s % 60]
	return "%ds" % s
