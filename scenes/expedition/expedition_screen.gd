extends Control

var _configs: Array[ExpeditionConfig] = []
var _poll_accumulator: float = 0.0
var _reward_display_timer: float = 0.0
var _showing_rewards: bool = false

const POLL_INTERVAL: float = 0.1
const REWARD_DISPLAY_DURATION: float = 3.0

@onready var _card_1_header: Label = %Card1Header
@onready var _card_1_name: Label = %Card1Name
@onready var _card_1_desc: Label = %Card1Desc
@onready var _card_1_material: Label = %Card1Material
@onready var _card_1_time: Label = %Card1Time
@onready var _card_1_rewards: VBoxContainer = %Card1Rewards
@onready var _card_1_progress: ProgressBar = %Card1Progress
@onready var _card_1_countdown: Label = %Card1Countdown
@onready var _card_1_status: Label = %Card1Status
@onready var _card_1_send: Button = %Card1Send
@onready var _card_1_busy: Button = %Card1Busy
@onready var _card_1_collect: Button = %Card1Collect
@onready var _card_1_recall: Button = %Card1Recall

@onready var _card_2_header: Label = %Card2Header
@onready var _card_2_name: Label = %Card2Name
@onready var _card_2_desc: Label = %Card2Desc
@onready var _card_2_material: Label = %Card2Material
@onready var _card_2_time: Label = %Card2Time
@onready var _card_2_rewards: VBoxContainer = %Card2Rewards
@onready var _card_2_progress: ProgressBar = %Card2Progress
@onready var _card_2_countdown: Label = %Card2Countdown
@onready var _card_2_status: Label = %Card2Status
@onready var _card_2_send: Button = %Card2Send
@onready var _card_2_busy: Button = %Card2Busy
@onready var _card_2_collect: Button = %Card2Collect
@onready var _card_2_recall: Button = %Card2Recall


func _ready() -> void:
	_configs = ExpeditionConfig.get_all_configs()

	_populate_card(0)
	_populate_card(1)
	_update_card_states()

	_card_1_send.pressed.connect(_on_send_pressed.bind(0))
	_card_2_send.pressed.connect(_on_send_pressed.bind(1))
	_card_1_recall.pressed.connect(_on_recall_pressed)
	_card_2_recall.pressed.connect(_on_recall_pressed)
	_card_1_collect.pressed.connect(_on_collect_pressed)
	_card_2_collect.pressed.connect(_on_collect_pressed)

	GameEvents.expedition_started.connect(_on_expedition_started)
	GameEvents.expedition_completed.connect(_on_expedition_completed)
	GameEvents.expedition_collected.connect(_on_expedition_collected)
	GameEvents.equipment_changed.connect(_on_equipment_changed)


func _populate_card(index: int) -> void:
	var config := _configs[index]
	var header_label := _card_1_header if index == 0 else _card_2_header
	var name_label := _card_1_name if index == 0 else _card_2_name
	var desc_label := _card_1_desc if index == 0 else _card_2_desc
	var material_label := _card_1_material if index == 0 else _card_2_material
	var time_label := _card_1_time if index == 0 else _card_2_time
	var rewards_box := _card_1_rewards if index == 0 else _card_2_rewards

	var stars := ""
	for i in range(1, 4):
		stars += "★" if i <= config.difficulty else "☆"

	header_label.text = "EXPEDITION %s  %s" % ["I" if index == 0 else "II", stars]
	name_label.text = config.expedition_name
	desc_label.text = config.description
	var material_name := "Iron" if config.reward_tier == 1 else "Steel"
	material_label.text = material_name
	var resolver := GameState.expedition_resolver
	var effective_duration: float
	if resolver.is_active and resolver.active_config != null and resolver.active_config.expedition_id == config.expedition_id:
		effective_duration = resolver.get_effective_duration()
	else:
		var hero_power := GameState.hero.get_hero_power()
		effective_duration = config.duration_seconds / (1.0 + hero_power * BalanceConfig.EXPEDITION_HERO_POWER_SCALING)
	time_label.text = _format_duration(effective_duration)

	for child in rewards_box.get_children():
		child.queue_free()

	if config.drop_table != null:
		for entry: Dictionary in config.drop_table.entries:
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
			rewards_box.add_child(reward_label)


func _format_duration(seconds: float) -> String:
	var s := int(seconds)
	if s >= 60:
		return "%dm %ds" % [s / 60, s % 60]
	return "%ds" % s


func _on_send_pressed(config_index: int) -> void:
	var resolver := GameState.expedition_resolver
	var success := resolver.start_expedition(_configs[config_index])
	if not success:
		var status_label := _card_1_status if config_index == 0 else _card_2_status
		status_label.text = "Cannot send hero"
		status_label.visible = true
	_update_card_states()


func _on_recall_pressed() -> void:
	GameState.expedition_resolver.cancel_expedition()
	_update_card_states()


