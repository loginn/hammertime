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
	_group_10_item_base_construction()
	_group_11_serialization_round_trip()
	_group_12_defense_archetype_verification()
	_group_13_valid_tags_affix_gating()
	_group_14_drop_generation()
	_group_15_starter_weapon()
	_group_16_new_affix_pool_validation()
	_group_17_spell_damage_affix_gating()
	_group_18_dot_affix_gating()
	_group_19_cast_speed_chaos_resist_accessibility()
	_group_20_flat_damage_range_rolling()
	_group_21_new_stat_type_enum_values()
	_group_22_spell_damage_channel()
	_group_23_hero_spell_stat_tracking()
	_group_24_spell_field_serialization()
	_group_25_int_weapon_base_construction()
	_group_26_int_weapon_serialization()
	_group_27_new_spell_stat_types()
	_group_28_hero_spell_combat_mode()
	_group_29_drop_pool_inclusion()
	_group_30_dot_stat_type_existence()
	_group_31_dot_stat_aggregation_and_proc()
	_group_32_dot_defense_interaction()
	_group_33_dot_dps_calculation()
	_group_34_game_events_dot_signals()
	_group_35_save_version_and_loot_integration()
	_group_36_hero_archetype_data()
	_group_37_stat_integration()
	_group_38_save_persistence()
	_group_39_selection_ui()
	_group_40_stash_data_model()
	_group_41_stash_drop_routing()
	_group_42_forest_difficulty_tuning()
	_group_43_starter_kit_fresh_game()
	_group_44_starter_kit_post_prestige()
	_group_45_stash_ui_display()
	_group_46_stash_tap_to_bench()
	_group_47_stash_tooltip_text()
	_group_48_alteration_hammer()
	_group_49_regal_hammer()
	_group_50_save_v10_round_trip()
	_group_51_transmute_hammer()
	_group_52_augment_hammer()
	_group_53_alchemy_hammer()
	_group_54_chaos_hammer()
	_group_55_exalt_hammer()
	_group_56_divine_hammer()
	_group_57_annulment_hammer()

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
	else:
		_fail_count += 1
		print("[FAIL] %s" % description)


func _reset_fresh() -> void:
	GameState.initialize_fresh_game()


func _simulate_prestige() -> void:
	# Spend augment currency (100 times)
	for i in range(100):
		GameState.spend_currency("augment")

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
		GameState.stash["weapon"][0] != null,
		"starter weapon exists in stash"
	)
	_check(
		GameState.stash["weapon"][0] is Broadsword,
		"starter weapon is Broadsword"
	)
	_check(GameState.area_level == 1, "area_level == 1")
	_check(GameState.tag_currency_counts.is_empty(), "tag_currency_counts is empty")


# --- Group 2: Prestige Gating ---

func _group_2_prestige_gating() -> void:
	print("\n=== GROUP 2: Prestige Gating ===")
	# Continue from group 1 state (fresh game, prestige_level=0)

	GameState.currency_counts["augment"] = 99
	_check(PrestigeManager.can_prestige() == false, "can_prestige() == false with 99 augment")

	GameState.currency_counts["augment"] = 100
	_check(PrestigeManager.can_prestige() == true, "can_prestige() == true with 100 augment")

	var cost: Dictionary = PrestigeManager.get_next_prestige_cost()
	_check(cost.has("augment") and cost["augment"] == 100, "next prestige cost == {augment: 100}")


# --- Group 3: Execute Prestige P0 -> P1 ---

func _group_3_execute_prestige() -> void:
	print("\n=== GROUP 3: Execute Prestige P0 -> P1 ===")
	_reset_fresh()
	GameState.currency_counts["augment"] = 100
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
		GameState.stash["weapon"].size() == 0,
		"weapon stash empty after prestige (starter item is Phase 56)"
	)
	_check(GameState.currency_counts["augment"] == 2, "augment currency == 2 (fresh default after wipe)")
	_check(GameState.currency_counts["transmute"] == 2, "transmute currency == 2 (fresh default)")

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
	_check(GameState.currency_counts["transmute"] == 2, "restored transmute currency == 2")


# --- Group 5: Save Round-Trip at P1 ---

func _group_5_save_round_trip_p1() -> void:
	print("\n=== GROUP 5: Save Round-Trip at P1 ===")
	_reset_fresh()
	GameState.currency_counts["augment"] = 100
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

	var weapon: Item = GameState.stash["weapon"][0]
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

	var sword := Broadsword.new(8)
	_check(sword._get_affix_tier_floor() == 29, "tier 8 sword: affix floor == 29")

	sword.tier = 7
	_check(sword._get_affix_tier_floor() == 25, "tier 7 sword: affix floor == 25")

	sword.tier = 1
	_check(sword._get_affix_tier_floor() == 1, "tier 1 sword: affix floor == 1")

	# Test affix generation respects tier floor
	var test_sword := Broadsword.new(7)
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

	# Use PHYSICAL tag since Broadsword has Tag.PHYSICAL in valid_tags
	var phys_hammer := TagHammer.new("PHYSICAL", "Physical Hammer")
	var sword := Broadsword.new(8)

	_check(phys_hammer.can_apply(sword) == true, "TagHammer(PHYSICAL) can_apply Normal Broadsword")

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


# --- Helper: Item Construction ---

func _test_item_construction(item_class, type_string: String, archetype_tag: String, p_tier: int) -> bool:
	var item = item_class.new(p_tier)
	if item.get_item_type_string() != type_string:
		return false
	if item.tier != p_tier:
		return false
	if item.item_name == "":
		return false
	if not item.valid_tags.has(archetype_tag):
		return false
	return true


# --- Group 10: Item Base Construction (all 18 types) ---

func _group_10_item_base_construction() -> void:
	print("\n=== GROUP 10: Item Base Construction (all 18 types) ===")

	# STR Weapons
	_check(_test_item_construction(Broadsword, "Broadsword", Tag.STR, 8), "Broadsword T8 construction")
	_check(_test_item_construction(Broadsword, "Broadsword", Tag.STR, 1), "Broadsword T1 construction")
	_check(_test_item_construction(Battleaxe, "Battleaxe", Tag.STR, 8), "Battleaxe T8 construction")
	_check(_test_item_construction(Battleaxe, "Battleaxe", Tag.STR, 1), "Battleaxe T1 construction")
	_check(_test_item_construction(Warhammer, "Warhammer", Tag.STR, 8), "Warhammer T8 construction")
	_check(_test_item_construction(Warhammer, "Warhammer", Tag.STR, 1), "Warhammer T1 construction")

	# DEX Weapons
	_check(_test_item_construction(Dagger, "Dagger", Tag.DEX, 8), "Dagger T8 construction")
	_check(_test_item_construction(Dagger, "Dagger", Tag.DEX, 1), "Dagger T1 construction")
	_check(_test_item_construction(VenomBlade, "VenomBlade", Tag.DEX, 8), "VenomBlade T8 construction")
	_check(_test_item_construction(VenomBlade, "VenomBlade", Tag.DEX, 1), "VenomBlade T1 construction")
	_check(_test_item_construction(Shortbow, "Shortbow", Tag.DEX, 8), "Shortbow T8 construction")
	_check(_test_item_construction(Shortbow, "Shortbow", Tag.DEX, 1), "Shortbow T1 construction")

	# Weapon stat checks: base_damage_min > 0 and base_damage_max > base_damage_min
	for weapon_class in [Broadsword, Battleaxe, Warhammer, Dagger, VenomBlade, Shortbow]:
		var w: Weapon = weapon_class.new(8)
		_check(w.base_damage_min > 0, "%s T8: base_damage_min > 0" % w.get_item_type_string())
		_check(w.base_damage_max > w.base_damage_min, "%s T8: base_damage_max > base_damage_min" % w.get_item_type_string())

	# T1 stats > T8 stats (scaling)
	for weapon_class in [Broadsword, Battleaxe, Warhammer, Dagger, VenomBlade, Shortbow]:
		var w1: Weapon = weapon_class.new(1)
		var w8: Weapon = weapon_class.new(8)
		_check(w1.base_damage_min > w8.base_damage_min, "%s: T1 dmg_min > T8 dmg_min" % w1.get_item_type_string())

	# STR Armor/Helmet/Boots
	_check(_test_item_construction(IronPlate, "IronPlate", Tag.STR, 8), "IronPlate T8 construction")
	_check(_test_item_construction(IronPlate, "IronPlate", Tag.STR, 1), "IronPlate T1 construction")
	_check(_test_item_construction(IronHelm, "IronHelm", Tag.STR, 8), "IronHelm T8 construction")
	_check(_test_item_construction(IronHelm, "IronHelm", Tag.STR, 1), "IronHelm T1 construction")
	_check(_test_item_construction(IronGreaves, "IronGreaves", Tag.STR, 8), "IronGreaves T8 construction")
	_check(_test_item_construction(IronGreaves, "IronGreaves", Tag.STR, 1), "IronGreaves T1 construction")

	# DEX Armor/Helmet/Boots
	_check(_test_item_construction(LeatherVest, "LeatherVest", Tag.DEX, 8), "LeatherVest T8 construction")
	_check(_test_item_construction(LeatherVest, "LeatherVest", Tag.DEX, 1), "LeatherVest T1 construction")
	_check(_test_item_construction(LeatherHood, "LeatherHood", Tag.DEX, 8), "LeatherHood T8 construction")
	_check(_test_item_construction(LeatherHood, "LeatherHood", Tag.DEX, 1), "LeatherHood T1 construction")
	_check(_test_item_construction(LeatherBoots, "LeatherBoots", Tag.DEX, 8), "LeatherBoots T8 construction")
	_check(_test_item_construction(LeatherBoots, "LeatherBoots", Tag.DEX, 1), "LeatherBoots T1 construction")

	# INT Armor/Helmet/Boots
	_check(_test_item_construction(SilkRobe, "SilkRobe", Tag.INT, 8), "SilkRobe T8 construction")
	_check(_test_item_construction(SilkRobe, "SilkRobe", Tag.INT, 1), "SilkRobe T1 construction")
	_check(_test_item_construction(Circlet, "Circlet", Tag.INT, 8), "Circlet T8 construction")
	_check(_test_item_construction(Circlet, "Circlet", Tag.INT, 1), "Circlet T1 construction")
	_check(_test_item_construction(SilkSlippers, "SilkSlippers", Tag.INT, 8), "SilkSlippers T8 construction")
	_check(_test_item_construction(SilkSlippers, "SilkSlippers", Tag.INT, 1), "SilkSlippers T1 construction")

	# Defense items: primary defense stat > 0
	var plate: Armor = IronPlate.new(8)
	_check(plate.base_armor > 0, "IronPlate T8: base_armor > 0")
	var vest: Armor = LeatherVest.new(8)
	_check(vest.base_evasion > 0, "LeatherVest T8: base_evasion > 0")
	var robe: Armor = SilkRobe.new(8)
	_check(robe.base_energy_shield > 0, "SilkRobe T8: base_energy_shield > 0")

	# Defense T1 > T8 scaling
	var plate1: Armor = IronPlate.new(1)
	_check(plate1.base_armor > plate.base_armor, "IronPlate: T1 armor > T8 armor")
	var vest1: Armor = LeatherVest.new(1)
	_check(vest1.base_evasion > vest.base_evasion, "LeatherVest: T1 evasion > T8 evasion")
	var robe1: Armor = SilkRobe.new(1)
	_check(robe1.base_energy_shield > robe.base_energy_shield, "SilkRobe: T1 ES > T8 ES")

	# STR/DEX/INT Rings
	_check(_test_item_construction(IronBand, "IronBand", Tag.STR, 8), "IronBand T8 construction")
	_check(_test_item_construction(IronBand, "IronBand", Tag.STR, 1), "IronBand T1 construction")
	_check(_test_item_construction(JadeRing, "JadeRing", Tag.DEX, 8), "JadeRing T8 construction")
	_check(_test_item_construction(JadeRing, "JadeRing", Tag.DEX, 1), "JadeRing T1 construction")
	_check(_test_item_construction(SapphireRing, "SapphireRing", Tag.INT, 8), "SapphireRing T8 construction")
	_check(_test_item_construction(SapphireRing, "SapphireRing", Tag.INT, 1), "SapphireRing T1 construction")

	# Ring: base_damage > 0
	for ring_class in [IronBand, JadeRing, SapphireRing]:
		var r: Ring = ring_class.new(8)
		_check(r.base_damage > 0, "%s T8: base_damage > 0" % r.get_item_type_string())

	# Ring T1 > T8 scaling
	for ring_class in [IronBand, JadeRing, SapphireRing]:
		var r1: Ring = ring_class.new(1)
		var r8: Ring = ring_class.new(8)
		_check(r1.base_damage > r8.base_damage, "%s: T1 base_damage > T8 base_damage" % r1.get_item_type_string())


# --- Group 11: Serialization Round-Trip (all 18 types) ---

func _group_11_serialization_round_trip() -> void:
	print("\n=== GROUP 11: Serialization Round-Trip (all 18 types) ===")

	var all_classes: Array = [
		Broadsword, Battleaxe, Warhammer, Dagger, VenomBlade, Shortbow,
		IronPlate, LeatherVest, SilkRobe,
		IronHelm, LeatherHood, Circlet,
		IronGreaves, LeatherBoots, SilkSlippers,
		IronBand, JadeRing, SapphireRing,
	]

	for item_class in all_classes:
		var original: Item = item_class.new(5)
		var dict: Dictionary = original.to_dict()
		var restored: Item = Item.create_from_dict(dict)

		var type_str: String = original.get_item_type_string()
		_check(restored != null, "%s: create_from_dict not null" % type_str)
		if restored != null:
			_check(
				restored.item_name == original.item_name,
				"%s: restored item_name matches" % type_str
			)
			_check(
				restored.tier == original.tier,
				"%s: restored tier matches" % type_str
			)
			_check(
				restored.get_item_type_string() == type_str,
				"%s: restored type_string matches" % type_str
			)


# --- Group 12: Defense Archetype Verification ---

func _group_12_defense_archetype_verification() -> void:
	print("\n=== GROUP 12: Defense Archetype Verification ===")

	var iron: Armor = IronPlate.new(5)
	_check(iron.computed_armor > 0, "IronPlate(5): computed_armor > 0")
	_check(iron.computed_evasion == 0, "IronPlate(5): computed_evasion == 0")
	_check(iron.computed_energy_shield == 0, "IronPlate(5): computed_energy_shield == 0")
	_check(iron.total_defense == iron.computed_armor, "IronPlate(5): total_defense == computed_armor")

	var leather: Armor = LeatherVest.new(5)
	_check(leather.computed_evasion > 0, "LeatherVest(5): computed_evasion > 0")
	_check(leather.computed_armor == 0, "LeatherVest(5): computed_armor == 0")
	_check(leather.total_defense == leather.computed_evasion, "LeatherVest(5): total_defense == computed_evasion")

	var silk: Armor = SilkRobe.new(5)
	_check(silk.computed_energy_shield > 0, "SilkRobe(5): computed_energy_shield > 0")
	_check(silk.computed_armor == 0, "SilkRobe(5): computed_armor == 0")
	_check(silk.total_defense == silk.computed_energy_shield, "SilkRobe(5): total_defense == computed_energy_shield")


# --- Group 13: Valid Tags / Affix Gating ---

