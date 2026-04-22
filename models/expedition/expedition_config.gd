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

var drop_table: DropTable = null


func _init(
	p_id: String = "",
	p_name: String = "",
	p_description: String = "",
	p_duration: float = 30.0,
	p_difficulty: int = 1,
	p_reward_tier: int = 1,
	p_rewards: Dictionary = {},
	p_drop_table: DropTable = null
) -> void:
	expedition_id = p_id
	expedition_name = p_name
	description = p_description
	duration_seconds = p_duration
	difficulty = p_difficulty
	reward_tier = p_reward_tier
	base_currency_rewards = p_rewards
	drop_table = p_drop_table


static func _training_grounds_drop_table() -> DropTable:
	var dt := DropTable.new()
	dt.drop_rolls = 1
	dt.entries = [
		DropTable.create_entry("currency", "tack", -1, 0, 2, 4, true),
		DropTable.create_entry("item", "random_from_tier", Tag_List.MaterialTier.IRON, 40, 1, 1, false),
		DropTable.create_entry("currency", "tuning", -1, 30, 1, 1, false),
		DropTable.create_entry("currency", "forge", -1, 15, 1, 1, false),
		DropTable.create_entry("currency", "tack", -1, 15, 2, 2, false),
	]
	return dt


static func training_grounds() -> ExpeditionConfig:
	return ExpeditionConfig.new(
		"training_grounds",
		"Training Grounds",
		"A safe area to practice. Short expedition with basic rewards.",
		BalanceConfig.EXPEDITION_1_BASE_TIME,
		1,
		1,
		{"tack": 3},
		_training_grounds_drop_table()
	)


static func _dark_forest_drop_table() -> DropTable:
	var dt := DropTable.new()
	dt.drop_rolls = 2
	dt.entries = [
		DropTable.create_entry("currency", "tack", -1, 0, 5, 8, true),
		DropTable.create_entry("currency", "tuning", -1, 0, 1, 2, true),
		DropTable.create_entry("item", "random_from_tier", Tag_List.MaterialTier.STEEL, 30, 1, 1, false),
		DropTable.create_entry("item", "random_from_tier", Tag_List.MaterialTier.IRON, 15, 1, 1, false),
		DropTable.create_entry("currency", "forge", -1, 20, 1, 2, false),
		DropTable.create_entry("currency", "grand", -1, 15, 1, 1, false),
		DropTable.create_entry("currency", "tuning", -1, 10, 2, 3, false),
		DropTable.create_entry("currency", "runic", -1, 5, 1, 1, false),
		DropTable.create_entry("currency", "claw", -1, 5, 1, 1, false),
	]
	return dt


static func dark_forest() -> ExpeditionConfig:
	return ExpeditionConfig.new(
		"dark_forest",
		"Dark Forest",
		"A dangerous woodland filled with lurking threats. Better rewards for the brave.",
		BalanceConfig.EXPEDITION_2_BASE_TIME,
		3,
		2,
		{"tack": 8, "tuning": 2},
		_dark_forest_drop_table()
	)


static func get_all_configs() -> Array[ExpeditionConfig]:
	return [training_grounds(), dark_forest()]


static func get_config_by_id(id: String) -> ExpeditionConfig:
	for config in get_all_configs():
		if config.expedition_id == id:
			return config
	return null
