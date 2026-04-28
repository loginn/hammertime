class_name ExpeditionConfig extends Resource

var expedition_id: String
var expedition_name: String
var description: String
var duration_seconds: float
var difficulty: int
var reward_tier: int
var required_prestige: int

var drop_table: DropTable = null
var resource_drops: Array[Dictionary] = []


func _init(
	p_id: String = "",
	p_name: String = "",
	p_description: String = "",
	p_duration: float = 30.0,
	p_difficulty: int = 1,
	p_reward_tier: int = 1,
	p_drop_table: DropTable = null,
	p_required_prestige: int = 0,
	p_resource_drops: Array[Dictionary] = []
) -> void:
	expedition_id = p_id
	expedition_name = p_name
	description = p_description
	duration_seconds = p_duration
	difficulty = p_difficulty
	reward_tier = p_reward_tier
	drop_table = p_drop_table
	required_prestige = p_required_prestige
	resource_drops = p_resource_drops


# --- Wood Drop Helper ---

static func _add_wood_entries(dt: DropTable, is_rare: bool) -> void:
	var wood_key: String = "oak" if is_rare else "ash"
	dt.entries.append(
		DropTable.create_entry("currency", wood_key, -1, 1, 1, 1, false)
	)


# --- Starter Zone Drop Tables ---

static func _transmute_drop_table() -> DropTable:
	var dt := DropTable.new()
	dt.drop_rolls = 1
	dt.entries = [
		DropTable.create_entry("currency", "tack", -1, 0, 4, 8, true),
		DropTable.create_entry("currency", "tuning", -1, 30, 1, 1, false),
		DropTable.create_entry("currency", "forge", -1, 10, 1, 1, false),
	]
	if PrestigeManager.prestige_count >= 2:
		_add_wood_entries(dt, false)
	return dt


static func _augmentation_drop_table() -> DropTable:
	var dt := DropTable.new()
	dt.drop_rolls = 1
	dt.entries = [
		DropTable.create_entry("currency", "forge", -1, 0, 2, 4, true),
		DropTable.create_entry("currency", "tuning", -1, 30, 1, 1, false),
		DropTable.create_entry("currency", "tack", -1, 15, 2, 3, false),
	]
	if PrestigeManager.prestige_count >= 2:
		_add_wood_entries(dt, false)
	return dt


static func _alteration_drop_table() -> DropTable:
	var dt := DropTable.new()
	dt.drop_rolls = 1
	dt.entries = [
		DropTable.create_entry("currency", "tuning", -1, 0, 4, 8, true),
		DropTable.create_entry("currency", "grand", -1, 25, 1, 1, false),
		DropTable.create_entry("currency", "runic", -1, 15, 1, 1, false),
		DropTable.create_entry("currency", "tuning", -1, 5, 1, 1, false),
	]
	if PrestigeManager.prestige_count >= 2:
		_add_wood_entries(dt, false)
	return dt


# --- Rare Zone Drop Tables ---

static func _alchemy_drop_table() -> DropTable:
	var dt := DropTable.new()
	dt.drop_rolls = 1
	dt.entries = [
		DropTable.create_entry("currency", "grand", -1, 0, 1, 2, true),
		DropTable.create_entry("currency", "forge", -1, 25, 1, 2, false),
		DropTable.create_entry("currency", "tuning", -1, 10, 2, 3, false),
	]
	if PrestigeManager.prestige_count >= 2:
		_add_wood_entries(dt, true)
	return dt


static func _exaltation_drop_table() -> DropTable:
	var dt := DropTable.new()
	dt.drop_rolls = 1
	dt.entries = [
		DropTable.create_entry("currency", "runic", -1, 0, 1, 2, true),
		DropTable.create_entry("currency", "grand", -1, 25, 1, 1, false),
		DropTable.create_entry("currency", "forge", -1, 10, 1, 1, false),
	]
	if PrestigeManager.prestige_count >= 2:
		_add_wood_entries(dt, true)
	return dt


static func _annulment_drop_table() -> DropTable:
	var dt := DropTable.new()
	dt.drop_rolls = 1
	dt.entries = [
		DropTable.create_entry("currency", "claw", -1, 0, 1, 2, true),
		DropTable.create_entry("currency", "runic", -1, 25, 1, 1, false),
		DropTable.create_entry("currency", "grand", -1, 10, 1, 1, false),
	]
	if PrestigeManager.prestige_count >= 2:
		_add_wood_entries(dt, true)
	return dt