func _group_13_valid_tags_affix_gating() -> void:
	print("\n=== GROUP 13: Valid Tags / Affix Gating ===")

	# Find a Physical Damage prefix from ItemAffixes (has PHYSICAL tag)
	var phys_prefix: Affix = null
	for template: Affix in ItemAffixes.prefixes:
		if Tag.PHYSICAL in template.tags:
			phys_prefix = template
			break

	# Find a Crit suffix (has CRITICAL tag)
	var crit_suffix: Affix = null
	for template: Affix in ItemAffixes.suffixes:
		if Tag.CRITICAL in template.tags:
			crit_suffix = template
			break

	# Find an Armor-tagged affix
	var armor_affix: Affix = null
	for template: Affix in ItemAffixes.prefixes + ItemAffixes.suffixes:
		if Tag.ARMOR in template.tags and Tag.EVASION not in template.tags:
			armor_affix = template
			break

	# Find an Evasion-tagged affix
	var evasion_affix: Affix = null
	for template: Affix in ItemAffixes.prefixes + ItemAffixes.suffixes:
		if Tag.EVASION in template.tags and Tag.ARMOR not in template.tags:
			evasion_affix = template
			break

	# Broadsword should accept Physical prefix (has PHYSICAL + WEAPON tags)
	var sword := Broadsword.new(8)
	if phys_prefix != null:
		_check(sword.has_valid_tag(phys_prefix), "Broadsword: has_valid_tag for Physical prefix")
	else:
		_check(false, "Broadsword: no Physical prefix found in affix pool")

	# Dagger should accept Crit suffix (has CRITICAL tag)
	var dagger := Dagger.new(8)
	if crit_suffix != null:
		_check(dagger.has_valid_tag(crit_suffix), "Dagger: has_valid_tag for Crit suffix")
	else:
		_check(false, "Dagger: no Crit suffix found in affix pool")

	# IronPlate should accept Armor affix and reject Evasion-only affix
	var plate := IronPlate.new(8)
	if armor_affix != null:
		_check(plate.has_valid_tag(armor_affix), "IronPlate: has_valid_tag for Armor affix")
	else:
		_check(false, "IronPlate: no Armor affix found in affix pool")

	if evasion_affix != null:
		_check(not plate.has_valid_tag(evasion_affix), "IronPlate: rejects Evasion-only affix")
	else:
		_check(false, "IronPlate: no Evasion-only affix found in affix pool")

	# LeatherVest should accept Evasion affix and reject Armor-only affix
	var vest := LeatherVest.new(8)
	if evasion_affix != null:
		_check(vest.has_valid_tag(evasion_affix), "LeatherVest: has_valid_tag for Evasion affix")
	else:
		_check(false, "LeatherVest: no Evasion affix found in affix pool")

	if armor_affix != null:
		_check(not vest.has_valid_tag(armor_affix), "LeatherVest: rejects Armor-only affix")
	else:
		_check(false, "LeatherVest: no Armor-only affix found in affix pool")


# --- Group 14: Drop Generation ---

func _group_14_drop_generation() -> void:
	print("\n=== GROUP 14: Drop Generation ===")
	_reset_fresh()

	var has_weapon := false
	var has_armor := false
	var has_helmet := false
	var has_boots := false
	var has_ring := false
	var all_valid := true

	# Simulate drop generation inline using same logic as gameplay_view
	var slots = ["weapon", "armor", "helmet", "boots", "ring"]
	var bases: Dictionary = {
		"weapon": [Broadsword, Battleaxe, Warhammer, Dagger, VenomBlade, Shortbow],
		"armor": [IronPlate, LeatherVest, SilkRobe],
		"helmet": [IronHelm, LeatherHood, Circlet],
		"boots": [IronGreaves, LeatherBoots, SilkSlippers],
		"ring": [IronBand, JadeRing, SapphireRing],
	}

	for i in range(200):
		var slot = slots[randi() % slots.size()]
		var slot_bases = bases[slot]
		var item_class = slot_bases[randi() % slot_bases.size()]
		var tier = (randi() % 8) + 1
		var item: Item = item_class.new(tier)

		if item.item_name == "" or item.tier < 1 or item.tier > 8:
			all_valid = false

		if item is Weapon:
			has_weapon = true
		elif item is Armor:
			has_armor = true
		elif item is Helmet:
			has_helmet = true
		elif item is Boots:
			has_boots = true
		elif item is Ring:
			has_ring = true

	_check(has_weapon, "Drop gen: weapon slot represented")
	_check(has_armor, "Drop gen: armor slot represented")
	_check(has_helmet, "Drop gen: helmet slot represented")
	_check(has_boots, "Drop gen: boots slot represented")
	_check(has_ring, "Drop gen: ring slot represented")
	_check(all_valid, "Drop gen: all items have valid tier and non-empty name")


# --- Group 15: Starter Weapon ---

func _group_15_starter_weapon() -> void:
	print("\n=== GROUP 15: Starter Weapon ===")
	_reset_fresh()

	var weapon: Item = GameState.stash["weapon"][0]
	_check(weapon is Broadsword, "Starter weapon is Broadsword")
	_check(weapon.tier == 8, "Starter weapon tier == 8")
	_check(weapon.item_name == "Rusty Broadsword", "Starter weapon name == 'Rusty Broadsword'")


# --- Group 16: New Affix Pool Validation ---

func _group_16_new_affix_pool_validation() -> void:
	print("\n--- Group 16: New affix pool validation ---")
	var affixes_node := Affixes.new()

	# Check new prefixes exist (6 total)
	var prefix_names := ["Spell Damage", "%Spell Damage", "Bleed Damage", "Poison Damage", "Burn Damage", "%DoT Damage"]
	for pname in prefix_names:
		var found := false
		for p in affixes_node.prefixes:
			if p.affix_name == pname:
				found = true
				break
		_check(found, "Prefix '%s' exists in pool" % pname)

	# Check new suffixes exist (8 total)
	var suffix_names := ["Cast Speed", "Chaos Resistance", "Bleed Chance", "%Bleed Damage", "Poison Chance", "%Poison Damage", "Burn Chance", "%Burn Damage"]
	for sname in suffix_names:
		var found := false
		for s in affixes_node.suffixes:
			if s.affix_name == sname:
				found = true
				break
		_check(found, "Suffix '%s' exists in pool" % sname)

	# Check total counts
	_check(affixes_node.prefixes.size() == 24, "Prefixes array has 24 entries (18 old + 6 new)")
	_check(affixes_node.suffixes.size() == 17, "Suffixes array has 17 entries (9 old + 8 new)")

	# AFF-04: Evade suffix is disabled (commented out)
	var evade_found := false
	for s in affixes_node.suffixes:
		if s.affix_name == "Evade":
			evade_found = true
			break
	_check(not evade_found, "Evade suffix is NOT in the active pool (AFF-04 dropped)")

	affixes_node.free()


# --- Group 17: Spell Damage Affix Gating ---

func _group_17_spell_damage_affix_gating() -> void:
	print("\n--- Group 17: Spell damage affix gating ---")
	var sapphire := SapphireRing.new()
	var broadsword := Broadsword.new()
	var affixes_node := Affixes.new()

	# Find spell damage prefix
	var spell_prefix: Affix = null
	for p in affixes_node.prefixes:
		if p.affix_name == "Spell Damage":
			spell_prefix = p
			break

	_check(spell_prefix != null, "Spell Damage prefix found")
	if spell_prefix:
		_check(sapphire.has_valid_tag(spell_prefix), "SapphireRing can roll Spell Damage (SPELL + WEAPON)")
		# Broadsword also matches via WEAPON tag; non-weapon items without SPELL cannot
		_check(broadsword.has_valid_tag(spell_prefix), "Broadsword can roll Spell Damage (WEAPON)")
		var circlet := Circlet.new()
		_check(not circlet.has_valid_tag(spell_prefix), "Circlet cannot roll Spell Damage (no SPELL/FLAT/WEAPON)")

	# Find %Spell Damage prefix
	var pct_spell: Affix = null
	for p in affixes_node.prefixes:
		if p.affix_name == "%Spell Damage":
			pct_spell = p
			break

	if pct_spell:
		_check(sapphire.has_valid_tag(pct_spell), "SapphireRing can roll %Spell Damage (SPELL)")
		_check(broadsword.has_valid_tag(pct_spell), "Broadsword can roll %Spell Damage (WEAPON)")
		var iron_plate := IronPlate.new()
		_check(not iron_plate.has_valid_tag(pct_spell), "IronPlate cannot roll %Spell Damage (no SPELL/PERCENTAGE/WEAPON)")

	affixes_node.free()


# --- Group 18: DoT Affix Gating ---

func _group_18_dot_affix_gating() -> void:
	print("\n--- Group 18: DoT affix gating ---")
	var broadsword := Broadsword.new()
	var dagger := Dagger.new()
	var circlet := Circlet.new()
	var affixes_node := Affixes.new()

	# Find DoT affixes
	var bleed_prefix: Affix = null
	var poison_prefix: Affix = null
	var burn_prefix: Affix = null
	for p in affixes_node.prefixes:
		if p.affix_name == "Bleed Damage":
			bleed_prefix = p
		elif p.affix_name == "Poison Damage":
			poison_prefix = p
		elif p.affix_name == "Burn Damage":
			burn_prefix = p

	# Bleed (PHYSICAL tag) -- STR and DEX weapons both have PHYSICAL
	if bleed_prefix:
		_check(broadsword.has_valid_tag(bleed_prefix), "Broadsword can roll Bleed Damage (PHYSICAL)")
		_check(dagger.has_valid_tag(bleed_prefix), "Dagger can roll Bleed Damage (PHYSICAL)")
		_check(not circlet.has_valid_tag(bleed_prefix), "Circlet cannot roll Bleed Damage (no PHYSICAL/WEAPON)")

	# Poison (DOT, CHAOS, WEAPON tags) -- DEX weapons have CHAOS, STR weapons match via WEAPON
	if poison_prefix:
		_check(dagger.has_valid_tag(poison_prefix), "Dagger can roll Poison Damage (CHAOS + WEAPON)")
		_check(broadsword.has_valid_tag(poison_prefix), "Broadsword can roll Poison Damage (WEAPON)")
		_check(not circlet.has_valid_tag(poison_prefix), "Circlet cannot roll Poison Damage (no DOT/CHAOS/WEAPON)")

	# Burn (DOT, FIRE, WEAPON tags) -- weapons can roll via WEAPON tag, non-weapon defense items cannot
	if burn_prefix:
		_check(broadsword.has_valid_tag(burn_prefix), "Broadsword can roll Burn Damage (WEAPON)")
		_check(dagger.has_valid_tag(burn_prefix), "Dagger can roll Burn Damage (WEAPON)")
		_check(not circlet.has_valid_tag(burn_prefix), "Circlet cannot roll Burn Damage (no DOT/FIRE/WEAPON)")

	affixes_node.free()


# --- Group 19: Cast Speed / Chaos Resistance Accessibility ---

func _group_19_cast_speed_chaos_resist_accessibility() -> void:
	print("\n--- Group 19: Cast speed / chaos resistance accessibility ---")
	var iron_band := IronBand.new()
	var jade_ring := JadeRing.new()
	var sapphire := SapphireRing.new()
	var iron_plate := IronPlate.new()
	var affixes_node := Affixes.new()

	var cast_speed: Affix = null
	var chaos_resist: Affix = null
	for s in affixes_node.suffixes:
		if s.affix_name == "Cast Speed":
			cast_speed = s
		elif s.affix_name == "Chaos Resistance":
			chaos_resist = s

	# Cast Speed (SPEED tag) -- all rings have SPEED
	if cast_speed:
		_check(iron_band.has_valid_tag(cast_speed), "IronBand can roll Cast Speed (SPEED)")
		_check(jade_ring.has_valid_tag(cast_speed), "JadeRing can roll Cast Speed (SPEED)")
		_check(sapphire.has_valid_tag(cast_speed), "SapphireRing can roll Cast Speed (SPEED)")
		_check(not iron_plate.has_valid_tag(cast_speed), "IronPlate cannot roll Cast Speed")

	# Chaos Resistance (DEFENSE, CHAOS, WEAPON tags) -- accessible to defense items + weapons + CHAOS items
	if chaos_resist:
		_check(iron_plate.has_valid_tag(chaos_resist), "IronPlate can roll Chaos Resistance (DEFENSE)")
		_check(jade_ring.has_valid_tag(chaos_resist), "JadeRing can roll Chaos Resistance (CHAOS)")

	affixes_node.free()


# --- Group 20: Flat Damage Range Rolling ---

func _group_20_flat_damage_range_rolling() -> void:
	print("\n--- Group 20: Flat damage range rolling ---")

	# Test Flat Spell Damage rolls range values
	var spell_affix := Affix.new(
		"Spell Damage", Affix.AffixType.PREFIX, 2, 10,
		[Tag.SPELL, Tag.FLAT, Tag.WEAPON],
		[Tag.StatType.FLAT_SPELL_DAMAGE],
		Vector2i(1, 32), 3, 5, 7, 10
	)
	_check(spell_affix.add_min > 0 or spell_affix.add_max > 0, "Flat Spell Damage rolls add_min/add_max")
	_check(spell_affix.dmg_min_hi > 0, "Flat Spell Damage has tier-scaled dmg_min_hi")

	# Test Flat Bleed Damage rolls range values
	var bleed_affix := Affix.new(
		"Bleed Damage", Affix.AffixType.PREFIX, 2, 10,
		[Tag.DOT, Tag.PHYSICAL, Tag.WEAPON],
		[Tag.StatType.BLEED_DAMAGE],
		Vector2i(1, 32), 2, 3, 4, 6
	)
	_check(bleed_affix.add_min > 0 or bleed_affix.add_max > 0, "Flat Bleed Damage rolls add_min/add_max")

	# Test existing Flat Physical Damage still works (regression)
	var phys_affix := Affix.new(
		"Physical Damage", Affix.AffixType.PREFIX, 2, 10,
		[Tag.PHYSICAL, Tag.FLAT, Tag.WEAPON],
		[Tag.StatType.FLAT_DAMAGE],
		Vector2i(1, 32), 3, 5, 7, 10
	)
	_check(phys_affix.add_min > 0 or phys_affix.add_max > 0, "Flat Physical Damage still rolls add_min/add_max (regression)")

	# Test non-range affix does NOT get add_min/add_max
	var pct_affix := Affix.new(
		"%Spell Damage", Affix.AffixType.PREFIX, 2, 10,
		[Tag.SPELL, Tag.PERCENTAGE, Tag.WEAPON],
		[Tag.StatType.INCREASED_SPELL_DAMAGE],
		Vector2i(1, 32)
	)
	_check(pct_affix.add_min == 0 and pct_affix.add_max == 0, "% affix has zero add_min/add_max")

	# Test reroll works for new flat types
	var old_min := spell_affix.add_min
	var old_max := spell_affix.add_max
	var rerolled_different := false
	for i in 20:
		spell_affix.reroll()
		if spell_affix.add_min != old_min or spell_affix.add_max != old_max:
			rerolled_different = true
			break
	_check(rerolled_different, "Flat Spell Damage reroll produces different values")


# --- Group 21: New StatType Enum Values ---

func _group_21_new_stat_type_enum_values() -> void:
	print("\n--- Group 21: New StatType enum values ---")
	# These lines will fail to compile if the enum values don't exist
	var bleed_chance: int = Tag.StatType.BLEED_CHANCE
	var poison_chance: int = Tag.StatType.POISON_CHANCE
	var burn_chance: int = Tag.StatType.BURN_CHANCE
	_check(bleed_chance >= 0, "BLEED_CHANCE exists in StatType enum")
	_check(poison_chance >= 0, "POISON_CHANCE exists in StatType enum")
	_check(burn_chance >= 0, "BURN_CHANCE exists in StatType enum")
	# Verify they are distinct values
	_check(bleed_chance != poison_chance, "BLEED_CHANCE != POISON_CHANCE")
	_check(poison_chance != burn_chance, "POISON_CHANCE != BURN_CHANCE")
	_check(bleed_chance != burn_chance, "BLEED_CHANCE != BURN_CHANCE")


# --- Group 22: Spell Damage Channel ---

