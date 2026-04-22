class_name ExpeditionConfig extends Resource

var expedition_id: String
var expedition_name: String
var description: String
var duration_seconds: float
var difficulty: int
var reward_tier: int

## Currency rewards: keys are currency keys (e.g. "tack"), values are base amounts.
## Actual reward amounts are scaled by difficulty.
var base_currency_rewards: Dictionary = {}


func _init(
	p_id: String = "",
	p_name: String = "",
	p_description: String = "",
	p_duration: float = 30.0,
	p_difficulty: int = 1,
	p_reward_tier: int = 1,
	p_rewards: Dictionary = {}
) -> void:
	expedition_id = p_id
	expedition_name = p_name
	description = p_description
	duration_seconds = p_duration
	difficulty = p_difficulty
	reward_tier = p_reward_tier
	base_currency_rewards = p_rewards


static func training_grounds() -> ExpeditionConfig:
	return ExpeditionConfig.new(
		"training_grounds",
		"Training Grounds",
		"A safe area to practice. Short expedition with basic rewards.",
		BalanceConfig.EXPEDITION_1_BASE_TIME,
		1,
		1,
		{"tack": 3}
	)


static func dark_forest() -> ExpeditionConfig:
	return ExpeditionConfig.new(
		"dark_forest",
		"Dark Forest",
		"A dangerous woodland filled with lurking threats. Better rewards for the brave.",
		BalanceConfig.EXPEDITION_2_BASE_TIME,
		3,
		2,
		{"tack": 8, "tuning": 2}
	)


static func get_all_configs() -> Array[ExpeditionConfig]:
	return [training_grounds(), dark_forest()]


static func get_config_by_id(id: String) -> ExpeditionConfig:
	for config in get_all_configs():
		if config.expedition_id == id:
			return config
	return null
