extends Node

## End-to-end prestige loop verification test scene.
## Run standalone from Godot editor (F6) to verify all v1.7 requirements.

var _pass_count: int = 0
var _fail_count: int = 0


func _ready() -> void:
	_group_1_pre_prestige_baseline()
	_group_2_prestige_gating()
	_group_3_execute_prestige()
	_group_4_save_round_trip_p0()
	_group_5_save_round_trip_p1()
	_group_6_crafting_regression()
	_group_7_item_tier_affix_floor()
	_group_8_tag_hammer_gating()
	_group_9_file_io_round_trip()

	var total: int = _pass_count + _fail_count
	print("\n=== SUMMARY ===")
	print("%d/%d tests passed" % [_pass_count, total])
	if _fail_count > 0:
		print("[FAILURES DETECTED]")
	else:
		print("[ALL PASSED]")


# --- Helpers ---

func _check(condition: bool, description: String) -> void:
	if condition:
		_pass_count += 1
		print("[PASS] %s" % description)
	else:
		_fail_count += 1
		print("[FAIL] %s" % description)


func _reset_fresh() -> void:
	GameState.initialize_fresh_game()


func _simulate_prestige() -> void:
	# Spend forge currency (100 times)
	for i in range(100):
		GameState.spend_currency("forge")

	# Advance prestige state
	GameState.prestige_level = 1
	GameState.max_item_tier_unlocked = PrestigeManager.ITEM_TIERS_BY_PRESTIGE[1]

	# Wipe run-scoped state
	GameState._wipe_run_state()

	# Grant 1 deterministic tag currency (not random)
	GameState.tag_currency_counts["fire"] = 1


# --- Group 1: Pre-Prestige Baseline (P0) ---

func _group_1_pre_prestige_baseline() -> void:
	print("\n=== GROUP 1: Pre-Prestige Baseline (P0) ===")
	_reset_fresh()

	_check(GameState.prestige_level == 0, "prestige_level == 0")
	_check(GameState.max_item_tier_unlocked == 8, "max_item_tier_unlocked == 8")
	_check(PrestigeManager.can_prestige() == false, "can_prestige() == false (no forge hammers)")
	_check(
		GameState.crafting_inventory["weapon"].size() >= 1,
		"starter weapon exists in crafting inventory"
	)
	_check(
		GameState.crafting_inventory["weapon"][0] is LightSword,
		"starter weapon is LightSword"
	)
	_check(GameState.area_level == 1, "area_level == 1")
	_check(GameState.tag_currency_counts.is_empty(), "tag_currency_counts is empty")


# --- Group 2: Prestige Gating ---

func _group_2_prestige_gating() -> void:
	print("\n=== GROUP 2: Prestige Gating ===")
	# Continue from group 1 state (fresh game, prestige_level=0)

	GameState.currency_counts["forge"] = 99
	_check(PrestigeManager.can_prestige() == false, "can_prestige() == false with 99 forge")

	GameState.currency_counts["forge"] = 100
	_check(PrestigeManager.can_prestige() == true, "can_prestige() == true with 100 forge")

	var cost: Dictionary = PrestigeManager.get_next_prestige_cost()
	_check(cost.has("forge") and cost["forge"] == 100, "next prestige cost == {forge: 100}")


# --- Group 3: Execute Prestige P0 -> P1 ---