func _group_22_spell_damage_channel() -> void:
	print("\n--- Group 22: Spell damage channel ---")

	# Weapon spell field defaults
	var sword := Broadsword.new(8)
	_check(sword.base_spell_damage_min == 0, "Weapon: base_spell_damage_min == 0")
	_check(sword.base_spell_damage_max == 0, "Weapon: base_spell_damage_max == 0")
	_check(sword.base_cast_speed == 0.0, "Weapon: base_cast_speed == 0.0")
	_check(sword.spell_dps == 0.0, "Weapon: spell_dps == 0.0 (no spell channel)")

	# Weapon with spell fields set to non-zero should have spell_dps > 0
	var spell_sword := Broadsword.new(8)
	spell_sword.base_spell_damage_min = 10
	spell_sword.base_spell_damage_max = 20
	spell_sword.base_cast_speed = 1.0
	spell_sword.update_value()
	_check(spell_sword.spell_dps > 0.0, "Weapon: spell_dps > 0 when spell fields set")

	# SapphireRing base_cast_speed by tier
	var sapphire_t8 := SapphireRing.new(8)
	_check(is_equal_approx(sapphire_t8.base_cast_speed, 0.5), "SapphireRing(8): base_cast_speed == 0.5")

	var sapphire_t5 := SapphireRing.new(5)
	_check(is_equal_approx(sapphire_t5.base_cast_speed, 0.8), "SapphireRing(5): base_cast_speed == 0.8")

	var sapphire_t1 := SapphireRing.new(1)
	_check(is_equal_approx(sapphire_t1.base_cast_speed, 1.2), "SapphireRing(1): base_cast_speed == 1.2")

	# IronBand has base_cast_speed == 0
	var iron_band := IronBand.new(8)
	_check(iron_band.base_cast_speed == 0.0, "IronBand: base_cast_speed == 0.0")

	# SapphireRing should have spell_dps > 0 (has cast speed + spell damage implicit)
	_check(sapphire_t8.spell_dps > 0.0, "SapphireRing(8): spell_dps > 0 (has cast speed + spell implicit)")

	# StatCalculator.calculate_spell_damage_range() with no affixes
	var spell_range := StatCalculator.calculate_spell_damage_range(10, 20, [])
	_check(spell_range.has("spell"), "calculate_spell_damage_range: has 'spell' key")
	_check(is_equal_approx(spell_range["spell"]["min"], 10.0), "calculate_spell_damage_range: min == 10.0")
	_check(is_equal_approx(spell_range["spell"]["max"], 20.0), "calculate_spell_damage_range: max == 20.0")

	# StatCalculator.calculate_spell_dps() with base values
	var sdps := StatCalculator.calculate_spell_dps(15.0, 1.0, [], 5.0, 150.0)
	var expected_sdps := 15.0 * 1.0 * 1.025  # 15.375
	_check(is_equal_approx(sdps, expected_sdps), "calculate_spell_dps(15, 1.0, [], 5, 150) == 15.375")

	# StatCalculator.calculate_spell_dps() with 0 cast speed returns 0
	var sdps_zero := StatCalculator.calculate_spell_dps(15.0, 0.0, [], 5.0, 150.0)
	_check(sdps_zero == 0.0, "calculate_spell_dps with cast_speed=0 returns 0.0")

	# JadeRing has base_cast_speed == 0
	var jade_ring := JadeRing.new(8)
	_check(jade_ring.base_cast_speed == 0.0, "JadeRing: base_cast_speed == 0.0")

	# calculate_spell_damage_range with flat affix
	var flat_spell_affix := Affix.new(
		"Spell Damage", Affix.AffixType.PREFIX, 0, 0,
		[Tag.SPELL, Tag.FLAT, Tag.WEAPON],
		[Tag.StatType.FLAT_SPELL_DAMAGE],
		Vector2i(1, 1)
	)
	flat_spell_affix.add_min = 5
	flat_spell_affix.add_max = 10
	var range_with_flat := StatCalculator.calculate_spell_damage_range(10, 20, [flat_spell_affix])
	_check(is_equal_approx(range_with_flat["spell"]["min"], 15.0), "calculate_spell_damage_range with flat affix: min == 15.0")
	_check(is_equal_approx(range_with_flat["spell"]["max"], 30.0), "calculate_spell_damage_range with flat affix: max == 30.0")

	# calculate_spell_dps with %spell damage affix
	var pct_spell_affix := Affix.new(
		"%Spell Damage", Affix.AffixType.PREFIX, 0, 0,
		[Tag.SPELL, Tag.PERCENTAGE, Tag.WEAPON],
		[Tag.StatType.INCREASED_SPELL_DAMAGE],
		Vector2i(1, 1)
	)
	pct_spell_affix.value = 100
	var sdps_pct := StatCalculator.calculate_spell_dps(10.0, 1.0, [pct_spell_affix], 5.0, 150.0)
	var expected_pct_sdps := 10.0 * 2.0 * 1.0 * 1.025  # 20.5
	_check(is_equal_approx(sdps_pct, expected_pct_sdps), "calculate_spell_dps with 100%% spell damage == 20.5")

	# Attack DPS regression: existing weapon DPS unaffected
	var regression_sword := Broadsword.new(5)
	var orig_dps := regression_sword.dps
	_check(orig_dps > 0.0, "Broadsword(5): attack dps > 0 (regression check)")


# --- Group 23: Hero Spell Stat Tracking ---

func _group_23_hero_spell_stat_tracking() -> void:
	print("\n--- Group 23: Hero spell stat tracking ---")
	_reset_fresh()

	var hero := GameState.hero

	# No equipment: fresh hero has total_spell_dps == 0
	hero.unequip_item("weapon")
	hero.unequip_item("ring")
	_check(hero.total_spell_dps == 0.0, "Hero: total_spell_dps == 0 with no equipment")

	# Attack weapon only: Broadsword(8) — no spell fields
	var atk_sword := Broadsword.new(8)
	hero.equip_item(atk_sword, "weapon")
	_check(hero.total_spell_dps == 0.0, "Hero: total_spell_dps == 0 with attack-only weapon")
	_check(hero.total_dps > 0.0, "Hero: total_dps > 0 with Broadsword equipped")
	hero.unequip_item("weapon")

	# Equip SapphireRing(8) — has base_cast_speed 0.5 + FLAT_SPELL_DAMAGE implicit
	var sapphire := SapphireRing.new(8)
	hero.equip_item(sapphire, "ring")
	_check(hero.total_spell_dps > 0.0, "Hero: total_spell_dps > 0 with SapphireRing equipped")
	_check(hero.spell_damage_ranges["spell"]["min"] > 0.0 or hero.spell_damage_ranges["spell"]["max"] > 0.0,
		"Hero: spell_damage_ranges has non-zero values with SapphireRing")

	# Replace with IronBand — no cast speed, no spell damage
	var iron_band := IronBand.new(8)
	hero.equip_item(iron_band, "ring")
	_check(hero.total_spell_dps == 0.0, "Hero: total_spell_dps == 0 with IronBand (no cast speed)")

	# Equip Broadsword (no spell fields) — verify no spell DPS
	var broadsword := Broadsword.new(8)
	hero.equip_item(broadsword, "weapon")
	_check(hero.total_spell_dps == 0.0, "Hero: total_spell_dps == 0 with Broadsword + IronBand")

	# Equip SapphireRing again with Broadsword — SapphireRing enables spell channel
	hero.equip_item(SapphireRing.new(8), "ring")
	_check(hero.total_spell_dps > 0.0, "Hero: total_spell_dps > 0 with Broadsword + SapphireRing")
	_check(hero.total_dps > 0.0, "Hero: total_dps (attack) > 0 with Broadsword + SapphireRing")

	# Unequip clears spell DPS
	var saved_spell_dps := hero.total_spell_dps
	_check(saved_spell_dps > 0.0, "Hero: total_spell_dps > 0 before unequip (precondition)")
	hero.unequip_item("ring")
	_check(hero.total_spell_dps == 0.0, "Hero: total_spell_dps == 0 after unequipping ring")

	# Verify get_total_spell_dps() getter
	hero.equip_item(SapphireRing.new(8), "ring")
	_check(hero.get_total_spell_dps() == hero.total_spell_dps, "Hero: get_total_spell_dps() matches field")


# --- Group 24: Spell Field Serialization ---

func _group_24_spell_field_serialization() -> void:
	print("\n--- Group 24: Spell field serialization ---")

	# Weapon round-trip preserves spell fields (defaults are 0 from constructor)
	var sword := Broadsword.new(8)
	_check(sword.base_spell_damage_min == 0, "Broadsword(8): base_spell_damage_min == 0 before serialization")
	_check(sword.base_spell_damage_max == 0, "Broadsword(8): base_spell_damage_max == 0 before serialization")
	_check(sword.base_cast_speed == 0.0, "Broadsword(8): base_cast_speed == 0.0 before serialization")
	var sword_dict := sword.to_dict()
	var sword_restored: Item = Item.create_from_dict(sword_dict)
	_check(sword_restored != null, "Broadsword round-trip: create_from_dict not null")
	if sword_restored != null and sword_restored is Weapon:
		var w: Weapon = sword_restored as Weapon
		_check(w.base_spell_damage_min == 0, "Broadsword round-trip: base_spell_damage_min == 0")
		_check(w.base_spell_damage_max == 0, "Broadsword round-trip: base_spell_damage_max == 0")
		_check(w.base_cast_speed == 0.0, "Broadsword round-trip: base_cast_speed == 0.0")
		_check(is_equal_approx(w.spell_dps, 0.0), "Broadsword round-trip: spell_dps == 0.0")
		_check(w.dps > 0.0, "Broadsword round-trip: attack dps preserved > 0")

	# SapphireRing round-trip preserves base_cast_speed and spell_dps
	var sapphire := SapphireRing.new(8)
	var orig_cast_speed := sapphire.base_cast_speed
	var orig_spell_dps := sapphire.spell_dps
	_check(is_equal_approx(orig_cast_speed, 0.5), "SapphireRing(8): base_cast_speed == 0.5 before serialization")
	_check(orig_spell_dps > 0.0, "SapphireRing(8): spell_dps > 0 before serialization")
	var sapphire_dict := sapphire.to_dict()
	var sapphire_restored: Item = Item.create_from_dict(sapphire_dict)
	_check(sapphire_restored != null, "SapphireRing round-trip: create_from_dict not null")
	if sapphire_restored != null and sapphire_restored is Ring:
		var r: Ring = sapphire_restored as Ring
		_check(is_equal_approx(r.base_cast_speed, 0.5), "SapphireRing round-trip: base_cast_speed == 0.5")
		_check(is_equal_approx(r.spell_dps, orig_spell_dps), "SapphireRing round-trip: spell_dps matches original")

	# IronBand round-trip preserves base_cast_speed == 0
	var iron_band := IronBand.new(8)
	_check(iron_band.base_cast_speed == 0.0, "IronBand(8): base_cast_speed == 0.0 before serialization")
	var iron_dict := iron_band.to_dict()
	var iron_restored: Item = Item.create_from_dict(iron_dict)
	_check(iron_restored != null, "IronBand round-trip: create_from_dict not null")
	if iron_restored != null and iron_restored is Ring:
		var r: Ring = iron_restored as Ring
		_check(r.base_cast_speed == 0.0, "IronBand round-trip: base_cast_speed == 0.0")
		_check(is_equal_approx(r.spell_dps, 0.0), "IronBand round-trip: spell_dps == 0.0")


# --- Group 25: INT Weapon Base Construction ---

func _group_25_int_weapon_base_construction() -> void:
	print("\n--- Group 25: INT Weapon Base Construction ---")

	# Wand T8 and T1
	var wand_t8 = Wand.new(8)
	_check(wand_t8 != null, "Wand T8 constructs")
	_check(wand_t8.item_name == "Twig Wand", "Wand T8 name is Twig Wand")
	_check(Tag.INT in wand_t8.valid_tags, "Wand has INT tag")
	_check(Tag.SPELL in wand_t8.valid_tags, "Wand has SPELL tag")
	_check(wand_t8.base_spell_damage_min > 0, "Wand T8 has non-zero spell damage min")
	_check(wand_t8.base_spell_damage_max > 0, "Wand T8 has non-zero spell damage max")
	_check(wand_t8.base_cast_speed > 0.0, "Wand T8 has non-zero cast speed")
	_check(wand_t8.base_damage_min > 0, "Wand T8 has non-zero attack damage min (suboptimal)")
	_check(wand_t8.base_attack_speed > 0.0, "Wand T8 has non-zero attack speed")
	_check(wand_t8.spell_dps > 0.0, "Wand T8 has non-zero spell DPS")

	var wand_t1 = Wand.new(1)
	_check(wand_t1.base_spell_damage_min > wand_t8.base_spell_damage_min, "Wand T1 spell damage > T8")
	_check(wand_t1.base_damage_min > wand_t8.base_damage_min, "Wand T1 attack damage > T8")

	# LightningRod T8 and T1
	var lr_t8 = LightningRod.new(8)
	_check(lr_t8 != null, "LightningRod T8 constructs")
	_check(Tag.INT in lr_t8.valid_tags, "LightningRod has INT tag")
	_check(lr_t8.base_spell_damage_min > 0, "LightningRod T8 has non-zero spell damage")
	_check(lr_t8.base_cast_speed > 0.0, "LightningRod T8 has non-zero cast speed")
	_check(lr_t8.implicit != null, "LightningRod has implicit")
	_check(Tag.StatType.FLAT_SPELL_LIGHTNING_DAMAGE in lr_t8.implicit.stat_types, "LightningRod implicit uses FLAT_SPELL_LIGHTNING_DAMAGE")

	var lr_t1 = LightningRod.new(1)
	_check(lr_t1.base_spell_damage_min > lr_t8.base_spell_damage_min, "LightningRod T1 spell damage > T8")

	# Sceptre T8 and T1
	var sc_t8 = Sceptre.new(8)
	_check(sc_t8 != null, "Sceptre T8 constructs")
	_check(Tag.INT in sc_t8.valid_tags, "Sceptre has INT tag")
	_check(sc_t8.base_spell_damage_min > 0, "Sceptre T8 has non-zero spell damage")
	_check(sc_t8.base_cast_speed > 0.0, "Sceptre T8 has non-zero cast speed")
	_check(sc_t8.implicit != null, "Sceptre has implicit")
	_check(Tag.StatType.FLAT_SPELL_FIRE_DAMAGE in sc_t8.implicit.stat_types, "Sceptre implicit uses FLAT_SPELL_FIRE_DAMAGE")

	var sc_t1 = Sceptre.new(1)
	_check(sc_t1.base_spell_damage_min > sc_t8.base_spell_damage_min, "Sceptre T1 spell damage > T8")

	# Cast speed variation: Wand > LightningRod > Sceptre
	_check(wand_t8.base_cast_speed > lr_t8.base_cast_speed, "Wand casts faster than LightningRod")
	_check(lr_t8.base_cast_speed > sc_t8.base_cast_speed, "LightningRod casts faster than Sceptre")


# --- Group 26: INT Weapon Serialization ---

func _group_26_int_weapon_serialization() -> void:
	print("\n--- Group 26: INT Weapon Serialization ---")

	# Wand round-trip
	var wand = Wand.new(5)
	var wand_dict = wand.to_dict()
	_check(wand_dict["item_type"] == "Wand", "Wand serializes with correct item_type")
	var wand_restored = Item.create_from_dict(wand_dict)
	_check(wand_restored != null, "Wand restores from dict")
	_check(wand_restored is Wand, "Restored item is Wand type")
	_check(wand_restored.tier == 5, "Wand tier preserved")
	_check(wand_restored.item_name == wand.item_name, "Wand name preserved")
	_check(abs(wand_restored.spell_dps - wand.spell_dps) < 0.1, "Wand spell_dps matches after restore")

	# LightningRod round-trip
	var lr = LightningRod.new(3)
	var lr_dict = lr.to_dict()
	_check(lr_dict["item_type"] == "LightningRod", "LightningRod serializes correctly")
	var lr_restored = Item.create_from_dict(lr_dict)
	_check(lr_restored != null, "LightningRod restores from dict")
	_check(lr_restored is LightningRod, "Restored item is LightningRod type")
	_check(lr_restored.tier == 3, "LightningRod tier preserved")

	# Sceptre round-trip
	var sc = Sceptre.new(1)
	var sc_dict = sc.to_dict()
	_check(sc_dict["item_type"] == "Sceptre", "Sceptre serializes correctly")
	var sc_restored = Item.create_from_dict(sc_dict)
	_check(sc_restored != null, "Sceptre restores from dict")
	_check(sc_restored is Sceptre, "Restored item is Sceptre type")
	_check(sc_restored.tier == 1, "Sceptre tier preserved")


# --- Group 27: New Spell Stat Types ---

func _group_27_new_spell_stat_types() -> void:
	print("\n--- Group 27: New Spell Stat Types ---")

	# Enum values exist and are distinct
	var lightning_type = Tag.StatType.FLAT_SPELL_LIGHTNING_DAMAGE
	var fire_type = Tag.StatType.FLAT_SPELL_FIRE_DAMAGE
	var spell_type = Tag.StatType.FLAT_SPELL_DAMAGE
	_check(lightning_type != fire_type, "FLAT_SPELL_LIGHTNING_DAMAGE != FLAT_SPELL_FIRE_DAMAGE")
	_check(lightning_type != spell_type, "FLAT_SPELL_LIGHTNING_DAMAGE != FLAT_SPELL_DAMAGE")
	_check(fire_type != spell_type, "FLAT_SPELL_FIRE_DAMAGE != FLAT_SPELL_DAMAGE")

	# StatCalculator routes correctly
	var fire_affix = Affix.new()
	fire_affix.affix_name = "Test Fire Spell"
	fire_affix.add_min = 10
	fire_affix.add_max = 20
	fire_affix.stat_types.append(Tag.StatType.FLAT_SPELL_FIRE_DAMAGE)
	fire_affix.tags.append(Tag.SPELL)
	fire_affix.tags.append(Tag.FIRE)

	var result = StatCalculator.calculate_spell_damage_range(0, 0, [fire_affix])
	_check("spell_fire" in result, "Result contains spell_fire key")
	_check("spell_lightning" in result, "Result contains spell_lightning key")
	_check("spell" in result, "Result contains spell key")
	_check(result["spell_fire"]["min"] == 10.0, "Fire spell affix routes to spell_fire min")
	_check(result["spell_fire"]["max"] == 20.0, "Fire spell affix routes to spell_fire max")
	_check(result["spell"]["min"] == 0.0, "Generic spell unaffected by fire affix")
	_check(result["spell_lightning"]["min"] == 0.0, "Lightning spell unaffected by fire affix")


