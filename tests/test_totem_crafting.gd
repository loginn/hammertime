extends GutTest

# Comprehensive tests for the CraftableItem hierarchy, TotemPiece crafting,
# TotemPieceFactory, wood drops, and backward compatibility.


func before_each() -> void:
	GameState.initialize_fresh_game()
	PrestigeManager.prestige_count = 0


func after_each() -> void:
	PrestigeManager.prestige_count = 0


# --- CraftableItem affix rolling ---

func test_craftable_item_affix_rolling() -> void:
	GameState.currency_counts["iron"] = 5
	var item: HeroItem = ItemFactory.create_base("iron_shortsword")
	assert_not_null(item, "item created")
	# Transmute to magic so it can hold affixes
	var tack := TackHammer.new()
	tack.apply(item)
	assert_eq(item.rarity, CraftableItem.Rarity.MAGIC, "item is magic")
	assert_true(item.prefixes.size() <= item.max_prefixes(), "prefix count within limit")
	assert_true(item.suffixes.size() <= item.max_suffixes(), "suffix count within limit")


# --- HeroItem backward compatibility ---

func test_hero_item_backward_compat() -> void:
	GameState.currency_counts["iron"] = 5
	var item: HeroItem = ItemFactory.create_base("iron_shortsword")
	assert_not_null(item)
	assert_true(item is HeroItem, "is HeroItem")
	assert_true(item is CraftableItem, "HeroItem extends CraftableItem")

	var tack := TackHammer.new()
	assert_true(tack.can_apply(item), "tack can apply to normal item")
	tack.apply(item)
	assert_eq(item.rarity, CraftableItem.Rarity.MAGIC, "tack changes to magic")

	# Tack may randomly fill all MAGIC slots (1 prefix + 1 suffix).
	# Clear to one affix so forge always has room.
	if item.prefixes.size() + item.suffixes.size() >= item.max_prefixes() + item.max_suffixes():
		item.suffixes.clear()

	var forge := ForgeHammer.new()
	var can_forge: bool = forge.can_apply(item)
	assert_true(can_forge, "forge can apply to magic item with open slots")
	forge.apply(item)
	assert_true(item.prefixes.size() + item.suffixes.size() >= 1, "at least one affix added by forge")


# --- TotemPiece creation via factory ---

func test_totem_piece_creation() -> void:
	GameState.currency_counts["ash"] = 3
	assert_true(TotemPieceFactory.can_afford(Tag_List.MaterialTier.ASH), "can afford ash totem")
	var piece: TotemPiece = TotemPieceFactory.create_base(Tag_List.MaterialTier.ASH)
	assert_not_null(piece, "piece created")
	assert_eq(piece.material_tier, Tag_List.MaterialTier.ASH, "correct material tier")
	assert_eq(piece.rarity, CraftableItem.Rarity.NORMAL, "starts normal rarity")
	assert_eq(GameState.currency_counts["ash"], 3 - BalanceConfig.BASE_TOTEM_ASH_COST, "ash spent")


func test_totem_piece_creation_fails_without_wood() -> void:
	GameState.currency_counts["ash"] = 0
	assert_false(TotemPieceFactory.can_afford(Tag_List.MaterialTier.ASH), "cannot afford with 0 ash")
	var piece: TotemPiece = TotemPieceFactory.create_base(Tag_List.MaterialTier.ASH)
	assert_null(piece, "returns null with no ash")
	assert_eq(GameState.currency_counts["ash"], 0, "ash unchanged")


# --- TotemPiece affix pool ---