# --- Zone Factory Methods ---

static func transmute() -> ExpeditionConfig:
	var res: Array[Dictionary] = [{"key": "iron", "chance": 1.0, "qty_min": 1, "qty_max": 2}]
	return ExpeditionConfig.new(
		"transmute",
		"Transmute",
		"A shallow surface dig. Ore runs thin but the tack flows freely.",
		BalanceConfig.EXPEDITION_TRANSMUTE_TIME,
		1,
		1,
		_transmute_drop_table(),
		0,
		res
	)


static func augmentation() -> ExpeditionConfig:
	var res: Array[Dictionary] = [{"key": "iron", "chance": 1.0, "qty_min": 1, "qty_max": 3}]
	return ExpeditionConfig.new(
		"augmentation",
		"Augmentation",
		"A worked hillside quarry. Good for tuning ore and the occasional forge shard.",
		BalanceConfig.EXPEDITION_AUGMENTATION_TIME,
		2,
		1,
		_augmentation_drop_table(),
		0,
		res
	)


static func alteration() -> ExpeditionConfig:
	var res: Array[Dictionary] = [{"key": "iron", "chance": 1.0, "qty_min": 2, "qty_max": 4}]
	return ExpeditionConfig.new(
		"alteration",
		"Alteration",
		"An old trade route collapsed into a vein network. Forge ore dominates. Rare hammers surface occasionally.",
		BalanceConfig.EXPEDITION_ALTERATION_TIME,
		3,
		1,
		_alteration_drop_table(),
		0,
		res
	)


static func alchemy() -> ExpeditionConfig:
	var res: Array[Dictionary] = [
		{"key": "iron", "chance": 1.0, "qty_min": 2, "qty_max": 4},
		{"key": "steel", "chance": 0.05, "qty_min": 1, "qty_max": 2},
	]
	return ExpeditionConfig.new(
		"regal",
		"Regal",
		"A resonant cave complex. Grand hammers ring off every wall. Steel seams run thin but present.",
		BalanceConfig.EXPEDITION_ALCHEMY_TIME,
		3,
		2,
		_alchemy_drop_table(),
		1,
		res
	)


static func exaltation() -> ExpeditionConfig:
	var res: Array[Dictionary] = [
		{"key": "iron", "chance": 1.0, "qty_min": 2, "qty_max": 4},
		{"key": "steel", "chance": 0.05, "qty_min": 1, "qty_max": 3},
	]
	return ExpeditionConfig.new(
		"exaltation",
		"Exaltation",
		"A deep magmatic shelf. Runic hammers are common here. Steel bleeds from the cracks.",
		BalanceConfig.EXPEDITION_EXALTATION_TIME,
		4,
		2,
		_exaltation_drop_table(),
		1,
		res
	)


static func annulment() -> ExpeditionConfig:
	var res: Array[Dictionary] = [
		{"key": "iron", "chance": 1.0, "qty_min": 3, "qty_max": 5},
		{"key": "steel", "chance": 0.05, "qty_min": 1, "qty_max": 3},
	]
	return ExpeditionConfig.new(
		"annulment",
		"Annulment",
		"The lowest known excavation. Claw hammers are the prize. Steel is a certainty to the patient.",
		BalanceConfig.EXPEDITION_ANNULMENT_TIME,
		4,
		2,
		_annulment_drop_table(),
		1,
		res
	)


# --- Config Access ---

static func get_all_configs() -> Array[ExpeditionConfig]:
	return [transmute(), augmentation(), alteration(), alchemy(), exaltation(), annulment()]


static func get_starter_configs() -> Array[ExpeditionConfig]:
	return [transmute(), augmentation(), alteration()]


static func get_rare_configs() -> Array[ExpeditionConfig]:
	return [alchemy(), exaltation(), annulment()]


static func get_configs_for_prestige(prestige_count: int) -> Array[ExpeditionConfig]:
	var result: Array[ExpeditionConfig] = []
	for config in get_all_configs():
		if config.required_prestige <= prestige_count:
			result.append(config)
	return result


static func get_config_by_id(id: String) -> ExpeditionConfig:
	for config in get_all_configs():
		if config.expedition_id == id:
			return config
	return null