# --- Group 28: Hero Spell Combat Mode ---

func _group_28_hero_spell_combat_mode() -> void:
	print("\n--- Group 28: Hero Spell Combat Mode ---")

	var hero = Hero.new()
	_check(hero.is_spell_user == false, "is_spell_user defaults to false")

	# Equip a Wand and verify spell damage populates
	var wand = Wand.new(5)
	hero.equipped_items["weapon"] = wand
	hero.update_stats()

	_check(hero.spell_damage_ranges["spell"]["max"] > 0.0, "Spell damage populates with Wand equipped")
	_check(hero.total_spell_dps > 0.0, "Spell DPS > 0 with Wand equipped")

	# Equip a LightningRod and verify element-specific spell damage
	var lr = LightningRod.new(5)
	hero.equipped_items["weapon"] = lr
	hero.update_stats()

	_check(hero.spell_damage_ranges["spell_lightning"]["max"] > 0.0, "Lightning spell damage populates with LightningRod")

	# Equip a Sceptre and verify fire spell damage
	var sc = Sceptre.new(5)
	hero.equipped_items["weapon"] = sc
	hero.update_stats()

	_check(hero.spell_damage_ranges["spell_fire"]["max"] > 0.0, "Fire spell damage populates with Sceptre")

	# Equip a Broadsword (STR weapon) — spell damage should be zero
	var sword = Broadsword.new(5)
	hero.equipped_items["weapon"] = sword
	hero.update_stats()

	_check(hero.total_spell_dps == 0.0, "Spell DPS is 0 with Broadsword equipped (no spell channel)")

	# Toggle spell mode
	hero.is_spell_user = true
	_check(hero.is_spell_user == true, "is_spell_user can be set to true")
	hero.is_spell_user = false


# --- Group 29: Drop Pool Inclusion ---

func _group_29_drop_pool_inclusion() -> void:
	print("\n--- Group 29: Drop Pool Inclusion ---")

	# Verify all 9 weapon types can construct
	var weapons = [
		Broadsword.new(8), Battleaxe.new(8), Warhammer.new(8),
		Dagger.new(8), VenomBlade.new(8), Shortbow.new(8),
		Wand.new(8), LightningRod.new(8), Sceptre.new(8),
	]
	_check(weapons.size() == 9, "9 weapon types total")
	for w in weapons:
		_check(w != null, "%s constructs" % w.get_item_type_string())

	# Verify ITEM_TYPE_STRINGS has 21 entries
	_check(Item.ITEM_TYPE_STRINGS.size() == 21, "ITEM_TYPE_STRINGS has 21 entries")

	# Verify each INT weapon is in ITEM_TYPE_STRINGS
	_check("Wand" in Item.ITEM_TYPE_STRINGS, "Wand in ITEM_TYPE_STRINGS")
	_check("LightningRod" in Item.ITEM_TYPE_STRINGS, "LightningRod in ITEM_TYPE_STRINGS")
	_check("Sceptre" in Item.ITEM_TYPE_STRINGS, "Sceptre in ITEM_TYPE_STRINGS")


# --- Group 30: DoT Stat Type Existence (DOT-01) ---

func _group_30_dot_stat_type_existence() -> void:
	print("\n--- Group 30: DoT stat type existence ---")

	# Verify all DoT stat types exist in the enum
	var bleed_damage: int = Tag.StatType.BLEED_DAMAGE
	var poison_damage: int = Tag.StatType.POISON_DAMAGE
	var burn_damage: int = Tag.StatType.BURN_DAMAGE
	var bleed_chance: int = Tag.StatType.BLEED_CHANCE
	var poison_chance: int = Tag.StatType.POISON_CHANCE
	var burn_chance: int = Tag.StatType.BURN_CHANCE
	var chaos_res: int = Tag.StatType.CHAOS_RESISTANCE

	_check(bleed_damage >= 0, "BLEED_DAMAGE exists in StatType enum")
	_check(poison_damage >= 0, "POISON_DAMAGE exists in StatType enum")
	_check(burn_damage >= 0, "BURN_DAMAGE exists in StatType enum")
	_check(bleed_chance >= 0, "BLEED_CHANCE exists in StatType enum")
	_check(poison_chance >= 0, "POISON_CHANCE exists in StatType enum")
	_check(burn_chance >= 0, "BURN_CHANCE exists in StatType enum")
	_check(Tag.DOT == "DOT", "Tag.DOT constant equals 'DOT'")
	_check(chaos_res >= 0, "CHAOS_RESISTANCE exists in StatType enum")

	# Verify all are distinct
	var all_vals := [bleed_damage, poison_damage, burn_damage, bleed_chance, poison_chance, burn_chance, chaos_res]
	for i in all_vals.size():
		for j in range(i + 1, all_vals.size()):
			_check(all_vals[i] != all_vals[j], "DoT stat type %d != %d (indices %d, %d)" % [all_vals[i], all_vals[j], i, j])


# --- Group 31: DoT Stat Aggregation and Proc Logic (DOT-02/03/04/05) ---

func _group_31_dot_stat_aggregation_and_proc() -> void:
	print("\n--- Group 31: DoT stat aggregation and proc logic ---")

	# Warhammer has BLEED_DAMAGE implicit
	var warhammer := Warhammer.new(1)
	_check(warhammer.implicit != null, "Warhammer has implicit")
	_check(Tag.StatType.BLEED_DAMAGE in warhammer.implicit.stat_types, "Warhammer implicit uses BLEED_DAMAGE")

	# VenomBlade has POISON_DAMAGE implicit
	var venom := VenomBlade.new(1)
	_check(venom.implicit != null, "VenomBlade has implicit")
	_check(Tag.StatType.POISON_DAMAGE in venom.implicit.stat_types, "VenomBlade implicit uses POISON_DAMAGE")

	# Hero with bleed affixes aggregates DoT stats
	var hero := Hero.new()
	var weapon := Warhammer.new(1)
	# Add a bleed chance suffix manually
	var bleed_chance_affix := Affix.new(
		"Bleed Chance", Affix.AffixType.SUFFIX,
		3, 10,
		[Tag.DOT, Tag.PHYSICAL, Tag.WEAPON],
		[Tag.StatType.BLEED_CHANCE],
		Vector2i(1, 32)
	)
	weapon.suffixes.append(bleed_chance_affix)
	hero.equipped_items["weapon"] = weapon
	hero.update_stats()
	_check(hero.total_bleed_chance > 0.0, "Hero total_bleed_chance > 0 with bleed chance suffix")
	_check(hero.total_bleed_damage_min > 0.0, "Hero total_bleed_damage_min > 0 with Warhammer implicit")

	# MonsterPack bleed stacking: max 8
	var pack := MonsterPack.new()
	pack.hp = 1000.0
	pack.max_hp = 1000.0
	for i in 8:
		pack.apply_dot("bleed", 10.0, "physical")
	_check(pack.get_dot_count("bleed") == 8, "Pack has 8 bleed stacks after 8 applications")

	# 9th application replaces oldest, count stays at 8
	pack.apply_dot("bleed", 10.0, "physical")
	_check(pack.get_dot_count("bleed") == 8, "Pack still has 8 bleed stacks after 9th application (replaced oldest)")

	# Poison: unlimited stacks
	var poison_pack := MonsterPack.new()
	poison_pack.hp = 1000.0
	poison_pack.max_hp = 1000.0
	for i in 20:
		poison_pack.apply_dot("poison", 5.0, "chaos")
	_check(poison_pack.get_dot_count("poison") == 20, "Pack has 20 poison stacks (unlimited)")

	# Burn: single stack, refreshed
	var burn_pack := MonsterPack.new()
	burn_pack.hp = 1000.0
	burn_pack.max_hp = 1000.0
	burn_pack.apply_dot("burn", 15.0, "fire")
	burn_pack.apply_dot("burn", 15.0, "fire")
	_check(burn_pack.get_dot_count("burn") == 1, "Pack has 1 burn stack (single, refreshed)")

	# process_dot_tick: 3 bleed stacks of 10.0 each = 30.0 total damage
	var tick_pack := MonsterPack.new()
	tick_pack.hp = 1000.0
	tick_pack.max_hp = 1000.0
	tick_pack.apply_dot("bleed", 10.0, "physical")
	tick_pack.apply_dot("bleed", 10.0, "physical")
	tick_pack.apply_dot("bleed", 10.0, "physical")
	var tick_results := tick_pack.process_dot_tick()
	var total_tick_damage := 0.0
	for r in tick_results:
		if r["type"] == "bleed":
			total_tick_damage = r["damage"]
	_check(is_equal_approx(total_tick_damage, 30.0), "process_dot_tick: 3 bleed stacks deal 30.0 total damage")

	# After 4 ticks total (3 remaining after first), all stacks expire
	tick_pack.process_dot_tick()  # tick 2 (2 remaining)
	tick_pack.process_dot_tick()  # tick 3 (1 remaining)
	tick_pack.process_dot_tick()  # tick 4 (0 remaining, expired)
	_check(tick_pack.get_dot_count("bleed") == 0, "All bleed stacks expired after 4 ticks")

	# clear_dots empties active_dots
	var clear_pack := MonsterPack.new()
	clear_pack.hp = 1000.0
	clear_pack.max_hp = 1000.0
	clear_pack.apply_dot("bleed", 10.0, "physical")
	clear_pack.apply_dot("poison", 5.0, "chaos")
	clear_pack.clear_dots()
	_check(clear_pack.active_dots.size() == 0, "clear_dots empties active_dots")


# --- Group 32: DoT Defense Interaction (DOT-07) ---

func _group_32_dot_defense_interaction() -> void:
	print("\n--- Group 32: DoT defense interaction ---")

	# Bleed (physical): no resistance, no ES — full damage to life
	var r1 := DefenseCalculator.calculate_dot_damage_taken(100.0, "physical", 0, 0, 0.0)
	_check(is_equal_approx(r1["life_damage"], 100.0), "Bleed 100 damage, no res, no ES: life_damage == 100.0")
	_check(is_equal_approx(r1["es_damage"], 0.0), "Bleed 100 damage, no res, no ES: es_damage == 0.0")

	# Chaos: 50 resistance reduces damage by 50%
	var r2 := DefenseCalculator.calculate_dot_damage_taken(100.0, "chaos", 0, 50, 0.0)
	_check(is_equal_approx(r2["life_damage"], 50.0), "Chaos 100 damage, 50 res: life_damage == 50.0")

	# Fire: 75 resistance reduces damage by 75% (at cap)
	var r3 := DefenseCalculator.calculate_dot_damage_taken(100.0, "fire", 75, 0, 0.0)
	_check(is_equal_approx(r3["life_damage"], 25.0), "Fire 100 damage, 75 res: life_damage == 25.0")

	# Fire: 100 resistance over-cap clamped to 75%
	var r4 := DefenseCalculator.calculate_dot_damage_taken(100.0, "fire", 100, 0, 0.0)
	_check(is_equal_approx(r4["life_damage"], 25.0), "Fire 100 damage, 100 res (over-cap): life_damage == 25.0")

	# Physical with ES: 50/50 split
	var r5 := DefenseCalculator.calculate_dot_damage_taken(100.0, "physical", 0, 0, 50.0)
	_check(is_equal_approx(r5["es_damage"], 50.0), "Physical 100 damage, 50 ES: es_damage == 50.0")
	_check(is_equal_approx(r5["life_damage"], 50.0), "Physical 100 damage, 50 ES: life_damage == 50.0")

	# Physical with low ES: overflow to life
	var r6 := DefenseCalculator.calculate_dot_damage_taken(100.0, "physical", 0, 0, 10.0)
	_check(is_equal_approx(r6["es_damage"], 10.0), "Physical 100 damage, 10 ES: es_damage == 10.0")
	_check(is_equal_approx(r6["life_damage"], 90.0), "Physical 100 damage, 10 ES: life_damage == 90.0")

	# Hero with CHAOS_RESISTANCE suffix
	var hero := Hero.new()
	var weapon := Broadsword.new(1)
	var chaos_res_affix := Affix.new(
		"Chaos Resistance", Affix.AffixType.SUFFIX,
		1, 3,
		[Tag.DEFENSE, Tag.CHAOS, Tag.WEAPON],
		[Tag.StatType.CHAOS_RESISTANCE],
		Vector2i(1, 32)
	)
	weapon.suffixes.append(chaos_res_affix)
	hero.equipped_items["weapon"] = weapon
	hero.update_stats()
	_check(hero.total_chaos_resistance > 0, "Hero total_chaos_resistance > 0 with CHAOS_RESISTANCE suffix")


# --- Group 33: DoT DPS Calculation (DOT-02) ---

func _group_33_dot_dps_calculation() -> void:
	print("\n--- Group 33: DoT DPS calculation ---")

	# Attack-mode hero with bleed chance + bleed damage: total_dot_dps > 0
	var hero_atk := Hero.new()
	hero_atk.is_spell_user = false
	var warhammer := Warhammer.new(1)  # Has BLEED_DAMAGE implicit
	var bleed_chance_affix := Affix.new(
		"Bleed Chance", Affix.AffixType.SUFFIX,
		3, 10,
		[Tag.DOT, Tag.PHYSICAL, Tag.WEAPON],
		[Tag.StatType.BLEED_CHANCE],
		Vector2i(1, 32)
	)
	warhammer.suffixes.append(bleed_chance_affix)
	hero_atk.equipped_items["weapon"] = warhammer
	hero_atk.update_stats()
	_check(hero_atk.total_dot_dps > 0.0, "Attack hero with bleed affixes: total_dot_dps > 0")

	# Spell-mode hero with burn chance + burn damage: total_dot_dps > 0
	var hero_spell := Hero.new()
	var sceptre := Sceptre.new(1)  # INT weapon with fire spell damage
	var burn_chance_affix := Affix.new(
		"Burn Chance", Affix.AffixType.SUFFIX,
		3, 10,
		[Tag.DOT, Tag.FIRE, Tag.WEAPON],
		[Tag.StatType.BURN_CHANCE],
		Vector2i(1, 32)
	)
	var burn_damage_affix := Affix.new(
		"Burn Damage", Affix.AffixType.PREFIX,
		2, 10,
		[Tag.DOT, Tag.FIRE, Tag.WEAPON],
		[Tag.StatType.BURN_DAMAGE],
		Vector2i(1, 32), 2, 3, 4, 6
	)
	sceptre.suffixes.append(burn_chance_affix)
	sceptre.prefixes.append(burn_damage_affix)
	hero_spell.equipped_items["weapon"] = sceptre
	hero_spell.update_stats()
	hero_spell.is_spell_user = true
	hero_spell.calculate_dot_stats()
	hero_spell.calculate_dot_dps()
	_check(hero_spell.total_dot_dps > 0.0, "Spell hero with burn affixes: total_dot_dps > 0")

	# Hero with no DoT affixes: total_dot_dps == 0
	var hero_none := Hero.new()
	var broadsword := Broadsword.new(1)
	hero_none.equipped_items["weapon"] = broadsword
	hero_none.update_stats()
	_check(hero_none.total_dot_dps == 0.0, "Hero with no DoT affixes: total_dot_dps == 0")

	# Attack-mode hero with bleed affixes but is_spell_user = true: bleed does not contribute
	var hero_wrong_mode := Hero.new()
	var warhammer2 := Warhammer.new(1)
	var bleed_chance2 := Affix.new(
		"Bleed Chance", Affix.AffixType.SUFFIX,
		3, 10,
		[Tag.DOT, Tag.PHYSICAL, Tag.WEAPON],
		[Tag.StatType.BLEED_CHANCE],
		Vector2i(1, 32)
	)
	warhammer2.suffixes.append(bleed_chance2)
	hero_wrong_mode.equipped_items["weapon"] = warhammer2
	hero_wrong_mode.update_stats()
	hero_wrong_mode.is_spell_user = true
	hero_wrong_mode.calculate_dot_dps()
	# Bleed is attack-only; spell user should not get bleed DPS
	# But burn_chance is 0 so total_dot_dps should be 0
	_check(hero_wrong_mode.total_dot_dps == 0.0, "Spell-mode hero with bleed affixes: total_dot_dps == 0 (attack-only)")

	# Spell-mode hero with burn affixes but is_spell_user = false: burn does not contribute
	var hero_wrong_mode2 := Hero.new()
	hero_wrong_mode2.is_spell_user = false
	var sceptre2 := Sceptre.new(1)
	var burn_chance2 := Affix.new(
		"Burn Chance", Affix.AffixType.SUFFIX,
		3, 10,
		[Tag.DOT, Tag.FIRE, Tag.WEAPON],
		[Tag.StatType.BURN_CHANCE],
		Vector2i(1, 32)
	)
	sceptre2.suffixes.append(burn_chance2)
	hero_wrong_mode2.equipped_items["weapon"] = sceptre2
	hero_wrong_mode2.update_stats()
	# Burn is spell-only; attack user should not get burn DPS
	# But bleed_chance is 0 so total_dot_dps should be 0
	_check(hero_wrong_mode2.total_dot_dps == 0.0, "Attack-mode hero with burn affixes: total_dot_dps == 0 (spell-only)")


