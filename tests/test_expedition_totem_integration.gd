extends GutTest

# Integration tests: totem modifiers → ExpeditionResolver reward output.
# Proves R013 (modifiers affect drops) and synergy amplification (R011).
#
# Strategy: populate GameState.totem_grid with real TotemPiece objects carrying
# known affixes, then call ExpeditionResolver with a minimal DropTable.


# ---------------------------------------------------------------------------
# Helpers — no typed returns to avoid GDScript parse errors with class_name types
# ---------------------------------------------------------------------------

func _make_config_currency_only():
	# Guaranteed single currency entry, fixed qty=10, difficulty=1.
	var dt = DropTable.new()
	dt.drop_rolls = 1
	dt.entries = [
		DropTable.create_entry("currency", "tack", -1, -1, 10, 10, true),
	]
	return ExpeditionConfig.new("test", "Test", "Test config", 300.0, 1, 1, dt, 0)


func _make_resolver():
	var r = ExpeditionResolver.new()
	r.active_config = _make_config_currency_only()
	return r


func _total_currency(rewards: Dictionary) -> int:
	var total: int = 0
	for key in rewards.get("currencies", {}):
		total += rewards["currencies"][key]
	return total


func _make_drop_qty_piece(qty_value: int):
	var piece = TotemPiece.new()
	var a = Affix.new("drop_qty", Affix.AffixType.PREFIX, 0, 0, [Tag.DROP_QUANTITY])
	a.value = qty_value
	piece.prefixes.append(a)
	return piece


func _make_bonus_roll_piece(roll_value: int):
	# DROP_QUALITY SUFFIX maps to bonus_roll_chance in get_expedition_modifiers()
	var piece = TotemPiece.new()
	var a = Affix.new("bonus_roll", Affix.AffixType.SUFFIX, 0, 0, [Tag.DROP_QUALITY])
	a.value = roll_value
	piece.suffixes.append(a)
	return piece


func _make_hammer_piece(hammer_value: int):
	var piece = TotemPiece.new()
	var a = Affix.new("hammer", Affix.AffixType.PREFIX, 0, 0, [Tag.HAMMER_CHANCE])
	a.value = hammer_value
	piece.prefixes.append(a)
	return piece


func before_each() -> void:
	GameState.totem_grid = TotemGrid.new()


# ---------------------------------------------------------------------------
# Test cases
# ---------------------------------------------------------------------------

func test_empty_grid_no_modifier_effect() -> void:
	seed(42)
	var rewards = _make_resolver().resolve_rewards()
	assert_true(rewards.has("currencies"), "rewards has currencies key")
	assert_gt(rewards["currencies"].get("tack", 0), 0, "baseline tack present")


func test_drop_quantity_scales_currencies() -> void:
	# Run 20 parallel trials: empty grid vs drop_quantity=100 piece.
	# qty=10 fixed, drop_quantity=100 → boosted = int(scaled * 2.0) always >= scaled.
	var baseline_total: int = 0
	var boosted_total: int = 0
	var trials: int = 20

	for i in range(trials):
		seed(i * 7)
		GameState.totem_grid = TotemGrid.new()
		baseline_total += _total_currency(_make_resolver().resolve_rewards())

	for i in range(trials):
		seed(i * 7)
		GameState.totem_grid = TotemGrid.new()
		GameState.totem_grid.place_piece(Vector2i(0, 0), _make_drop_qty_piece(100))
		boosted_total += _total_currency(_make_resolver().resolve_rewards())

	var baseline_avg = float(baseline_total) / trials
	var boosted_avg = float(boosted_total) / trials
	assert_gt(boosted_avg, baseline_avg * 1.5,
		"drop_quantity=100 should produce >1.5x currency (%.1f vs %.1f)" % [boosted_avg, baseline_avg])


func test_duration_reduction_shortens_time() -> void:
	GameState.totem_grid = TotemGrid.new()
	var base_dur = _make_resolver().get_effective_duration()

	var dr_piece = TotemPiece.new()
	var a = Affix.new("dur_red", Affix.AffixType.PREFIX, 0, 0, [Tag.DURATION])
	a.value = 50  # 50% duration reduction
	dr_piece.prefixes.append(a)
	GameState.totem_grid = TotemGrid.new()
	GameState.totem_grid.place_piece(Vector2i(0, 0), dr_piece)
	var mod_dur = _make_resolver().get_effective_duration()

	assert_lt(mod_dur, base_dur,
		"duration_reduction=50 piece shortens effective duration (%.2f < %.2f)" % [mod_dur, base_dur])


