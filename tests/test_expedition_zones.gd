extends GutTest

# Tests for expedition zone configs and drop tables (M003/S02)


func test_zone_count() -> void:
	var configs := ExpeditionConfig.get_all_configs()
	assert_eq(configs.size(), 6, "get_all_configs() returns exactly 6 zones")


func test_starter_zone_count() -> void:
	assert_eq(ExpeditionConfig.get_starter_configs().size(), 3, "3 starter zones")


func test_rare_zone_count() -> void:
	assert_eq(ExpeditionConfig.get_rare_configs().size(), 3, "3 rare zones")


func test_get_configs_for_prestige_0_returns_3() -> void:
	var configs := ExpeditionConfig.get_configs_for_prestige(0)
	assert_eq(configs.size(), 3, "prestige 0 unlocks 3 zones")


func test_get_configs_for_prestige_1_returns_6() -> void:
	var configs := ExpeditionConfig.get_configs_for_prestige(1)
	assert_eq(configs.size(), 6, "prestige 1 unlocks all 6 zones")


func test_starter_zones_have_prestige_0() -> void:
	for config in ExpeditionConfig.get_starter_configs():
		assert_eq(config.required_prestige, 0, config.expedition_name + " required_prestige == 0")


func test_rare_zones_have_prestige_1() -> void:
	for config in ExpeditionConfig.get_rare_configs():
		assert_eq(config.required_prestige, 1, config.expedition_name + " required_prestige == 1")


func test_all_zones_have_unique_ids() -> void:
	var configs := ExpeditionConfig.get_all_configs()
	var seen_ids: Array[String] = []
	for config in configs:
		assert_false(config.expedition_id in seen_ids, "duplicate id: " + config.expedition_id)
		seen_ids.append(config.expedition_id)


func test_all_zones_have_non_empty_name_and_description() -> void:
	for config in ExpeditionConfig.get_all_configs():
		assert_ne(config.expedition_name, "", config.expedition_id + " has name")
		assert_ne(config.description, "", config.expedition_id + " has description")


func test_all_zones_have_positive_duration() -> void:
	for config in ExpeditionConfig.get_all_configs():
		assert_gt(config.duration_seconds, 0.0, config.expedition_name + " duration > 0")


func test_all_zones_have_drop_table() -> void:
	for config in ExpeditionConfig.get_all_configs():
		assert_not_null(config.drop_table, config.expedition_name + " has drop_table")
		assert_gt(config.drop_table.entries.size(), 0, config.expedition_name + " drop_table has entries")


func _has_iron_guaranteed(drop_table: DropTable) -> bool:
	for entry in drop_table.entries:
		if entry["type"] == "item" and entry["material_tier"] == Tag_List.MaterialTier.IRON and entry["guaranteed"]:
			return true
	return false


func _has_steel_entry(drop_table: DropTable) -> bool:
	for entry in drop_table.entries:
		if entry["type"] == "item" and entry["material_tier"] == Tag_List.MaterialTier.STEEL:
			return true
	return false


func test_starter_zones_have_guaranteed_iron_drop() -> void:
	for config in ExpeditionConfig.get_starter_configs():
		assert_true(_has_iron_guaranteed(config.drop_table), config.expedition_name + " has guaranteed iron drop")


func test_rare_zones_have_guaranteed_iron_drop() -> void:
	for config in ExpeditionConfig.get_rare_configs():
		assert_true(_has_iron_guaranteed(config.drop_table), config.expedition_name + " has guaranteed iron drop")


func test_rare_zones_have_steel_entry() -> void:
	for config in ExpeditionConfig.get_rare_configs():
		assert_true(_has_steel_entry(config.drop_table), config.expedition_name + " has steel drop entry")


func _get_steel_weight(drop_table: DropTable) -> int:
	for entry in drop_table.entries:
		if entry["type"] == "item" and entry["material_tier"] == Tag_List.MaterialTier.STEEL:
			return entry["weight"]
	return -1


func test_rare_zones_steel_weight_is_5() -> void:
	for config in ExpeditionConfig.get_rare_configs():
		assert_eq(_get_steel_weight(config.drop_table), 5, config.expedition_name + " steel weight == 5")


func test_starter_zones_have_no_steel_entry() -> void:
	for config in ExpeditionConfig.get_starter_configs():
		assert_false(_has_steel_entry(config.drop_table), config.expedition_name + " has no steel drop")


func test_drop_table_roll_returns_results() -> void:
	for config in ExpeditionConfig.get_all_configs():
		# Roll multiple times to ensure non-empty results (guaranteed iron should always appear)
		for _i in range(5):
			var results := config.drop_table.roll()
			assert_gt(results.size(), 0, config.expedition_name + " roll() returns non-empty")


func test_transmute_expedition_id() -> void:
	assert_eq(ExpeditionConfig.transmute().expedition_id, "transmute")


func test_augmentation_expedition_id() -> void:
	assert_eq(ExpeditionConfig.augmentation().expedition_id, "augmentation")


func test_alteration_expedition_id() -> void:
	assert_eq(ExpeditionConfig.alteration().expedition_id, "alteration")


func test_alchemy_expedition_id() -> void:
	assert_eq(ExpeditionConfig.alchemy().expedition_id, "alchemy")


func test_exaltation_expedition_id() -> void:
	assert_eq(ExpeditionConfig.exaltation().expedition_id, "exaltation")


func test_annulment_expedition_id() -> void:
	assert_eq(ExpeditionConfig.annulment().expedition_id, "annulment")


func test_get_config_by_id_returns_correct_zone() -> void:
	var cfg := ExpeditionConfig.get_config_by_id("alchemy")
	assert_not_null(cfg)
	assert_eq(cfg.expedition_name, "Alchemy")


func test_get_config_by_id_returns_null_for_unknown() -> void:
	assert_null(ExpeditionConfig.get_config_by_id("nonexistent"))