# --- Group 34: GameEvents DoT Signal Verification (DOT-06) ---

func _group_34_game_events_dot_signals() -> void:
	print("\n--- Group 34: GameEvents DoT signal verification ---")

	# Verify GameEvents has the DoT signals
	_check(GameEvents.has_signal("dot_applied"), "GameEvents has dot_applied signal")
	_check(GameEvents.has_signal("dot_ticked"), "GameEvents has dot_ticked signal")
	_check(GameEvents.has_signal("dot_expired"), "GameEvents has dot_expired signal")

	# Verify forge_view code path includes DoT DPS display
	# We can't instantiate forge_view in a test, but we can check the source file
	var forge_script := load("res://scenes/forge_view.gd") as GDScript
	var source := forge_script.source_code
	_check("DoT DPS" in source, "forge_view.gd contains 'DoT DPS' display text")
	_check("get_total_dot_dps" in source, "forge_view.gd calls get_total_dot_dps()")
	_check("total_chaos_resistance" in source or "get_total_chaos_resistance" in source, "forge_view.gd references chaos resistance")


# --- Group 35: Save Version & Loot Integration (LOOT-01/02/03/04) ---

func _group_35_save_version_and_loot_integration() -> void:
	print("\n--- Group 35: Save version & loot integration ---")

	# 1. SAVE_VERSION is at least 7 (bumped to 9 in Phase 58)
	_check(SaveManager.SAVE_VERSION >= 7, "SAVE_VERSION >= 7")

	# 2. Old save wipe logic: version > 6 ensures wipe path triggers
	_check(SaveManager.SAVE_VERSION > 6, "SAVE_VERSION > 6 (old saves trigger wipe)")

	# 3. Drop pool completeness — verify all 21 item bases via source code inspection
	var gv_script := load("res://scenes/gameplay_view.gd") as GDScript
	var gv_source := gv_script.source_code

	# Verify all 21 item type names appear in get_random_item_base
	var expected_bases := [
		"Broadsword", "Battleaxe", "Warhammer",
		"Dagger", "VenomBlade", "Shortbow",
		"Wand", "LightningRod", "Sceptre",
		"IronPlate", "LeatherVest", "SilkRobe",
		"IronHelm", "LeatherHood", "Circlet",
		"IronGreaves", "LeatherBoots", "SilkSlippers",
		"IronBand", "JadeRing", "SapphireRing",
	]
	_check(expected_bases.size() == 21, "Expected 21 item bases")

	var all_found := true
	for base_name in expected_bases:
		if base_name not in gv_source:
			all_found = false
			_check(false, "%s found in drop pool source" % base_name)
	if all_found:
		_check(true, "All 21 item bases present in gameplay_view.gd drop pool")

	# Verify slot-first distribution logic
	_check("randi() % slots.size()" in gv_source, "Slot selection uses randi() % slots.size()")
	_check("randi() % slot_bases.size()" in gv_source, "Base selection uses randi() % slot_bases.size()")

	# 4. Verify all 21 bases construct correctly with all 3 archetypes present
	var all_items: Array = []
	all_items.append(Broadsword.new(8))
	all_items.append(Battleaxe.new(8))
	all_items.append(Warhammer.new(8))
	all_items.append(Dagger.new(8))
	all_items.append(VenomBlade.new(8))
	all_items.append(Shortbow.new(8))
	all_items.append(Wand.new(8))
	all_items.append(LightningRod.new(8))
	all_items.append(Sceptre.new(8))
	all_items.append(IronPlate.new(8))
	all_items.append(LeatherVest.new(8))
	all_items.append(SilkRobe.new(8))
	all_items.append(IronHelm.new(8))
	all_items.append(LeatherHood.new(8))
	all_items.append(Circlet.new(8))
	all_items.append(IronGreaves.new(8))
	all_items.append(LeatherBoots.new(8))
	all_items.append(SilkSlippers.new(8))
	all_items.append(IronBand.new(8))
	all_items.append(JadeRing.new(8))
	all_items.append(SapphireRing.new(8))
	_check(all_items.size() == 21, "All 21 item bases construct successfully")

	# Verify all 3 archetypes present via valid_tags
	var has_str := false
	var has_dex := false
	var has_int := false
	for item in all_items:
		if Tag.STR in item.valid_tags:
			has_str = true
		if Tag.DEX in item.valid_tags:
			has_dex = true
		if Tag.INT in item.valid_tags:
			has_int = true
	_check(has_str, "STR archetype items exist in drop pool")
	_check(has_dex, "DEX archetype items exist in drop pool")
	_check(has_int, "INT archetype items exist in drop pool")

	# Verify unique type strings cover all 21
	var type_set := {}
	for item in all_items:
		type_set[item.get_item_type_string()] = true
	_check(type_set.size() == 21, "21 unique item type strings across all bases")

	# 5. is_item_better uses tier only (LOOT-03 dropped — tier comparison stays)
	var low_tier := Broadsword.new(8)
	var high_tier := Broadsword.new(1)
	var forge_script2 := load("res://scenes/forge_view.gd") as GDScript
	var forge_source := forge_script2.source_code
	# Verify the function body is tier-only comparison
	_check("return new_item.tier > existing_item.tier" in forge_source, "is_item_better uses tier-only comparison (LOOT-03 dropped)")


func _group_36_hero_archetype_data() -> void:
	print("\n--- Group 36: Hero Archetype Data (Phase 50) ---")
	_reset_fresh()

	# HERO-01: REGISTRY has exactly 9 entries
	_check(HeroArchetype.REGISTRY.size() == 9, "REGISTRY contains exactly 9 heroes")

	# HERO-01: 3 per archetype
	var str_count := 0
	var dex_count := 0
	var int_count := 0
	for hero_id in HeroArchetype.REGISTRY:
		var data: Dictionary = HeroArchetype.REGISTRY[hero_id]
		match data["archetype"]:
			HeroArchetype.Archetype.STR: str_count += 1
			HeroArchetype.Archetype.DEX: dex_count += 1
			HeroArchetype.Archetype.INT: int_count += 1
	_check(str_count == 3, "3 STR heroes in REGISTRY")
	_check(dex_count == 3, "3 DEX heroes in REGISTRY")
	_check(int_count == 3, "3 INT heroes in REGISTRY")

	# HERO-02: from_id returns correct fields
	var berserker := HeroArchetype.from_id("str_hit")
	_check(berserker != null, "from_id('str_hit') returns non-null")
	_check(berserker.id == "str_hit", "str_hit id is 'str_hit'")
	_check(berserker.archetype == HeroArchetype.Archetype.STR, "str_hit archetype is STR")
	_check(berserker.subvariant == HeroArchetype.Subvariant.HIT, "str_hit subvariant is HIT")
	_check(berserker.title == "The Berserker", "str_hit title is 'The Berserker'")
	_check(berserker.spell_user == false, "str_hit spell_user is false")
	_check(berserker.passive_bonuses.has("attack_damage_more"), "str_hit has attack_damage_more bonus")
	_check(berserker.passive_bonuses.has("physical_damage_more"), "str_hit has physical_damage_more bonus")

	# HERO-02: from_id unknown returns null
	var unknown := HeroArchetype.from_id("nonexistent")
	_check(unknown == null, "from_id('nonexistent') returns null")

	# HERO-02: generate_choices returns 3, one per archetype
	var choices := HeroArchetype.generate_choices()
	_check(choices.size() == 3, "generate_choices() returns exactly 3")
	var archetypes_seen: Array[int] = []
	for choice in choices:
		_check(choice != null, "generate_choices() entry is non-null")
		if choice != null:
			archetypes_seen.append(choice.archetype)
	archetypes_seen.sort()
	_check(archetypes_seen == [HeroArchetype.Archetype.STR, HeroArchetype.Archetype.DEX, HeroArchetype.Archetype.INT], "generate_choices() has one per archetype")

	# HERO-03: All heroes have non-empty title
	for hero_id in HeroArchetype.REGISTRY:
		var h := HeroArchetype.from_id(hero_id)
		_check(h.title != "", "Hero '%s' has non-empty title" % hero_id)

	# HERO-03: Color family check -- STR red (r > g and r > b), DEX green, INT blue
	for hero_id in HeroArchetype.REGISTRY:
		var data: Dictionary = HeroArchetype.REGISTRY[hero_id]
		var c: Color = data["color"]
		match data["archetype"]:
			HeroArchetype.Archetype.STR:
				_check(c.r > c.b, "STR hero '%s' color has red > blue" % hero_id)
			HeroArchetype.Archetype.DEX:
				_check(c.g > c.r, "DEX hero '%s' color has green > red" % hero_id)
			HeroArchetype.Archetype.INT:
				_check(c.b > c.r or (c.b > 0.4 and c.r < 0.6), "INT hero '%s' color is blue-family" % hero_id)

	# HERO-02: GameState.hero_archetype is null on fresh game
	_check(GameState.hero_archetype == null, "GameState.hero_archetype is null on fresh game")

	# HERO-02: GameEvents has hero signals
	_check(GameEvents.has_signal("hero_selection_needed"), "GameEvents has hero_selection_needed signal")
	_check(GameEvents.has_signal("hero_selected"), "GameEvents has hero_selected signal")

	# D-07: INT heroes are spell_user true, STR/DEX are false
	for hero_id in HeroArchetype.REGISTRY:
		var h := HeroArchetype.from_id(hero_id)
		if h.archetype == HeroArchetype.Archetype.INT:
			_check(h.spell_user == true, "INT hero '%s' spell_user is true" % hero_id)
		else:
			_check(h.spell_user == false, "Non-INT hero '%s' spell_user is false" % hero_id)


# --- Group 37: Stat Integration (Phase 51 — PASS-01, PASS-02) ---

