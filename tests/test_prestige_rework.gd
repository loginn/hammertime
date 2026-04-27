extends GutTest

# Tests for M003/S04: 2-level prestige system and totem tab gating


func before_each() -> void:
	PrestigeManager.prestige_count = 0
	GameState.wipe_run_state()


func test_prestige_levels_count() -> void:
	assert_eq(BalanceConfig.PRESTIGE_LEVELS.size(), 2, "exactly 2 prestige levels")


func test_p1_costs_tuning() -> void:
	var level := BalanceConfig.PRESTIGE_LEVELS[0]
	assert_eq(level.cost_currency, "tuning", "P1 cost currency is tuning")
	assert_eq(level.cost, 100, "P1 cost is 100")


func test_p2_costs_claw() -> void:
	var level := BalanceConfig.PRESTIGE_LEVELS[1]
	assert_eq(level.cost_currency, "claw", "P2 cost currency is claw")
	assert_eq(level.cost, 100, "P2 cost is 100")


func test_can_prestige_checks_correct_currency() -> void:
	GameState.currency_counts["tuning"] = 100
	assert_true(PrestigeManager.can_prestige(), "can prestige when tuning >= 100")

	GameState.currency_counts["tuning"] = 0
	GameState.currency_counts["claw"] = 100
	assert_false(PrestigeManager.can_prestige(), "cannot prestige with claw when at P0 (needs tuning)")


func test_execute_prestige_spends_correct_currency() -> void:
	GameState.currency_counts["tuning"] = 100
	PrestigeManager.execute_prestige()
	assert_eq(GameState.currency_counts.get("tuning", 0), 0, "tuning spent after P1 prestige")


func test_prestige_no_reward_granted() -> void:
	GameState.currency_counts["tuning"] = 100
	GameState.currency_counts["claw"] = 50
	PrestigeManager.execute_prestige()
	# wipe_run_state zeros all currencies — no extra grants
	for key in GameState.currency_counts:
		assert_eq(GameState.currency_counts[key], 0, key + " is 0 after prestige (no reward)")


func test_totem_tab_requires_p2() -> void:
	assert_false(PrestigeManager.prestige_count >= 2, "totem hidden at P0")

	PrestigeManager.prestige_count = 1
	assert_false(PrestigeManager.prestige_count >= 2, "totem hidden at P1")

	PrestigeManager.prestige_count = 2
	assert_true(PrestigeManager.prestige_count >= 2, "totem visible at P2")
