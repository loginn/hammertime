extends Control

const ExpeditionCardScene = preload("res://scenes/expedition/expedition_card.tscn")
var _cards: Array[ExpeditionCard] = []

@onready var _card_grid: GridContainer = %CardGrid


func _ready() -> void:
	_rebuild_cards()
	GameEvents.expedition_started.connect(_on_expedition_started)
	GameEvents.expedition_completed.connect(_on_expedition_completed)
	GameEvents.expedition_collected.connect(_on_expedition_collected)
	GameEvents.equipment_changed.connect(_on_equipment_changed)
	GameEvents.prestige_completed.connect(_rebuild_cards)


func _rebuild_cards() -> void:
	for child in _card_grid.get_children():
		child.queue_free()
	_cards.clear()

	var resolver := GameState.expedition_resolver
	var configs := ExpeditionConfig.get_configs_for_prestige(PrestigeManager.prestige_count)
	for i in range(configs.size()):
		var config: ExpeditionConfig = configs[i]
		var card: ExpeditionCard = ExpeditionCardScene.instantiate()
		_card_grid.add_child(card)
		card.setup(config, resolver, i)
		card.expedition_send_requested.connect(_on_send_requested)
		card.expedition_collect_requested.connect(_on_collect_requested)
		card.expedition_recall_requested.connect(_on_recall_requested)
		_cards.append(card)

	_update_all_card_states()


func _update_all_card_states() -> void:
	var resolver := GameState.expedition_resolver
	var active_id := ""
	if resolver.is_active and resolver.active_config != null:
		active_id = resolver.active_config.expedition_id
	var completed := resolver.is_completed() if resolver.is_active else false

	for card in _cards:
		if not is_instance_valid(card) or card._config == null:
			continue
		if card._config.expedition_id == active_id and active_id != "":
			if completed:
				card.update_state(ExpeditionCard.CardState.COMPLETED)
			else:
				card.update_state(ExpeditionCard.CardState.IN_PROGRESS)
		elif active_id != "":
			card.update_state(ExpeditionCard.CardState.BUSY)
		else:
			card.update_state(ExpeditionCard.CardState.IDLE)



func _on_send_requested(config: ExpeditionConfig) -> void:
	var resolver := GameState.expedition_resolver
	var success := resolver.start_expedition(config)
	if not success:
		var card := _find_card_for_config(config)
		if card != null:
			card.show_status("Cannot send hero")
	_update_all_card_states()


func _on_collect_requested(config: ExpeditionConfig) -> void:
	var resolver := GameState.expedition_resolver
	var rewards := resolver.complete_expedition()
	if rewards.is_empty():
		return

	var parts: Array[String] = []
	var currencies: Dictionary = rewards.get("currencies", {})
	for currency_key: String in currencies:
		var display_name: String = GameState.CURRENCY_DISPLAY_NAMES.get(currency_key, currency_key)
		parts.append("%d %s" % [currencies[currency_key], display_name])
	if not parts.is_empty():
		Toast.show_message("Earned: %s" % ", ".join(parts))

	_update_all_card_states()


func _on_recall_requested(_config: ExpeditionConfig) -> void:
	GameState.expedition_resolver.cancel_expedition()
	_update_all_card_states()


func _find_card_for_config(config: ExpeditionConfig) -> ExpeditionCard:
	for card in _cards:
		if is_instance_valid(card) and card._config != null and card._config.expedition_id == config.expedition_id:
			return card
	return null


func _on_expedition_started(_expedition_id: String) -> void:
	_update_all_card_states()


func _on_expedition_completed(_expedition_id: String, _rewards: Dictionary) -> void:
	_update_all_card_states()


func _on_expedition_collected(_expedition_id: String) -> void:
	_update_all_card_states()


func _on_equipment_changed(_slot: int, _item: HeroItem) -> void:
	for card in _cards:
		if is_instance_valid(card):
			card.refresh_time()