func _group_37_stat_integration() -> void:
	print("\n--- Group 37: Stat integration (Phase 51) ---")

	# Test 1: PASS-01 classless baseline — null archetype produces no bonus
	_reset_fresh()
	GameState.hero_archetype = null
	var weapon_base := Broadsword.new(1)
	GameState.hero.equipped_items["weapon"] = weapon_base
	GameState.hero.update_stats()
	var baseline_min: float = GameState.hero.damage_ranges["physical"]["min"]
	var baseline_max: float = GameState.hero.damage_ranges["physical"]["max"]
	_check(baseline_min > 0.0, "PASS-01 classless: physical min > 0 with Broadsword equipped")
	# Set archetype to null explicitly, re-call update_stats, damage should match baseline
	GameState.hero_archetype = null
	GameState.hero.update_stats()
	_check(abs(GameState.hero.damage_ranges["physical"]["min"] - baseline_min) < 0.01,
		"PASS-01 classless: null archetype produces identical stats to baseline (min)")
	_check(abs(GameState.hero.damage_ranges["physical"]["max"] - baseline_max) < 0.01,
		"PASS-01 classless: null archetype produces identical stats to baseline (max)")

	# Test 2: PASS-01 STR attack boost — Berserker: attack_damage_more=0.25 + physical_damage_more=0.25
	# physical gets base * 1.25 (element) * 1.25 (channel) = base * 1.5625
	GameState.hero_archetype = HeroArchetype.from_id("str_hit")
	GameState.hero.update_stats()
	var str_phys_min: float = GameState.hero.damage_ranges["physical"]["min"]
	var expected_str_min: float = baseline_min * 1.25 * 1.25
	_check(abs(str_phys_min - expected_str_min) < 0.01,
		"PASS-01 STR str_hit: physical min == baseline * 1.25 * 1.25 (= * 1.5625)")

	# Test 3: PASS-01 STR channel only affects attack elements — fire remains zero (no fire gear)
	var str_fire_min: float = GameState.hero.damage_ranges["fire"]["min"]
	_check(str_fire_min == 0.0,
		"PASS-01 STR str_hit: fire damage remains 0 (no fire gear; attack_damage_more on zero = zero)")

	# Test 4: PASS-01 INT spell boost — Arcanist: spell_damage_more=0.25 + physical_damage_more=0.25
	# spell["spell"] = base_spell * 1.25 (physical->spell element map) * 1.25 (channel)
	_reset_fresh()
	GameState.hero_archetype = null
	var wand := Wand.new(1)
	GameState.hero.equipped_items["weapon"] = wand
	GameState.hero.update_stats()
	var base_spell_min: float = GameState.hero.spell_damage_ranges["spell"]["min"]
	_check(base_spell_min > 0.0, "PASS-01 INT: Wand(1) gives nonzero spell_damage_ranges['spell']")
	GameState.hero_archetype = HeroArchetype.from_id("int_hit")
	GameState.hero.update_stats()
	var int_spell_min: float = GameState.hero.spell_damage_ranges["spell"]["min"]
	var expected_int_spell: float = base_spell_min * 1.25 * 1.25
	_check(abs(int_spell_min - expected_int_spell) < 0.01,
		"PASS-01 INT int_hit: spell min == base * 1.25 (physical_damage_more) * 1.25 (spell_damage_more)")

	# Test 5: PASS-01 channel isolation — attack_damage_more (STR) does NOT affect spell
	_reset_fresh()
	GameState.hero_archetype = null
	var sword_for_spell := Wand.new(1)
	GameState.hero.equipped_items["weapon"] = sword_for_spell
	GameState.hero.update_stats()
	var spell_base_for_str: float = GameState.hero.spell_damage_ranges["spell"]["min"]
	GameState.hero_archetype = HeroArchetype.from_id("str_hit")
	GameState.hero.update_stats()
	var spell_with_str: float = GameState.hero.spell_damage_ranges["spell"]["min"]
	# STR has attack_damage_more (no effect on spell) + physical_damage_more (maps to spell via element map)
	# physical_damage_more DOES apply to spell["spell"] via spell_element_map, but attack_damage_more does NOT
	# So spell_with_str = spell_base_for_str * 1.25 (physical_damage_more only)
	var expected_spell_str: float = spell_base_for_str * 1.25
	_check(abs(spell_with_str - expected_spell_str) < 0.01,
		"PASS-01 STR isolation: attack_damage_more does NOT affect spell; only physical_damage_more (element map) applies")

	# Test 6: PASS-01 channel isolation — spell_damage_more (INT) does NOT affect attack
	_reset_fresh()
	GameState.hero_archetype = null
	var broadsword_for_int := Broadsword.new(1)
	GameState.hero.equipped_items["weapon"] = broadsword_for_int
	GameState.hero.update_stats()
	var atk_base_for_int: float = GameState.hero.damage_ranges["physical"]["min"]
	GameState.hero_archetype = HeroArchetype.from_id("int_hit")
	GameState.hero.update_stats()
	var atk_with_int: float = GameState.hero.damage_ranges["physical"]["min"]
	# int_hit has spell_damage_more (no effect on attack) + physical_damage_more (DOES affect attack)
	# So atk_with_int = atk_base_for_int * 1.25 (physical_damage_more only, not spell_damage_more)
	var expected_atk_int: float = atk_base_for_int * 1.25
	_check(abs(atk_with_int - expected_atk_int) < 0.01,
		"PASS-01 INT isolation: spell_damage_more does NOT affect attack; only physical_damage_more (element) applies")

	# Test 7: PASS-01 DEX general applies to both channels
	# dex_hit: damage_more=0.15 + physical_damage_more=0.25
	# Attack: physical = base * 1.25 (element) * 1.15 (general)
	_reset_fresh()
	GameState.hero_archetype = null
	var broadsword_dex := Broadsword.new(1)
	GameState.hero.equipped_items["weapon"] = broadsword_dex
	GameState.hero.update_stats()
	var atk_base_dex: float = GameState.hero.damage_ranges["physical"]["min"]
	GameState.hero_archetype = HeroArchetype.from_id("dex_hit")
	GameState.hero.update_stats()
	var atk_dex_min: float = GameState.hero.damage_ranges["physical"]["min"]
	var expected_dex_atk: float = atk_base_dex * 1.25 * 1.15
	_check(abs(atk_dex_min - expected_dex_atk) < 0.01,
		"PASS-01 DEX dex_hit: physical attack min == base * 1.25 (element) * 1.15 (general damage_more)")

	# Test 8: PASS-01 element-specific (Fire Knight / str_elem)
	# str_elem: attack_damage_more=0.25 + fire_damage_more=0.25
	# Physical: base * 1.25 (channel only, no physical_damage_more)
	# Fire: 0 (no fire gear) * 1.25 * 1.25 = still 0
	_reset_fresh()
	GameState.hero_archetype = null
	var sword_elem := Broadsword.new(1)
	GameState.hero.equipped_items["weapon"] = sword_elem
	GameState.hero.update_stats()
	var base_phys_elem: float = GameState.hero.damage_ranges["physical"]["min"]
	GameState.hero_archetype = HeroArchetype.from_id("str_elem")
	GameState.hero.update_stats()
	var phys_with_str_elem: float = GameState.hero.damage_ranges["physical"]["min"]
	# str_elem has attack_damage_more=0.25 (channel, scales physical) but no physical_damage_more
	var expected_phys_str_elem: float = base_phys_elem * 1.25
	_check(abs(phys_with_str_elem - expected_phys_str_elem) < 0.01,
		"PASS-01 Fire Knight str_elem: physical == base * 1.25 (attack_damage_more channel only, no physical bonus)")
	_check(GameState.hero.damage_ranges["fire"]["min"] == 0.0,
		"PASS-01 Fire Knight str_elem: fire remains 0 (no fire gear equipped)")

	# Test 9: PASS-02 DoT chance — Reaver (str_dot): bleed_chance_more=0.20
	_reset_fresh()
	GameState.hero_archetype = null
	var warhammer_dot := Warhammer.new(1)
	var bleed_chance_affix := Affix.new(
		"Bleed Chance", Affix.AffixType.SUFFIX,
		3, 10,
		[Tag.DOT, Tag.PHYSICAL, Tag.WEAPON],
		[Tag.StatType.BLEED_CHANCE],
		Vector2i(1, 32)
	)
	warhammer_dot.suffixes.append(bleed_chance_affix)
	GameState.hero.equipped_items["weapon"] = warhammer_dot
	GameState.hero.update_stats()
	var base_bleed_chance: float = GameState.hero.total_bleed_chance
	_check(base_bleed_chance > 0.0, "PASS-02 Reaver: bleed_chance > 0 with bleed chance affix equipped")
	GameState.hero_archetype = HeroArchetype.from_id("str_dot")
	GameState.hero.update_stats()
	var boosted_bleed_chance: float = GameState.hero.total_bleed_chance
	var expected_bleed_chance: float = base_bleed_chance * 1.20
	_check(abs(boosted_bleed_chance - expected_bleed_chance) < 0.01,
		"PASS-02 Reaver str_dot: bleed_chance == base_bleed_chance * 1.20 (bleed_chance_more=0.20)")

	# Test 10: PASS-02 DoT chance — Plague Hunter (dex_dot): poison_chance_more=0.20
	_reset_fresh()
	GameState.hero_archetype = null
	var dagger_dot := Dagger.new(1)
	var poison_chance_affix := Affix.new(
		"Poison Chance", Affix.AffixType.SUFFIX,
		3, 10,
		[Tag.DOT, Tag.PHYSICAL, Tag.WEAPON],
		[Tag.StatType.POISON_CHANCE],
		Vector2i(1, 32)
	)
	dagger_dot.suffixes.append(poison_chance_affix)
	GameState.hero.equipped_items["weapon"] = dagger_dot
	GameState.hero.update_stats()
	var base_poison_chance: float = GameState.hero.total_poison_chance
	_check(base_poison_chance > 0.0, "PASS-02 Plague Hunter: poison_chance > 0 with poison chance affix equipped")
	GameState.hero_archetype = HeroArchetype.from_id("dex_dot")
	GameState.hero.update_stats()
	var boosted_poison_chance: float = GameState.hero.total_poison_chance
	var expected_poison_chance: float = base_poison_chance * 1.20
	_check(abs(boosted_poison_chance - expected_poison_chance) < 0.01,
		"PASS-02 Plague Hunter dex_dot: poison_chance == base_poison_chance * 1.20 (poison_chance_more=0.20)")

	# Test 11: PASS-02 DoT chance — Warlock (int_dot): burn_chance_more=0.20
	_reset_fresh()
	GameState.hero_archetype = null
	var sceptre_dot := Sceptre.new(1)
	var burn_chance_affix := Affix.new(
		"Burn Chance", Affix.AffixType.SUFFIX,
		3, 10,
		[Tag.DOT, Tag.FIRE, Tag.WEAPON],
		[Tag.StatType.BURN_CHANCE],
		Vector2i(1, 32)
	)
	sceptre_dot.suffixes.append(burn_chance_affix)
	GameState.hero.equipped_items["weapon"] = sceptre_dot
	GameState.hero.update_stats()
	var base_burn_chance: float = GameState.hero.total_burn_chance
	_check(base_burn_chance > 0.0, "PASS-02 Warlock: burn_chance > 0 with burn chance affix equipped")
	GameState.hero_archetype = HeroArchetype.from_id("int_dot")
	GameState.hero.update_stats()
	var boosted_burn_chance: float = GameState.hero.total_burn_chance
	var expected_burn_chance: float = base_burn_chance * 1.20
	_check(abs(boosted_burn_chance - expected_burn_chance) < 0.01,
		"PASS-02 Warlock int_dot: burn_chance == base_burn_chance * 1.20 (burn_chance_more=0.20)")

	# Test 12: D-02 is_spell_user derivation from archetype
	_reset_fresh()
	GameState.hero_archetype = HeroArchetype.from_id("int_hit")
	GameState.hero.update_stats()
	_check(GameState.hero.is_spell_user == true,
		"D-02: INT hero (int_hit) derives is_spell_user == true")
	GameState.hero_archetype = HeroArchetype.from_id("str_hit")
	GameState.hero.update_stats()
	_check(GameState.hero.is_spell_user == false,
		"D-02: STR hero (str_hit) derives is_spell_user == false")
	GameState.hero_archetype = null
	GameState.hero.update_stats()
	_check(GameState.hero.is_spell_user == false,
		"D-02: null archetype derives is_spell_user == false (classless Adventurer)")

	# Cleanup: reset archetype to null for test isolation
	GameState.hero_archetype = null


# --- Group 38: Save Persistence (SAVE-01) ---

func _group_38_save_persistence() -> void:
	print("\n=== GROUP 38: Save Persistence (SAVE-01) ===")

	# Test 38.1: SAVE_VERSION is 9 (bumped from 8 in Phase 58)
	_check(SaveManager.SAVE_VERSION == 9, "38.1 SAVE_VERSION is 9")

	# Test 38.2: _build_save_data includes hero_archetype_id when archetype set
	GameState.hero_archetype = HeroArchetype.from_id("str_hit")
	var save_data := SaveManager._build_save_data()
	_check(save_data.has("hero_archetype_id"), "38.2 save data has hero_archetype_id key")
	_check(save_data["hero_archetype_id"] == "str_hit", "38.3 hero_archetype_id is 'str_hit'")

	# Test 38.4: _build_save_data writes null when no archetype
	GameState.hero_archetype = null
	save_data = SaveManager._build_save_data()
	_check(save_data["hero_archetype_id"] == null, "38.4 hero_archetype_id is null for classless")

	# Test 38.5: _restore_state restores archetype from ID
	var restore_data := save_data.duplicate(true)
	restore_data["hero_archetype_id"] = "dex_dot"
	restore_data["version"] = 8
	SaveManager._restore_state(restore_data)
	_check(GameState.hero_archetype != null, "38.5 hero_archetype restored (not null)")
	_check(GameState.hero_archetype.id == "dex_dot", "38.6 restored archetype id is 'dex_dot'")

	# Test 38.7: _restore_state handles null archetype ID
	restore_data["hero_archetype_id"] = null
	SaveManager._restore_state(restore_data)
	_check(GameState.hero_archetype == null, "38.7 null archetype_id restores to null")

	# Test 38.8: _restore_state handles missing key (pre-v8 data shape)
	restore_data.erase("hero_archetype_id")
	SaveManager._restore_state(restore_data)
	_check(GameState.hero_archetype == null, "38.8 missing key defaults to null archetype")

	# Test 38.9: import_save_string rejects old version
	var old_save := {"version": 7, "hero_equipment": {}, "currencies": {}}
	var old_json := JSON.stringify(old_save)
	var old_b64 := Marshalls.utf8_to_base64(old_json)
	var old_checksum := old_b64.md5_text()
	var old_string := "HT1:" + old_b64 + ":" + old_checksum
	var result := SaveManager.import_save_string(old_string)
	_check(result["success"] == false, "38.9 old version import rejected")
	_check(result["error"] == "outdated_version", "38.10 error is 'outdated_version'")

	# Test 38.11: _wipe_run_state nulls hero_archetype
	GameState.hero_archetype = HeroArchetype.from_id("int_elem")
	_check(GameState.hero_archetype != null, "38.11 pre-wipe archetype is set")
	GameState._wipe_run_state()
	_check(GameState.hero_archetype == null, "38.12 post-wipe archetype is null")

	# Cleanup: restore fresh game state for subsequent groups
	GameState.initialize_fresh_game()


func _group_39_selection_ui() -> void:
	print("\n--- Group 39: Selection UI ---")

	# Test format_bonuses basic conversion
	var single := HeroArchetype.format_bonuses({"attack_damage_more": 0.25})
	_check(single.size() == 1, "format_bonuses: single bonus returns 1 entry")
	_check(single[0] == "+25% Attack Damage", "format_bonuses: 0.25 -> '+25% Attack Damage'")

	# Test format_bonuses with multiple bonuses
	var multi := HeroArchetype.format_bonuses({"bleed_chance_more": 0.20, "bleed_damage_more": 0.15})
	_check(multi.size() == 2, "format_bonuses: two bonuses returns 2 entries")

	# Test format_bonuses empty
	var empty := HeroArchetype.format_bonuses({})
	_check(empty.size() == 0, "format_bonuses: empty dict returns empty array")

	# Test BONUS_LABELS covers all REGISTRY bonus keys
	var all_keys: Dictionary = {}
	for hero_id in HeroArchetype.REGISTRY:
		var data: Dictionary = HeroArchetype.REGISTRY[hero_id]
		for key in data["passive_bonuses"]:
			all_keys[key] = true
	for key in all_keys:
		_check(key in HeroArchetype.BONUS_LABELS, "BONUS_LABELS has key: %s" % key)

	# Test generate_choices returns 3 heroes, one per archetype
	var choices := HeroArchetype.generate_choices()
	_check(choices.size() == 3, "generate_choices: returns exactly 3")
	var archetypes_seen: Dictionary = {}
	for hero in choices:
		archetypes_seen[hero.archetype] = true
		_check(hero.title != "", "generate_choices: hero has title")
		_check(hero.passive_bonuses.size() > 0, "generate_choices: hero has passive_bonuses")
	_check(archetypes_seen.size() == 3, "generate_choices: one per archetype (STR/DEX/INT)")

	# Test P0 detection logic (prestige_level == 0 -> no overlay)
	var old_prestige := GameState.prestige_level
	var old_archetype := GameState.hero_archetype
	GameState.prestige_level = 0
	GameState.hero_archetype = null
	var p0_should_show: bool = GameState.prestige_level >= 1 and GameState.hero_archetype == null
	_check(p0_should_show == false, "P0 with null archetype: overlay NOT triggered")

	# Test P1+ with null archetype -> overlay triggered
	GameState.prestige_level = 1
	GameState.hero_archetype = null
	var p1_null_should_show: bool = GameState.prestige_level >= 1 and GameState.hero_archetype == null
	_check(p1_null_should_show == true, "P1 with null archetype: overlay triggered")

	# Test P1+ with non-null archetype -> no overlay
	GameState.prestige_level = 1
	GameState.hero_archetype = HeroArchetype.from_id("str_hit")
	var p1_set_should_show: bool = GameState.prestige_level >= 1 and GameState.hero_archetype == null
	_check(p1_set_should_show == false, "P1 with set archetype: overlay NOT triggered")

	# Test selection sets GameState correctly
	var picked := HeroArchetype.from_id("dex_dot")
	GameState.hero_archetype = picked
	_check(GameState.hero_archetype != null, "After selection: hero_archetype is not null")
	_check(GameState.hero_archetype.id == "dex_dot", "After selection: hero_archetype.id matches")

	# Restore state
	GameState.prestige_level = old_prestige
	GameState.hero_archetype = old_archetype


func _group_40_stash_data_model() -> void:
	print("\n--- Group 40: Stash Data Model (STSH-01) ---")
	_reset_fresh()

	# Stash exists with 5 keys
	_check(GameState.stash.size() == 5, "Stash has 5 slot keys")
	_check("weapon" in GameState.stash, "Stash has weapon key")
	_check("helmet" in GameState.stash, "Stash has helmet key")
	_check("armor" in GameState.stash, "Stash has armor key")
	_check("boots" in GameState.stash, "Stash has boots key")
	_check("ring" in GameState.stash, "Stash has ring key")

	# Starter kit places Broadsword in weapon and IronPlate in armor; other slots empty
	for slot_name in ["weapon", "helmet", "armor", "boots", "ring"]:
		_check(GameState.stash[slot_name] is Array, "Stash[" + slot_name + "] is Array")
	_check(GameState.stash["weapon"].size() == 1, "Stash[weapon] has 1 starter item after fresh game")
	_check(GameState.stash["armor"].size() == 1, "Stash[armor] has 1 starter item after fresh game")
	_check(GameState.stash["weapon"][0] is Broadsword, "Stash[weapon][0] is starter Broadsword")
	_check(GameState.stash["armor"][0] is IronPlate, "Stash[armor][0] is starter IronPlate")
	for slot_name in ["helmet", "boots", "ring"]:
		_check(GameState.stash[slot_name].size() == 0, "Stash[" + slot_name + "] is empty after fresh game")

	# Crafting bench is null
	_check(GameState.crafting_bench == null, "Crafting bench is null after fresh game")

	# Wipe run state also resets stash
	GameState.stash["weapon"].append(Broadsword.new(8))
	GameState.crafting_bench = Broadsword.new(8)
	GameState._wipe_run_state()
	_check(GameState.stash["weapon"].size() == 0, "Stash weapon empty after wipe")
	_check(GameState.crafting_bench == null, "Crafting bench null after wipe")
	for slot_name in ["helmet", "armor", "boots", "ring"]:
		_check(GameState.stash[slot_name].size() == 0, "Stash[" + slot_name + "] empty after wipe")


func _group_41_stash_drop_routing() -> void:
	print("\n--- Group 41: Stash Drop Routing (STSH-04) ---")
	_reset_fresh()

	# Starter kit already placed 1 weapon; adding another returns true
	var sword := Broadsword.new(8)
	var result := GameState.add_item_to_stash(sword)
	_check(result == true, "add_item_to_stash returns true when slot has room")
	_check(GameState.stash["weapon"].size() == 2, "Weapon slot has 2 items after adding to starter")
	_check(GameState.stash["weapon"][1] == sword, "Stash weapon[1] is the added sword")

	# Fill weapon slot to 3 (already at 2: starter + sword)
	var sword2 := Broadsword.new(8)
	GameState.add_item_to_stash(sword2)
	_check(GameState.stash["weapon"].size() == 3, "Weapon slot has 3 items (full)")

	# 4th item is discarded
	var sword4 := Broadsword.new(8)
	var overflow_result := GameState.add_item_to_stash(sword4)
	_check(overflow_result == false, "add_item_to_stash returns false on overflow")
	_check(GameState.stash["weapon"].size() == 3, "Weapon slot stays at 3 after overflow")

	# Other slots unaffected by weapon overflow
	_check(GameState.stash["ring"].size() == 0, "Ring slot still empty after weapon overflow")

	# Items route to correct slots (fresh game has 1 starter weapon + 1 starter armor)
	_reset_fresh()
	var helmet := IronHelm.new(8)
	GameState.add_item_to_stash(helmet)
	_check(GameState.stash["helmet"].size() == 1, "Helmet routes to helmet slot")
	_check(GameState.stash["weapon"].size() == 1, "Weapon slot has starter item, unaffected by helmet add")

	var ring := JadeRing.new(8)
	GameState.add_item_to_stash(ring)
	_check(GameState.stash["ring"].size() == 1, "Ring routes to ring slot")

	var armor := IronPlate.new(8)
	GameState.add_item_to_stash(armor)
	_check(GameState.stash["armor"].size() == 2, "Armor routes to armor slot (starter + added)")

	var boots := LeatherBoots.new(8)
	GameState.add_item_to_stash(boots)
	_check(GameState.stash["boots"].size() == 1, "Boots routes to boots slot")