func test_bonus_roll_adds_extra_roll() -> void:
	# bonus_roll_chance >= 1.0 → integer extra_rolls=1 → guaranteed second roll.
	# With guaranteed-only DropTable, 2 rolls = 2x tack accumulated.
	seed(11)
	GameState.totem_grid = TotemGrid.new()
	var base_tack: int = _make_resolver().resolve_rewards()["currencies"].get("tack", 0)

	seed(11)
	GameState.totem_grid = TotemGrid.new()
	GameState.totem_grid.place_piece(Vector2i(0, 0), _make_bonus_roll_piece(100))
	var bonus_tack: int = _make_resolver().resolve_rewards()["currencies"].get("tack", 0)

	assert_gt(bonus_tack, base_tack,
		"bonus_roll_chance=100 (guaranteed extra roll) produces more tack than baseline")


func test_synergy_amplifies_drop_quantity_in_totem_grid() -> void:
	# Two adjacent same-deity pieces with drop_quantity=10 each.
	# Each gets 1.5x synergy → total = 10*1.5 + 10*1.5 = 30.
	var grid = TotemGrid.new()
	var pa = _make_drop_qty_piece(10)
	pa.deity_tag = Tag.CTHULHU
	var pb = _make_drop_qty_piece(10)
	pb.deity_tag = Tag.CTHULHU
	grid.place_piece(Vector2i(0, 0), pa)
	grid.place_piece(Vector2i(1, 0), pb)
	var mods = grid.get_effective_modifiers()
	assert_almost_eq(mods["drop_quantity"], 30.0, 0.01,
		"two adjacent same-deity pieces (dq=10 each) with 1.5x synergy → dq=30")


func test_synergy_produces_more_than_non_synergy_pair() -> void:
	var non_syn = TotemGrid.new()
	var p1 = _make_drop_qty_piece(10)
	p1.deity_tag = Tag.CTHULHU
	var p2 = _make_drop_qty_piece(10)
	p2.deity_tag = Tag.HASTUR
	non_syn.place_piece(Vector2i(0, 0), p1)
	non_syn.place_piece(Vector2i(1, 0), p2)

	var syn = TotemGrid.new()
	var pa = _make_drop_qty_piece(10)
	pa.deity_tag = Tag.CTHULHU
	var pb = _make_drop_qty_piece(10)
	pb.deity_tag = Tag.CTHULHU
	syn.place_piece(Vector2i(0, 0), pa)
	syn.place_piece(Vector2i(1, 0), pb)

	var non_syn_mods = non_syn.get_effective_modifiers()
	var syn_mods = syn.get_effective_modifiers()
	assert_almost_eq(non_syn_mods["drop_quantity"], 20.0, 0.01, "non-synergy: 10+10=20")
	assert_almost_eq(syn_mods["drop_quantity"], 30.0, 0.01, "synergy: 10*1.5+10*1.5=30")
	assert_gt(syn_mods["drop_quantity"], non_syn_mods["drop_quantity"],
		"synergy pair > non-synergy pair")


func test_hammer_chance_produces_extra_drops_over_trials() -> void:
	# hammer_chance=100 → randf() < 1.0 always → guaranteed bonus hammer-type drop.
	var base_total: int = 0
	var boosted_total: int = 0
	for i in range(10):
		seed(i * 13)
		GameState.totem_grid = TotemGrid.new()
		base_total += _total_currency(_make_resolver().resolve_rewards())
	for i in range(10):
		seed(i * 13)
		GameState.totem_grid = TotemGrid.new()
		GameState.totem_grid.place_piece(Vector2i(0, 0), _make_hammer_piece(100))
		boosted_total += _total_currency(_make_resolver().resolve_rewards())
	assert_gt(boosted_total, base_total,
		"hammer_chance=100 (guaranteed) produces more total drops than baseline")
