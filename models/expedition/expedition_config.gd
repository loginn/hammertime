class_name ExpeditionConfig extends Resource

var expedition_id: String
var expedition_name: String
var description: String
var duration_seconds: float
var difficulty: int
var reward_tier: int

var drop_table: DropTable = null


func _init(
	p_id: String = "",
	p_name: String = "",
	p_description: String = "",
	p_duration: float = 30.0,
	p_difficulty: int = 1,
	p_reward_tier: int = 1,
	p_drop_table: DropTable = null
) -> void:
	expedition_id = p_id
	expedition_name = p_name
	description = p_description
	duration_seconds = p_duration
	difficulty = p_difficulty
	reward_tier = p_reward_tier
	drop_table = p_drop_table


static func _iron_quarry_drop_table() -> DropTable:
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


static func iron_quarry() -> ExpeditionConfig:
	return ExpeditionConfig.new(
		"iron_quarry",
		"Iron Quarry",
		"A collapsed surface mine. The veins run shallow but the ore is plentiful.",
		BalanceConfig.EXPEDITION_1_BASE_TIME,
		1,
		1,
		_iron_quarry_drop_table()
	)


static func _steel_depths_drop_table() -> DropTable:
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


static func steel_depths() -> ExpeditionConfig:
	return ExpeditionConfig.new(
		"steel_depths",
		"Steel Depths",
		"The old mines run deep. Ore harder than iron, but everything still breathes down here.",
		BalanceConfig.EXPEDITION_2_BASE_TIME,
		3,
		2,
		_steel_depths_drop_table()
	)


static func get_all_configs() -> Array[ExpeditionConfig]:
	return [iron_quarry(), steel_depths()]


static func get_config_by_id(id: String) -> ExpeditionConfig:
	for config in get_all_configs():
		if config.expedition_id == id:
			return config
	return null