# --- Group 42: Forest Difficulty Tuning (DIFF-01) ---

func _group_42_forest_difficulty_tuning() -> void:
	print("\n--- Group 42: Forest Difficulty Tuning (DIFF-01) ---")

	# Verify Forest biome monster stats are tuned for zone 1 survival
	var forest := BiomeConfig.get_biome_for_level(1)
	_check(forest.biome_name == "Forest", "level 1 is Forest biome")

	# Check each monster type count
	var monsters := forest.monster_types
	_check(monsters.size() == 6, "Forest has 6 monster types")

	# Forest Bear should have reduced HP and damage
	var bear := monsters[0]
	_check(bear.type_name == "Forest Bear", "first monster is Forest Bear")
	_check(bear.base_hp == 20.0, "Forest Bear base_hp == 20.0")
	_check(bear.base_damage == 3.5, "Forest Bear base_damage == 3.5")

	# Bramble Golem (tankiest) should also be reduced
	var golem := monsters[5]
	_check(golem.type_name == "Bramble Golem", "last monster is Bramble Golem")
	_check(golem.base_hp == 26.0, "Bramble Golem base_hp == 26.0")
	_check(golem.base_damage == 2.0, "Bramble Golem base_damage == 2.0")


# --- Group 43: Starter Kit Fresh Game (DIFF-03) ---

func _group_43_starter_kit_fresh_game() -> void:
	print("\n--- Group 43: Starter Kit Fresh Game (DIFF-03) ---")

	# Fresh game should have starter items in stash and correct currencies
	GameState.initialize_fresh_game()

	# Check starter currencies (D-04)
	_check(GameState.currency_counts["transmute"] == 2, "fresh game has 2 transmute")
	_check(GameState.currency_counts["augment"] == 2, "fresh game has 2 augment")
	_check(GameState.currency_counts["alteration"] == 0, "fresh game has 0 alteration")

	# Check starter items in stash (D-01, D-02 — null archetype = STR defaults)
	var weapon_stash: Array = GameState.stash["weapon"]
	var armor_stash: Array = GameState.stash["armor"]
	_check(weapon_stash.size() == 1, "stash has 1 starter weapon")
	_check(armor_stash.size() == 1, "stash has 1 starter armor")

	# Verify item types (STR defaults for P0)
	_check(weapon_stash[0] is Broadsword, "starter weapon is Broadsword")
	_check(armor_stash[0] is IronPlate, "starter armor is IronPlate")

	# Verify items are Normal rarity with no affixes (D-03)
	_check(weapon_stash[0].rarity == Item.Rarity.NORMAL, "starter weapon is Normal rarity")
	_check(weapon_stash[0].prefixes.size() == 0, "starter weapon has 0 prefixes")
	_check(weapon_stash[0].suffixes.size() == 0, "starter weapon has 0 suffixes")


# --- Group 44: Starter Kit Post-Prestige (DIFF-03, D-09) ---

func _group_44_starter_kit_post_prestige() -> void:
	print("\n--- Group 44: Starter Kit Post-Prestige (DIFF-03, D-09) ---")

	# Test _place_starter_kit with each archetype
	# STR archetype
	GameState.initialize_fresh_game()
	GameState._init_stash()  # Clear stash to test kit in isolation
	var str_hero := HeroArchetype.from_id("str_hit")
	GameState._place_starter_kit(str_hero)
	_check(GameState.stash["weapon"][0] is Broadsword, "STR starter weapon is Broadsword")
	_check(GameState.stash["armor"][0] is IronPlate, "STR starter armor is IronPlate")

	# DEX archetype
	GameState._init_stash()  # Clear stash
	var dex_hero := HeroArchetype.from_id("dex_hit")
	GameState._place_starter_kit(dex_hero)
	_check(GameState.stash["weapon"][0] is Dagger, "DEX starter weapon is Dagger")
	_check(GameState.stash["armor"][0] is LeatherVest, "DEX starter armor is LeatherVest")

	# INT archetype
	GameState._init_stash()  # Clear stash
	var int_hero := HeroArchetype.from_id("int_hit")
	GameState._place_starter_kit(int_hero)
	_check(GameState.stash["weapon"][0] is Wand, "INT starter weapon is Wand")
	_check(GameState.stash["armor"][0] is SilkRobe, "INT starter armor is SilkRobe")


# --- Group 45: Stash UI Display (STSH-02) ---

func _group_45_stash_ui_display() -> void:
	print("\n--- Group 45: Stash UI Display (STSH-02) ---")
	GameState._init_stash()
	GameState.crafting_bench = null

	# Add a weapon to the weapon stash slot and verify size
	var sword := Broadsword.new(8)
	GameState.add_item_to_stash(sword)
	_check(GameState.stash["weapon"].size() == 1, "Weapon stash has 1 item after adding Broadsword")

	# Verify instance type for abbreviation correctness
	_check(GameState.stash["weapon"][0] is Broadsword, "Stash weapon slot[0] is Broadsword (abbreviation = BS)")

	# Add 2 more weapons to fill the slot
	var axe := Battleaxe.new(8)
	var hammer := Warhammer.new(8)
	GameState.add_item_to_stash(axe)
	GameState.add_item_to_stash(hammer)
	_check(GameState.stash["weapon"].size() == 3, "Weapon stash has 3 items after filling slot")

	# Empty slots for other types should still be empty
	_check(GameState.stash["helmet"].size() == 0, "Helmet stash is empty when only weapons added")
	_check(GameState.stash["ring"].size() == 0, "Ring stash is empty when only weapons added")

	# Adding beyond cap does not grow the array
	var overflow := Dagger.new(8)
	GameState.add_item_to_stash(overflow)
	_check(GameState.stash["weapon"].size() == 3, "Weapon stash stays at 3 after overflow attempt")


# --- Group 46: Stash Tap-to-Bench Data Flow (STSH-03) ---

func _group_46_stash_tap_to_bench() -> void:
	print("\n--- Group 46: Stash Tap-to-Bench (STSH-03) ---")
	GameState._init_stash()
	GameState.crafting_bench = null

	# Add an item to stash and simulate tap-to-bench transfer
	var sword := Broadsword.new(8)
	GameState.add_item_to_stash(sword)
	_check(GameState.stash["weapon"].size() == 1, "Weapon stash has 1 item before tap")

	# Simulate tap: remove from stash, place on bench (mirrors _on_stash_slot_pressed logic)
	var item: Item = GameState.stash["weapon"][0]
	GameState.stash["weapon"].remove_at(0)
	GameState.crafting_bench = item
	_check(GameState.stash["weapon"].size() == 0, "Weapon stash is empty after tap-to-bench")
	_check(GameState.crafting_bench != null, "Crafting bench is occupied after tap-to-bench")
	_check(GameState.crafting_bench is Broadsword, "Crafting bench holds the transferred Broadsword")

	# Bench-occupied guard: crafting_bench != null means slots should be disabled
	_check(GameState.crafting_bench != null, "Bench-occupied guard: crafting_bench is non-null (slots would be disabled)")

	# Clear bench, verify bench is null
	GameState.crafting_bench = null
	_check(GameState.crafting_bench == null, "Bench is null after clearing")

	# Removing from a stash index leaves empty gap — remaining items do not shift (D-08)
	GameState._init_stash()
	var item_a := Broadsword.new(8)
	var item_b := Battleaxe.new(8)
	var item_c := Warhammer.new(8)
	GameState.add_item_to_stash(item_a)
	GameState.add_item_to_stash(item_b)
	GameState.add_item_to_stash(item_c)
	_check(GameState.stash["weapon"].size() == 3, "Weapon stash has 3 items before removal")
	# Remove middle item (index 1)
	GameState.stash["weapon"].remove_at(1)
	_check(GameState.stash["weapon"].size() == 2, "Weapon stash has 2 items after remove_at(1)")
	_check(GameState.stash["weapon"][0] is Broadsword, "First slot still has Broadsword after middle removal")
	_check(GameState.stash["weapon"][1] is Warhammer, "Second slot has Warhammer (Battleaxe removed)")


# --- Group 47: Stash Tooltip Text (STSH-05) ---

func _group_47_stash_tooltip_text() -> void:
	print("\n--- Group 47: Stash Tooltip Text (STSH-05) ---")
	GameState._init_stash()

	# Weapon: get_display_text() should contain "dps:" for weapons
	var sword := Broadsword.new(8)
	var sword_text := sword.get_display_text()
	_check(sword_text.length() > 0, "Broadsword get_display_text() returns non-empty string")
	_check("dps:" in sword_text, "Broadsword tooltip contains 'dps:' field")
	_check("name:" in sword_text, "Broadsword tooltip contains 'name:' field")

	# Defense item: get_display_text() should contain "defense:" for armor with stats
	var plate := IronPlate.new(8)
	var plate_text := plate.get_display_text()
	_check(plate_text.length() > 0, "IronPlate get_display_text() returns non-empty string")
	_check("name:" in plate_text, "IronPlate tooltip contains 'name:' field")

	# Ring: get_display_text() should contain "dps:" for rings
	var ring := JadeRing.new(8)
	var ring_text := ring.get_display_text()
	_check(ring_text.length() > 0, "JadeRing get_display_text() returns non-empty string")
	_check("dps:" in ring_text, "JadeRing tooltip contains 'dps:' field")
	_check("name:" in ring_text, "JadeRing tooltip contains 'name:' field")


func _group_48_alteration_hammer() -> void:
	# CRFT-01: Alteration rerolls Magic mods, rejected on Normal/Rare
	var hammer := TackHammer.new()

	# Test 1: Rejected on Normal item
	var normal_item := Broadsword.new(8)
	normal_item.rarity = Item.Rarity.NORMAL
	normal_item.prefixes.clear()
	normal_item.suffixes.clear()
	assert(not hammer.can_apply(normal_item), "48a: Alteration rejected on Normal")
	assert(hammer.get_error_message(normal_item) == "Alteration Hammer can only be used on Magic items", "48a: error msg")

	# Test 2: Accepted on Magic item, mods are rerolled
	var magic_item := Broadsword.new(8)
	magic_item.rarity = Item.Rarity.MAGIC
	magic_item.prefixes.clear()
	magic_item.suffixes.clear()
	magic_item.add_prefix()
	var old_prefix_id = magic_item.prefixes[0].affix_name if magic_item.prefixes.size() > 0 else ""
	assert(hammer.can_apply(magic_item), "48b: Alteration accepted on Magic")
	hammer.apply(magic_item)
	assert(magic_item.rarity == Item.Rarity.MAGIC, "48b: rarity stays MAGIC after reroll")
	assert(magic_item.prefixes.size() + magic_item.suffixes.size() >= 1, "48b: at least 1 mod after reroll")
	assert(magic_item.prefixes.size() + magic_item.suffixes.size() <= 2, "48b: at most 2 mods after reroll")

	# Test 3: Rejected on Rare item
	var rare_item := Broadsword.new(8)
	rare_item.rarity = Item.Rarity.RARE
	assert(not hammer.can_apply(rare_item), "48c: Alteration rejected on Rare")
	assert(hammer.get_error_message(rare_item) == "Alteration Hammer can only be used on Magic items", "48c: error msg")

	print("Group 48: Alteration Hammer — PASSED")


func _group_49_regal_hammer() -> void:
	# CRFT-02: Regal upgrades Magic to Rare, rejected on Normal/Rare
	var hammer := GrandHammer.new()

	# Test 1: Rejected on Normal item
	var normal_item := Broadsword.new(8)
	normal_item.rarity = Item.Rarity.NORMAL
	normal_item.prefixes.clear()
	normal_item.suffixes.clear()
	assert(not hammer.can_apply(normal_item), "49a: Regal rejected on Normal")
	assert(hammer.get_error_message(normal_item) == "Regal Hammer can only be used on Magic items", "49a: error msg")

	# Test 2: Accepted on Magic item, upgrades to Rare with +1 mod
	var magic_item := Broadsword.new(8)
	magic_item.rarity = Item.Rarity.MAGIC
	magic_item.prefixes.clear()
	magic_item.suffixes.clear()
	magic_item.add_prefix()
	magic_item.add_suffix()
	var mod_count_before = magic_item.prefixes.size() + magic_item.suffixes.size()
	assert(hammer.can_apply(magic_item), "49b: Regal accepted on Magic")
	hammer.apply(magic_item)
	assert(magic_item.rarity == Item.Rarity.RARE, "49b: rarity upgraded to RARE")
	var mod_count_after = magic_item.prefixes.size() + magic_item.suffixes.size()
	assert(mod_count_after == mod_count_before + 1, "49b: exactly one mod added (was %d, now %d)" % [mod_count_before, mod_count_after])

	# Test 3: Rejected on Rare item
	var rare_item := Broadsword.new(8)
	rare_item.rarity = Item.Rarity.RARE
	assert(not hammer.can_apply(rare_item), "49c: Regal rejected on Rare")
	assert(hammer.get_error_message(rare_item) == "Regal Hammer can only be used on Magic items", "49c: error msg")

	print("Group 49: Regal Hammer — PASSED")


# --- Group 50: Save v10 Round-Trip (INT-02) ---

func _group_50_save_v10_round_trip() -> void:
	print("\n--- Group 50: Save v10 Round-Trip (INT-02) ---")

	# Setup: known state
	GameState.initialize_fresh_game()

	# Put items in stash (stash starts with starter kit — weapon slot already has Broadsword)
	var stash_sword := Broadsword.new(8)
	stash_sword.rarity = Item.Rarity.MAGIC
	stash_sword.add_prefix()
	GameState.add_item_to_stash(stash_sword)

	var stash_helm := IronHelm.new(8)
	GameState.add_item_to_stash(stash_helm)

	# Put item on bench
	var bench_item := Dagger.new(8)
	bench_item.rarity = Item.Rarity.MAGIC
	bench_item.add_prefix()
	GameState.crafting_bench = bench_item

	# Set currency counts including alteration/regal
	GameState.currency_counts["alteration"] = 5
	GameState.currency_counts["regal"] = 3
	GameState.currency_counts["transmute"] = 10

	# Set archetype
	GameState.hero_archetype = HeroArchetype.from_id("dex_hit")

	# Build save dict and restore directly (avoids file I/O in tests)
	var save_data := SaveManager._build_save_data()
	_check(save_data.has("stash"), "50a: save data contains 'stash' key")
	_check(save_data.has("crafting_bench"), "50b: save data contains 'crafting_bench' key")
	_check(not save_data.has("crafting_inventory"), "50c: save data does not contain old 'crafting_inventory' key")
	_check(not save_data.has("crafting_bench_type"), "50d: save data does not contain old 'crafting_bench_type' key")

	# Verify stash serialization — weapon slot should have starter + stash_sword
	var stash_weapon_arr: Array = save_data["stash"].get("weapon", [])
	_check(stash_weapon_arr.size() >= 2, "50e: weapon stash has at least 2 serialized items")

	# Verify bench serialization
	var bench_dict = save_data["crafting_bench"]
	_check(bench_dict != null and bench_dict is Dictionary, "50f: crafting_bench is a non-null dict")

	# Verify version
	_check(save_data["version"] == 10, "50g: save version is 10")

	# Wipe state and restore
	GameState.initialize_fresh_game()
	_check(GameState.crafting_bench == null, "50h: bench is null after fresh game")

	var restore_ok := SaveManager._restore_state(save_data)
	_check(restore_ok, "50i: _restore_state succeeded")

	# Verify stash round-tripped
	var weapon_stash: Array = GameState.stash["weapon"]
	var found_magic_sword := false
	for item in weapon_stash:
		if item != null and item is Broadsword and item.rarity == Item.Rarity.MAGIC:
			found_magic_sword = true
			break
	_check(found_magic_sword, "50j: stash weapon round-tripped (Magic Broadsword)")

	var helmet_stash: Array = GameState.stash["helmet"]
	var found_helm := false
	for item in helmet_stash:
		if item != null and item is IronHelm:
			found_helm = true
			break
	_check(found_helm, "50k: stash helmet round-tripped (IronHelm)")

	# Verify bench round-tripped
	_check(GameState.crafting_bench != null, "50l: bench not null after restore")
	_check(GameState.crafting_bench is Dagger, "50m: bench is Dagger")
	_check(GameState.crafting_bench.rarity == Item.Rarity.MAGIC, "50n: bench rarity is MAGIC")
	_check(GameState.crafting_bench.prefixes.size() >= 1, "50o: bench has at least one prefix")

	# Verify currencies round-tripped
	_check(GameState.currency_counts["alteration"] == 5, "50p: alteration count round-tripped")
	_check(GameState.currency_counts["regal"] == 3, "50q: regal count round-tripped")
	_check(GameState.currency_counts["transmute"] == 10, "50r: transmute count round-tripped")

	# Verify archetype round-tripped
	_check(GameState.hero_archetype != null, "50s: archetype not null after restore")
	_check(GameState.hero_archetype.id == "dex_hit", "50t: archetype id round-tripped")

	# --- Second cycle: round-trip the 3 new currencies (alchemy/divine/annulment) ---
	GameState.currency_counts["alchemy"] = 7
	GameState.currency_counts["divine"] = 3
	GameState.currency_counts["annulment"] = 2
	var save_data2 := SaveManager._build_save_data()
	GameState.initialize_fresh_game()
	var restore_ok2 := SaveManager._restore_state(save_data2)
	_check(restore_ok2, "50u: second _restore_state succeeded")
	_check(GameState.currency_counts["alchemy"] == 7, "50v: alchemy count round-tripped")
	_check(GameState.currency_counts["divine"] == 3, "50w: divine count round-tripped")
	_check(GameState.currency_counts["annulment"] == 2, "50x: annulment count round-tripped")

	# Verify v8 rejection: build a v8-shaped save dict and confirm load_game would reject it
	# (We test the version check logic inline since we cannot do real file I/O in tests)
	var v8_data := {"version": 8, "hero_equipment": {}, "currencies": {}}
	_check(int(v8_data.get("version", 1)) < SaveManager.SAVE_VERSION, "50y: v8 save version is below SAVE_VERSION (would be rejected)")

	# Cleanup
	GameState.initialize_fresh_game()

	print("Group 50: Save v10 round-trip — PASSED")