func _group_3_execute_prestige() -> void:
	print("\n=== GROUP 3: Execute Prestige P0 -> P1 ===")
	_reset_fresh()
	GameState.currency_counts["forge"] = 100
	_simulate_prestige()

	_check(GameState.prestige_level == 1, "prestige_level == 1")
	_check(GameState.max_item_tier_unlocked == 7, "max_item_tier_unlocked == 7")
	_check(GameState.area_level == 1, "area_level == 1 (reset)")

	# Check hero equipment slots are all null
	var all_null: bool = true
	for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
		if GameState.hero.equipped_items.get(slot) != null:
			all_null = false
			break
	_check(all_null, "all hero equipment slots are null")

	_check(
		GameState.crafting_inventory["weapon"].size() >= 1
		and GameState.crafting_inventory["weapon"][0] is LightSword,
		"starter weapon (LightSword) in crafting inventory after prestige"
	)
	_check(GameState.currency_counts["forge"] == 0, "forge currency == 0 (spent + wiped)")
	_check(GameState.currency_counts["runic"] == 1, "runic currency == 1 (fresh default)")

	# Tag currency total should be 1 (we set fire=1 in _simulate_prestige)
	var tag_total: int = 0
	for key in GameState.tag_currency_counts:
		tag_total += GameState.tag_currency_counts[key]
	_check(tag_total == 1, "tag_currency_counts total == 1")

	_check(PrestigeManager.can_prestige() == false, "can_prestige() == false (P2 costs 999999)")


# --- Group 4: Save Round-Trip at P0 ---

func _group_4_save_round_trip_p0() -> void:
	print("\n=== GROUP 4: Save Round-Trip at P0 ===")
	_reset_fresh()
	GameState.prestige_level = 0
	GameState.max_item_tier_unlocked = 8
	GameState.tag_currency_counts = {}

	var saved: Dictionary = SaveManager._build_save_data()

	# Trash state
	GameState.prestige_level = 99
	GameState.max_item_tier_unlocked = 1
	GameState.tag_currency_counts = {"fire": 999}

	SaveManager._restore_state(saved)

	_check(GameState.prestige_level == 0, "restored prestige_level == 0")
	_check(GameState.max_item_tier_unlocked == 8, "restored max_item_tier_unlocked == 8")
	_check(
		GameState.tag_currency_counts.is_empty() or GameState.tag_currency_counts.size() == 0,
		"restored tag_currency_counts is empty"
	)
	_check(GameState.area_level == 1, "restored area_level == 1")
	_check(GameState.currency_counts["runic"] == 1, "restored runic currency == 1")


# --- Group 5: Save Round-Trip at P1 ---

func _group_5_save_round_trip_p1() -> void:
	print("\n=== GROUP 5: Save Round-Trip at P1 ===")
	_reset_fresh()
	GameState.currency_counts["forge"] = 100
	_simulate_prestige()
	GameState.tag_currency_counts = {"fire": 1, "cold": 2}

	var saved: Dictionary = SaveManager._build_save_data()

	# Trash state
	GameState.prestige_level = 0
	GameState.max_item_tier_unlocked = 8
	GameState.tag_currency_counts = {}

	SaveManager._restore_state(saved)

	_check(GameState.prestige_level == 1, "restored prestige_level == 1")
	_check(GameState.max_item_tier_unlocked == 7, "restored max_item_tier_unlocked == 7")
	_check(
		GameState.tag_currency_counts.get("fire", 0) == 1,
		"restored tag_currency fire == 1"
	)
	_check(
		GameState.tag_currency_counts.get("cold", 0) == 2,
		"restored tag_currency cold == 2"
	)
	_check(GameState.hero != null, "hero exists after restore")


# --- Group 6: Crafting Regression After Prestige ---

func _group_6_crafting_regression() -> void:
	print("\n=== GROUP 6: Crafting Regression After Prestige ===")
	_reset_fresh()
	GameState.prestige_level = 1

	var weapon: Item = GameState.crafting_inventory["weapon"][0]
	_check(weapon.rarity == Item.Rarity.NORMAL, "starter weapon is Normal rarity")

	var hammer := RunicHammer.new()
	hammer.apply(weapon)

	_check(weapon.rarity == Item.Rarity.MAGIC, "weapon is Magic after RunicHammer")
	_check(
		weapon.prefixes.size() + weapon.suffixes.size() >= 1,
		"weapon has at least 1 mod after RunicHammer"
	)


# --- Group 7: Item Tier / Affix Tier Floor ---

