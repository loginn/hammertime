extends GutTest


func before_each() -> void:
	GameState.initialize_fresh_game()


func test_iron_steel_wood_in_currency_keys() -> void:
	assert_true("iron" in GameState.CURRENCY_KEYS, "iron in CURRENCY_KEYS")
	assert_true("steel" in GameState.CURRENCY_KEYS, "steel in CURRENCY_KEYS")
	assert_true("wood" in GameState.CURRENCY_KEYS, "wood in CURRENCY_KEYS")


func test_material_currencies_initialize_to_zero() -> void:
	assert_eq(GameState.currency_counts["iron"], 0, "iron starts at 0")
	assert_eq(GameState.currency_counts["steel"], 0, "steel starts at 0")
	assert_eq(GameState.currency_counts["wood"], 0, "wood starts at 0")


func test_create_base_consumes_iron() -> void:
	GameState.currency_counts["iron"] = 5
	var item := ItemFactory.create_base("iron_shortsword")
	assert_not_null(item, "iron item created")
	assert_eq(GameState.currency_counts["iron"], 4, "iron decreased by 1")


func test_create_base_fails_without_iron() -> void:
	GameState.currency_counts["iron"] = 0
	var item := ItemFactory.create_base("iron_shortsword")
	assert_null(item, "returns null with no iron")
	assert_eq(GameState.currency_counts["iron"], 0, "iron unchanged")


func test_create_base_consumes_steel() -> void:
	GameState.currency_counts["steel"] = 5
	var item := ItemFactory.create_base("steel_longsword")
	assert_not_null(item, "steel item created")
	assert_eq(GameState.currency_counts["steel"], 4, "steel decreased by 1")


func test_can_afford_base() -> void:
	GameState.currency_counts["iron"] = 0
	assert_false(ItemFactory.can_afford_base("iron_shortsword"), "cannot afford with 0 iron")
	GameState.currency_counts["iron"] = 1
	assert_true(ItemFactory.can_afford_base("iron_shortsword"), "can afford with 1 iron")


func test_scour_in_hidden_currencies() -> void:
	assert_true("scour" in BalanceConfig.HIDDEN_CURRENCIES, "scour is in HIDDEN_CURRENCIES")


func test_scour_hammer_code_preserved() -> void:
	var scour := ScourHammer.new()
	assert_not_null(scour, "ScourHammer instantiates successfully")