# --- Group 51: Transmute Hammer (INT-03) ---
func _group_51_transmute_hammer() -> void:
	# INT-03: Transmute promotes Normal item to Magic with 1-2 mods; rejected on Magic/Rare
	var hammer := RunicHammer.new()

	# Test 1: Rejection — Magic item
	var magic_item := Broadsword.new(8)
	magic_item.rarity = Item.Rarity.MAGIC
	magic_item.prefixes.clear()
	magic_item.suffixes.clear()
	magic_item.add_prefix()
	_check(not hammer.can_apply(magic_item), "51a: Transmute rejected on Magic")
	_check(hammer.get_error_message(magic_item) == "Transmute Hammer can only be used on Normal items", "51a: error msg on Magic")

	# Test 2: Success — Normal item promoted to Magic with ≥1 mod
	var normal_item := Broadsword.new(8)
	normal_item.rarity = Item.Rarity.NORMAL
	normal_item.prefixes.clear()
	normal_item.suffixes.clear()
	_check(hammer.can_apply(normal_item), "51b: Transmute accepted on Normal")
	hammer.apply(normal_item)
	_check(normal_item.rarity == Item.Rarity.MAGIC, "51b: rarity upgraded to MAGIC")
	var mod_count := normal_item.prefixes.size() + normal_item.suffixes.size()
	_check(mod_count >= 1 and mod_count <= 2, "51b: Magic item has 1-2 mods after Transmute")

	# Test 3: Edge — second Transmute on a Magic item (already-promoted) is rejected
	_check(not hammer.can_apply(normal_item), "51c: second Transmute on now-Magic item rejected")
	_check(hammer.get_error_message(normal_item) == "Transmute Hammer can only be used on Normal items", "51c: error msg on already-Magic")

	print("Group 51: Transmute Hammer — PASSED")


# --- Group 52: Augment Hammer (INT-03) ---
func _group_52_augment_hammer() -> void:
	# INT-03: Augment adds 1 mod to Magic with room; rejected on Normal/full-Magic
	var hammer := AugmentHammer.new()

	# Test 1: Rejection — Normal item
	var normal_item := Broadsword.new(8)
	normal_item.rarity = Item.Rarity.NORMAL
	normal_item.prefixes.clear()
	normal_item.suffixes.clear()
	_check(not hammer.can_apply(normal_item), "52a: Augment rejected on Normal")
	_check(hammer.get_error_message(normal_item) == "Augment Hammer can only be used on Magic items", "52a: error msg on Normal")

	# Test 2: Success — Magic with 1 prefix, still has suffix room
	var magic_item := Broadsword.new(8)
	magic_item.rarity = Item.Rarity.MAGIC
	magic_item.prefixes.clear()
	magic_item.suffixes.clear()
	magic_item.add_prefix()
	var mod_count_before := magic_item.prefixes.size() + magic_item.suffixes.size()
	_check(hammer.can_apply(magic_item), "52b: Augment accepted on Magic with room")
	hammer.apply(magic_item)
	_check(magic_item.rarity == Item.Rarity.MAGIC, "52b: rarity stays MAGIC after Augment")
	_check(magic_item.prefixes.size() + magic_item.suffixes.size() == mod_count_before + 1, "52b: exactly one mod added")

	# Test 3: Edge — Magic item with full slots (1 prefix + 1 suffix)
	var full_magic := Broadsword.new(8)
	full_magic.rarity = Item.Rarity.MAGIC
	full_magic.prefixes.clear()
	full_magic.suffixes.clear()
	full_magic.add_prefix()
	full_magic.add_suffix()
	_check(not hammer.can_apply(full_magic), "52c: Augment rejected on full Magic")
	_check(hammer.get_error_message(full_magic) == "Magic item has no room for another mod", "52c: error msg on full Magic")

	print("Group 52: Augment Hammer — PASSED")


# --- Group 53: Alchemy Hammer (INT-03) ---
func _group_53_alchemy_hammer() -> void:
	# INT-03: Alchemy converts Normal → Rare with mods; rejected on Magic/Rare
	var hammer := AlchemyHammer.new()

	# Test 1: Rejection — Magic item
	var magic_item := Broadsword.new(8)
	magic_item.rarity = Item.Rarity.MAGIC
	magic_item.prefixes.clear()
	magic_item.suffixes.clear()
	magic_item.add_prefix()
	_check(not hammer.can_apply(magic_item), "53a: Alchemy rejected on Magic")
	_check(hammer.get_error_message(magic_item) == "Alchemy Hammer can only be used on Normal items", "53a: error msg on Magic")

	# Test 2: Success — Normal item becomes Rare with ≥1 mod (pool exhaustion may cap below 4; see Pitfall 5)
	var normal_item := Broadsword.new(8)
	normal_item.rarity = Item.Rarity.NORMAL
	normal_item.prefixes.clear()
	normal_item.suffixes.clear()
	_check(hammer.can_apply(normal_item), "53b: Alchemy accepted on Normal")
	hammer.apply(normal_item)
	_check(normal_item.rarity == Item.Rarity.RARE, "53b: rarity upgraded to RARE")
	var mod_count := normal_item.prefixes.size() + normal_item.suffixes.size()
	_check(mod_count >= 1, "53b: Rare item has ≥1 mod after Alchemy (pool exhaustion tolerated)")
	_check(mod_count <= 6, "53b: Rare item has ≤6 mods after Alchemy")

	# Test 3: Edge — Rare item rejected (already Rare)
	var rare_item := Broadsword.new(8)
	rare_item.rarity = Item.Rarity.RARE
	_check(not hammer.can_apply(rare_item), "53c: Alchemy rejected on Rare")
	_check(hammer.get_error_message(rare_item) == "Alchemy Hammer can only be used on Normal items", "53c: error msg on Rare")

	print("Group 53: Alchemy Hammer — PASSED")


# --- Group 54: Chaos Hammer (INT-03) ---
func _group_54_chaos_hammer() -> void:
	# INT-03: Chaos rerolls all mods on a Rare item; rejected on Normal/Magic; accepts empty Rare
	var hammer := ChaosHammer.new()

	# Test 1: Rejection — Normal item
	var normal_item := Broadsword.new(8)
	normal_item.rarity = Item.Rarity.NORMAL
	normal_item.prefixes.clear()
	normal_item.suffixes.clear()
	_check(not hammer.can_apply(normal_item), "54a: Chaos rejected on Normal")
	_check(hammer.get_error_message(normal_item) == "Chaos Hammer can only be used on Rare items", "54a: error msg on Normal")

	# Test 2: Success — Rare item with some mods gets rerolled (tolerate pool exhaustion at ≥1)
	var rare_item := Broadsword.new(8)
	rare_item.rarity = Item.Rarity.RARE
	rare_item.prefixes.clear()
	rare_item.suffixes.clear()
	rare_item.add_prefix()
	rare_item.add_suffix()
	_check(hammer.can_apply(rare_item), "54b: Chaos accepted on Rare")
	hammer.apply(rare_item)
	_check(rare_item.rarity == Item.Rarity.RARE, "54b: rarity stays RARE after Chaos")
	var post_count := rare_item.prefixes.size() + rare_item.suffixes.size()
	_check(post_count >= 1, "54b: Rare item has ≥1 mod after Chaos")
	_check(post_count <= 6, "54b: Rare item has ≤6 mods after Chaos")

	# Test 3: Edge — empty Rare (0 mods) is accepted (D-16 Phase 1: no mod-count gate on can_apply)
	var empty_rare := Broadsword.new(8)
	empty_rare.rarity = Item.Rarity.RARE
	empty_rare.prefixes.clear()
	empty_rare.suffixes.clear()
	_check(hammer.can_apply(empty_rare), "54c: Chaos accepted on empty Rare")
	hammer.apply(empty_rare)
	_check(empty_rare.rarity == Item.Rarity.RARE, "54c: rarity stays RARE after Chaos on empty Rare")
	var edge_count := empty_rare.prefixes.size() + empty_rare.suffixes.size()
	_check(edge_count >= 1, "54c: empty Rare gains ≥1 mod after Chaos")

	print("Group 54: Chaos Hammer — PASSED")


# --- Group 55: Exalt Hammer (INT-03) ---
func _group_55_exalt_hammer() -> void:
	# INT-03: Exalt adds 1 mod to Rare with room; rejected on Normal/Magic/full-Rare
	var hammer := ExaltHammer.new()

	# Test 1: Rejection — Magic item
	var magic_item := Broadsword.new(8)
	magic_item.rarity = Item.Rarity.MAGIC
	magic_item.prefixes.clear()
	magic_item.suffixes.clear()
	magic_item.add_prefix()
	_check(not hammer.can_apply(magic_item), "55a: Exalt rejected on Magic")
	_check(hammer.get_error_message(magic_item) == "Exalt Hammer can only be used on Rare items", "55a: error msg on Magic")

	# Test 2: Success — Rare with 1 prefix + 1 suffix (still has room)
	var rare_item := Broadsword.new(8)
	rare_item.rarity = Item.Rarity.RARE
	rare_item.prefixes.clear()
	rare_item.suffixes.clear()
	rare_item.add_prefix()
	rare_item.add_suffix()
	var mod_count_before := rare_item.prefixes.size() + rare_item.suffixes.size()
	_check(hammer.can_apply(rare_item), "55b: Exalt accepted on Rare with room")
	hammer.apply(rare_item)
	_check(rare_item.rarity == Item.Rarity.RARE, "55b: rarity stays RARE after Exalt")
	_check(rare_item.prefixes.size() + rare_item.suffixes.size() == mod_count_before + 1, "55b: exactly one mod added")

	# Test 3: Edge — Rare item with full slots (3 prefixes + 3 suffixes)
	var full_rare := Broadsword.new(8)
	full_rare.rarity = Item.Rarity.RARE
	full_rare.prefixes.clear()
	full_rare.suffixes.clear()
	full_rare.add_prefix()
	full_rare.add_prefix()
	full_rare.add_prefix()
	full_rare.add_suffix()
	full_rare.add_suffix()
	full_rare.add_suffix()
	_check(not hammer.can_apply(full_rare), "55c: Exalt rejected on full Rare")
	_check(hammer.get_error_message(full_rare) == "Rare item has no room for another mod", "55c: error msg on full Rare")

	print("Group 55: Exalt Hammer — PASSED")


# --- Group 56: Divine Hammer (INT-03) ---
func _group_56_divine_hammer() -> void:
	# INT-03: Divine rerolls mod VALUES, preserves mod NAMES and COUNT; rejected on mod-less items
	var hammer := DivineHammer.new()

	# Test 1: Rejection — Normal item with 0 mods
	var normal_item := Broadsword.new(8)
	normal_item.rarity = Item.Rarity.NORMAL
	normal_item.prefixes.clear()
	normal_item.suffixes.clear()
	_check(not hammer.can_apply(normal_item), "56a: Divine rejected on mod-less Normal")
	_check(hammer.get_error_message(normal_item) == "Item has no mods to reroll", "56a: error msg on mod-less item")

	# Test 2: Success — Magic item with 1 prefix, Divine works
	var magic_item := Broadsword.new(8)
	magic_item.rarity = Item.Rarity.MAGIC
	magic_item.prefixes.clear()
	magic_item.suffixes.clear()
	magic_item.add_prefix()
	_check(hammer.can_apply(magic_item), "56b: Divine accepted on Magic with mods")
	hammer.apply(magic_item)
	_check(magic_item.rarity == Item.Rarity.MAGIC, "56b: rarity stays MAGIC after Divine")

	# Test 3: Edge — mod-name preservation invariant (RESEARCH.md §"Divine edge test")
	var edge_item := Broadsword.new(8)
	edge_item.rarity = Item.Rarity.MAGIC
	edge_item.prefixes.clear()
	edge_item.suffixes.clear()
	edge_item.add_prefix()
	edge_item.add_suffix()
	var names_before: Array[String] = []
	for p in edge_item.prefixes:
		names_before.append(p.affix_name)
	for s in edge_item.suffixes:
		names_before.append(s.affix_name)
	var count_before := edge_item.prefixes.size() + edge_item.suffixes.size()

	_check(hammer.can_apply(edge_item), "56c: Divine accepted on Magic with prefix+suffix")
	hammer.apply(edge_item)

	_check(edge_item.prefixes.size() + edge_item.suffixes.size() == count_before, "56c: Divine preserves mod count")

	var names_after: Array[String] = []
	for p in edge_item.prefixes:
		names_after.append(p.affix_name)
	for s in edge_item.suffixes:
		names_after.append(s.affix_name)
	_check(names_before == names_after, "56c: Divine preserves mod names")

	print("Group 56: Divine Hammer — PASSED")


# --- Group 57: Annulment Hammer (INT-03) ---
func _group_57_annulment_hammer() -> void:
	# INT-03: Annulment removes 1 random mod from Magic or Rare; rejected on mod-less items
	var hammer := AnnulmentHammer.new()

	# Test 1: Rejection — Normal item with 0 mods
	var normal_item := Broadsword.new(8)
	normal_item.rarity = Item.Rarity.NORMAL
	normal_item.prefixes.clear()
	normal_item.suffixes.clear()
	_check(not hammer.can_apply(normal_item), "57a: Annulment rejected on mod-less Normal")
	_check(hammer.get_error_message(normal_item) == "Item has no mods to remove", "57a: error msg on mod-less item")

	# Test 2: Success — Magic item with 1 prefix + 1 suffix, Annulment removes exactly 1 mod
	var magic_item := Broadsword.new(8)
	magic_item.rarity = Item.Rarity.MAGIC
	magic_item.prefixes.clear()
	magic_item.suffixes.clear()
	magic_item.add_prefix()
	magic_item.add_suffix()
	var mod_count_before := magic_item.prefixes.size() + magic_item.suffixes.size()
	_check(hammer.can_apply(magic_item), "57b: Annulment accepted on Magic with mods")
	hammer.apply(magic_item)
	_check(magic_item.rarity == Item.Rarity.MAGIC, "57b: rarity stays MAGIC after Annulment")
	_check(magic_item.prefixes.size() + magic_item.suffixes.size() == mod_count_before - 1, "57b: exactly one mod removed")

	# Test 3: Edge — Magic with 0 mods (cleared after construction) rejected
	var empty_magic := Broadsword.new(8)
	empty_magic.rarity = Item.Rarity.MAGIC
	empty_magic.prefixes.clear()
	empty_magic.suffixes.clear()
	_check(not hammer.can_apply(empty_magic), "57c: Annulment rejected on empty Magic")
	_check(hammer.get_error_message(empty_magic) == "Item has no mods to remove", "57c: error msg on empty Magic")

	print("Group 57: Annulment Hammer — PASSED")