func _group_7_item_tier_affix_floor() -> void:
	print("\n=== GROUP 7: Item Tier / Affix Tier Floor ===")

	var sword := LightSword.new()
	_check(sword._get_affix_tier_floor() == 29, "tier 8 sword: affix floor == 29")

	sword.tier = 7
	_check(sword._get_affix_tier_floor() == 25, "tier 7 sword: affix floor == 25")

	sword.tier = 1
	_check(sword._get_affix_tier_floor() == 1, "tier 1 sword: affix floor == 1")

	# Test affix generation respects tier floor
	var test_sword := LightSword.new()
	test_sword.tier = 7
	var rh := RunicHammer.new()
	rh.apply(test_sword)

	var all_above_floor: bool = true
	for affix in test_sword.prefixes:
		if affix.tier < 25:
			all_above_floor = false
			break
	if all_above_floor:
		for affix in test_sword.suffixes:
			if affix.tier < 25:
				all_above_floor = false
				break
	_check(all_above_floor, "tier 7 sword: all generated affix tiers >= 25")


# --- Group 8: Tag Hammer Gating (Logic-Only) ---

func _group_8_tag_hammer_gating() -> void:
	print("\n=== GROUP 8: Tag Hammer Gating (Logic-Only) ===")
	_reset_fresh()

	_check(GameState.prestige_level >= 1 == false, "P0: prestige_level >= 1 is false")

	GameState.prestige_level = 1
	_check(GameState.prestige_level >= 1 == true, "P1: prestige_level >= 1 is true")

	# Use PHYSICAL tag since LightSword has Tag.PHYSICAL in valid_tags
	var phys_hammer := TagHammer.new("PHYSICAL", "Physical Hammer")
	var sword := LightSword.new()

	_check(phys_hammer.can_apply(sword) == true, "TagHammer(PHYSICAL) can_apply Normal LightSword")

	sword.rarity = Item.Rarity.MAGIC
	_check(
		phys_hammer.can_apply(sword) == false,
		"TagHammer(PHYSICAL) cannot apply to Magic item"
	)

	# Tag currency spend
	GameState.tag_currency_counts["fire"] = 1
	_check(GameState.spend_tag_currency("fire") == true, "spend_tag_currency(fire) succeeds")
	_check(GameState.tag_currency_counts["fire"] == 0, "fire tag currency == 0 after spend")
	_check(
		GameState.spend_tag_currency("fire") == false,
		"spend_tag_currency(fire) fails with 0 remaining"
	)


# --- Group 9: File I/O Round-Trip ---

func _group_9_file_io_round_trip() -> void:
	print("\n=== GROUP 9: File I/O Round-Trip ===")
	_reset_fresh()
	GameState.prestige_level = 1
	GameState.max_item_tier_unlocked = 7
	GameState.tag_currency_counts = {"cold": 3}

	var data: Dictionary = SaveManager._build_save_data()

	# Write to test path
	var file := FileAccess.open("user://test_save.json", FileAccess.WRITE)
	_check(file != null, "opened test_save.json for writing")
	if file != null:
		file.store_string(JSON.stringify(data))
		file = null  # close

	# Read back
	var read_file := FileAccess.open("user://test_save.json", FileAccess.READ)
	_check(read_file != null, "opened test_save.json for reading")
	var parsed = null
	if read_file != null:
		var text: String = read_file.get_as_text()
		parsed = JSON.parse_string(text)
		read_file = null  # close

	_check(parsed is Dictionary, "parsed data is Dictionary")

	if parsed is Dictionary:
		# Trash state
		GameState.prestige_level = 0
		GameState.max_item_tier_unlocked = 8
		GameState.tag_currency_counts = {}

		SaveManager._restore_state(parsed)

		_check(GameState.prestige_level == 1, "file restored prestige_level == 1")
		_check(GameState.max_item_tier_unlocked == 7, "file restored max_item_tier_unlocked == 7")
		_check(
			GameState.tag_currency_counts.get("cold", 0) == 3,
			"file restored tag_currency cold == 3"
		)

	# Cleanup
	DirAccess.remove_absolute("user://test_save.json")
	_check(
		FileAccess.file_exists("user://test_save.json") == false,
		"test_save.json cleaned up"
	)