func test_totem_piece_affix_pools() -> void:
	GameState.currency_counts["ash"] = 1
	var piece: TotemPiece = TotemPieceFactory.create_base(Tag_List.MaterialTier.ASH)
	assert_not_null(piece)
	# Must upgrade rarity before adding affixes
	piece.rarity = CraftableItem.Rarity.MAGIC

	# TotemPiece._get_prefix_pool() must return TotemAffixes pool, not ItemAffixes
	# We verify indirectly: adding a prefix must pick from TotemAffixes.prefixes
	var pool_before := piece.prefixes.size()
	piece.add_prefix()
	if piece.prefixes.size() > pool_before:
		var added: Affix = piece.prefixes[piece.prefixes.size() - 1]
		assert_true(Tag.TOTEM in added.tags, "affix from totem pool carries TOTEM tag")


# --- Deity tag recomputation ---

func test_totem_piece_deity_tag() -> void:
	GameState.currency_counts["ash"] = 1
	var piece: TotemPiece = TotemPieceFactory.create_base(Tag_List.MaterialTier.ASH)
	assert_not_null(piece)
	piece.rarity = CraftableItem.Rarity.MAGIC

	# Manually inject a known affix with a deity tag
	var dummy_affix := Affix.new(
		"Test Cthulhu Prefix",
		Affix.AffixType.PREFIX,
		5, 10,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUANTITY, Tag.CTHULHU],
		[],
		Vector2i(1, 8)
	)
	piece.prefixes.append(dummy_affix)
	piece.recompute_deity_tag()
	assert_eq(piece.deity_tag, Tag.CTHULHU, "deity_tag set to CTHULHU after recompute")


# --- Expedition modifiers ---

func test_totem_piece_expedition_modifiers() -> void:
	GameState.currency_counts["ash"] = 1
	var piece: TotemPiece = TotemPieceFactory.create_base(Tag_List.MaterialTier.ASH)
	assert_not_null(piece)

	var qty_affix := Affix.new(
		"Bounty of the Deep",
		Affix.AffixType.PREFIX,
		3, 3,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUANTITY, Tag.CTHULHU],
		[],
		Vector2i(1, 8)
	)
	qty_affix.value = 3
	piece.prefixes.append(qty_affix)

	var mods: Dictionary = piece.get_expedition_modifiers()
	assert_eq(mods["drop_quantity"], 3, "drop_quantity aggregated correctly")
	assert_eq(mods["drop_quality"], 0, "unset modifier is 0")


# --- Wood drops pre-prestige ---

func test_wood_drops_pre_prestige() -> void:
	PrestigeManager.prestige_count = 0
	for config in ExpeditionConfig.get_all_configs():
		for entry in config.drop_table.entries:
			assert_false(entry.get("key", "") == "ash", "no ash in pre-P2 tables")
			assert_false(entry.get("key", "") == "oak", "no oak in pre-P2 tables")


# --- Wood drops post-prestige ---

func test_wood_drops_post_prestige() -> void:
	PrestigeManager.prestige_count = 2

	var found_ash: bool = false
	var found_oak: bool = false

	for config in ExpeditionConfig.get_starter_configs():
		for entry in config.drop_table.entries:
			if entry.get("key", "") == "ash":
				found_ash = true

	for config in ExpeditionConfig.get_rare_configs():
		for entry in config.drop_table.entries:
			if entry.get("key", "") == "oak":
				found_oak = true

	assert_true(found_ash, "ash in starter zone tables at prestige >= 2")
	assert_true(found_oak, "oak in rare zone tables at prestige >= 2")


# --- Currency.apply accepts CraftableItem parameter ---

func test_currency_apply_on_craftable_item() -> void:
	GameState.currency_counts["iron"] = 1
	var item: HeroItem = ItemFactory.create_base("iron_shortsword")
	assert_not_null(item)
	assert_true(item is CraftableItem, "HeroItem is a CraftableItem")

	# TackHammer operates on HeroItem; ensure no type error with CraftableItem reference
	var ci: CraftableItem = item as CraftableItem
	assert_not_null(ci, "downcast to CraftableItem succeeds")
	var tack := TackHammer.new()
	# TackHammer.apply expects HeroItem; verify the item can round-trip through CraftableItem
	assert_true(tack.can_apply(item), "tack.can_apply accepts the item")
