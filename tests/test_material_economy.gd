extends GutTest

# Tests for material currency tracking and ItemFactory cost gating (T02)

var _game_state: Node


func before_each() -> void:
	_game_state = GameState
	_game_state.initialize_fresh_game()


func test_iron_steel_wood_in_currency_keys() -> void:
	assert_true("iron" in GameState.CURRENCY_KEYS, "iron in CURRENCY_KEYS")
	assert_true("steel" in GameState.CURRENCY_KEYS, "steel in CURRENCY_KEYS")
	assert_true("ash" in GameState.CURRENCY_KEYS, "ash in CURRENCY_KEYS")
	assert_true("oak" in GameState.CURRENCY_KEYS, "oak in CURRENCY_KEYS")


func test_material_display_names() -> void:
	assert_eq(GameState.CURRENCY_DISPLAY_NAMES["iron"], "Iron")
	assert_eq(GameState.CURRENCY_DISPLAY_NAMES["steel"], "Steel")
	assert_eq(GameState.CURRENCY_DISPLAY_NAMES["ash"], "Ash Wood")
	assert_eq(GameState.CURRENCY_DISPLAY_NAMES["oak"], "Oak Wood")


func test_materials_initialized_to_zero() -> void:
	assert_eq(GameState.currency_counts["iron"], 0)
	assert_eq(GameState.currency_counts["steel"], 0)
	assert_eq(GameState.currency_counts["ash"], 0)
	assert_eq(GameState.currency_counts["oak"], 0)


func test_wipe_run_resets_materials() -> void:
	GameState.add_currencies({"iron": 10, "steel": 5, "ash": 3})
	GameState.wipe_run_state()
	assert_eq(GameState.currency_counts["iron"], 0)
	assert_eq(GameState.currency_counts["steel"], 0)
	assert_eq(GameState.currency_counts["ash"], 0)


func test_create_base_iron_item_costs_iron() -> void:
	GameState.add_currencies({"iron": 3})
	var item: HeroItem = ItemFactory.create_base("iron_shortsword")
	assert_not_null(item)
	assert_eq(GameState.currency_counts["iron"], 3 - BalanceConfig.BASE_ITEM_IRON_COST)


func test_create_base_steel_item_costs_steel() -> void:
	GameState.add_currencies({"steel": 3})
	var item: HeroItem = ItemFactory.create_base("steel_longsword")
	assert_not_null(item)
	assert_eq(GameState.currency_counts["steel"], 3 - BalanceConfig.BASE_ITEM_STEEL_COST)


func test_create_base_iron_returns_null_when_no_iron() -> void:
	assert_eq(GameState.currency_counts["iron"], 0)
	var item: HeroItem = ItemFactory.create_base("iron_shortsword")
	assert_null(item, "should return null when iron is 0")


func test_create_base_steel_returns_null_when_no_steel() -> void:
	assert_eq(GameState.currency_counts["steel"], 0)
	var item: HeroItem = ItemFactory.create_base("steel_longsword")
	assert_null(item, "should return null when steel is 0")


func test_can_afford_base_true_when_funded() -> void:
	GameState.add_currencies({"iron": 5})
	assert_true(ItemFactory.can_afford_base("iron_cap"))


func test_can_afford_base_false_when_empty() -> void:
	assert_false(ItemFactory.can_afford_base("iron_cap"))


func test_can_afford_base_steel_false_when_empty() -> void:
	assert_false(ItemFactory.can_afford_base("steel_helm"))