func _on_collect_pressed() -> void:
	var resolver := GameState.expedition_resolver
	var active_index := _get_active_card_index()
	var rewards := resolver.complete_expedition()
	if rewards.is_empty():
		return

	var status_label := _card_1_status if active_index == 0 else _card_2_status
	var parts: Array[String] = []
	var currencies: Dictionary = rewards.get("currencies", {})
	for currency_key: String in currencies:
		var display_name: String = GameState.CURRENCY_DISPLAY_NAMES.get(currency_key, currency_key)
		parts.append("%d %s" % [currencies[currency_key], display_name])
	var items: Array = rewards.get("items", [])
	if items.size() > 0:
		parts.append("%d item%s" % [items.size(), "s" if items.size() > 1 else ""])
	status_label.text = "Earned: %s" % ", ".join(parts)
	status_label.visible = true
	_showing_rewards = true
	_reward_display_timer = 0.0

	_update_card_states()


func _process(delta: float) -> void:
	var resolver := GameState.expedition_resolver
	if resolver.is_active:
		var active_index := _get_active_card_index()
		if active_index >= 0:
			var progress_bar := _card_1_progress if active_index == 0 else _card_2_progress
			progress_bar.value = resolver.get_progress()

	_poll_accumulator += delta
	if _poll_accumulator < POLL_INTERVAL:
		return
	_poll_accumulator = 0.0

	if resolver.is_active:
		var active_index := _get_active_card_index()
		if active_index >= 0:
			var countdown_label := _card_1_countdown if active_index == 0 else _card_2_countdown
			var remaining := resolver.get_remaining_seconds()
			countdown_label.text = "%ds" % ceili(remaining)

			if resolver.is_completed():
				_update_card_states()

	if _showing_rewards:
		_reward_display_timer += POLL_INTERVAL
		if _reward_display_timer >= REWARD_DISPLAY_DURATION:
			_showing_rewards = false
			_card_1_status.visible = false
			_card_2_status.visible = false
			_update_card_states()


func _get_active_card_index() -> int:
	var resolver := GameState.expedition_resolver
	if not resolver.is_active or resolver.active_config == null:
		return -1
	for i in range(_configs.size()):
		if _configs[i].expedition_id == resolver.active_config.expedition_id:
			return i
	return -1


func _update_card_states() -> void:
	var resolver := GameState.expedition_resolver
	var active_index := _get_active_card_index()
	var completed := resolver.is_completed() if resolver.is_active else false

	_set_card_state(0, active_index, completed)
	_set_card_state(1, active_index, completed)


func _set_card_state(card_index: int, active_index: int, completed: bool) -> void:
	var send_btn := _card_1_send if card_index == 0 else _card_2_send
	var busy_btn := _card_1_busy if card_index == 0 else _card_2_busy
	var collect_btn := _card_1_collect if card_index == 0 else _card_2_collect
	var recall_btn := _card_1_recall if card_index == 0 else _card_2_recall
	var progress_bar := _card_1_progress if card_index == 0 else _card_2_progress
	var countdown_label := _card_1_countdown if card_index == 0 else _card_2_countdown
	var status_label := _card_1_status if card_index == 0 else _card_2_status

	var is_this_active := (card_index == active_index)
	var any_active := (active_index >= 0)

	if is_this_active and completed:
		# Completed state
		send_btn.visible = false
		busy_btn.visible = false
		collect_btn.visible = true
		recall_btn.visible = false
		progress_bar.visible = true
		progress_bar.value = 1.0
		countdown_label.visible = false
		if not _showing_rewards:
			status_label.text = "COMPLETE"
			status_label.visible = true
	elif is_this_active and not completed:
		# In-progress state
		send_btn.visible = false
		busy_btn.visible = false
		collect_btn.visible = false
		recall_btn.visible = true
		progress_bar.visible = true
		countdown_label.visible = true
		if not _showing_rewards:
			status_label.text = "IN PROGRESS"
			status_label.visible = true
	elif any_active and not is_this_active:
		# Hero busy on other card
		send_btn.visible = false
		busy_btn.visible = true
		collect_btn.visible = false
		recall_btn.visible = false
		progress_bar.visible = false
		countdown_label.visible = false
		if not _showing_rewards:
			status_label.visible = false
	else:
		# Idle state
		send_btn.visible = true
		busy_btn.visible = false
		collect_btn.visible = false
		recall_btn.visible = false
		progress_bar.visible = false
		countdown_label.visible = false
		if not _showing_rewards:
			status_label.visible = false


func _on_equipment_changed(_slot: int, _item: Item) -> void:
	_refresh_time_labels()


func _refresh_time_labels() -> void:
	var hero_power := GameState.hero.get_hero_power()
	for i in range(_configs.size()):
		var config := _configs[i]
		var time_label := _card_1_time if i == 0 else _card_2_time
		var effective := config.duration_seconds / (1.0 + hero_power * BalanceConfig.EXPEDITION_HERO_POWER_SCALING)
		time_label.text = _format_duration(effective)


func _on_expedition_started(_expedition_id: String) -> void:
	_update_card_states()


func _on_expedition_completed(_expedition_id: String, _rewards: Dictionary) -> void:
	_update_card_states()


func _on_expedition_collected(_expedition_id: String) -> void:
	_update_card_states()
