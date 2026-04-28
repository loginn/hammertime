extends GutTest

# GUT tests for TotemGrid: 2x2 slot management, synergy detection, and effective modifiers.


func _make_totem(deity: String) -> TotemPiece:
	var piece := TotemPiece.new()
	piece.deity_tag = deity
	return piece


func before_each() -> void:
	pass


# --- Empty grid ---

func test_empty_grid_no_synergies() -> void:
	var grid := TotemGrid.new()
	assert_eq(grid.compute_synergies().size(), 0, "no synergies on empty grid")


# --- Placement ---

func test_place_piece_in_valid_slot() -> void:
	var grid := TotemGrid.new()
	var piece := _make_totem("cthulhu")
	var ok := grid.place_piece(Vector2i(0, 0), piece)
	assert_true(ok, "place succeeds in valid empty slot")
	assert_eq(grid.get_piece(Vector2i(0, 0)), piece, "piece retrievable")


func test_place_piece_in_occupied_slot_fails() -> void:
	var grid := TotemGrid.new()
	var piece_a := _make_totem("cthulhu")
	var piece_b := _make_totem("hastur")
	grid.place_piece(Vector2i(0, 0), piece_a)
	var ok := grid.place_piece(Vector2i(0, 0), piece_b)
	assert_false(ok, "cannot place in occupied slot")
	assert_eq(grid.get_piece(Vector2i(0, 0)), piece_a, "original piece unchanged")


func test_place_piece_in_invalid_position_fails() -> void:
	var grid := TotemGrid.new()
	var piece := _make_totem("cthulhu")
	var ok := grid.place_piece(Vector2i(3, 3), piece)
	assert_false(ok, "position outside 2x2 is invalid")


# --- Synergy detection ---

func test_adjacent_matching_deity_produces_synergy() -> void:
	var grid := TotemGrid.new()
	grid.place_piece(Vector2i(0, 0), _make_totem("cthulhu"))
	grid.place_piece(Vector2i(1, 0), _make_totem("cthulhu"))
	var synergies := grid.compute_synergies()
	assert_eq(synergies.size(), 1, "one synergy pair")
	assert_eq(synergies[0]["deity_tag"], "cthulhu")
	assert_eq(synergies[0]["multiplier"], 1.5)


func test_adjacent_different_deity_no_synergy() -> void:
	var grid := TotemGrid.new()
	grid.place_piece(Vector2i(0, 0), _make_totem("cthulhu"))
	grid.place_piece(Vector2i(1, 0), _make_totem("hastur"))
	assert_eq(grid.compute_synergies().size(), 0, "different deities produce no synergy")


func test_diagonal_not_adjacent() -> void:
	var grid := TotemGrid.new()
	grid.place_piece(Vector2i(0, 0), _make_totem("cthulhu"))
	grid.place_piece(Vector2i(1, 1), _make_totem("cthulhu"))
	assert_eq(grid.compute_synergies().size(), 0, "diagonal pieces are not adjacent")


func test_remove_piece_clears_synergy() -> void:
	var grid := TotemGrid.new()
	grid.place_piece(Vector2i(0, 0), _make_totem("cthulhu"))
	grid.place_piece(Vector2i(1, 0), _make_totem("cthulhu"))
	assert_eq(grid.compute_synergies().size(), 1, "synergy before removal")
	grid.remove_piece(Vector2i(1, 0))
	assert_eq(grid.compute_synergies().size(), 0, "synergy gone after removal")


# --- Effective modifiers ---

func test_effective_modifiers_with_synergy_multiplier() -> void:
	var grid := TotemGrid.new()

	# Build two matching-deity pieces with known modifiers using a real affix
	var affix_a := Affix.new(
		"Test Drop Qty",
		Affix.AffixType.PREFIX,
		4, 4,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUANTITY, Tag.CTHULHU],
		[],
		Vector2i(1, 8)
	)
	affix_a.value = 4
	var piece_a := TotemPiece.new()
	piece_a.prefixes.append(affix_a)
	piece_a.deity_tag = Tag.CTHULHU

	var affix_b := Affix.new(
		"Test Drop Qty B",
		Affix.AffixType.PREFIX,
		2, 2,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUANTITY, Tag.CTHULHU],
		[],
		Vector2i(1, 8)
	)
	affix_b.value = 2
	var piece_b := TotemPiece.new()
	piece_b.prefixes.append(affix_b)
	piece_b.deity_tag = Tag.CTHULHU

	grid.place_piece(Vector2i(0, 0), piece_a)
	grid.place_piece(Vector2i(1, 0), piece_b)

	var mods := grid.get_effective_modifiers()
	# Both pieces in synergy: (4 + 2) * 1.5 = 9.0
	assert_almost_eq(mods["drop_quantity"], 9.0, 0.01, "synergy 1.5x applied to both pieces")


func test_effective_modifiers_no_synergy_no_multiplier() -> void:
	var grid := TotemGrid.new()
	var affix := Affix.new(
		"Test Drop Qty",
		Affix.AffixType.PREFIX,
		4, 4,
		[Tag.TOTEM, Tag.EXPEDITION, Tag.DROP_QUANTITY, Tag.CTHULHU],
		[],
		Vector2i(1, 8)
	)
	affix.value = 4
	var piece := TotemPiece.new()
	piece.prefixes.append(affix)
	piece.deity_tag = Tag.CTHULHU
	grid.place_piece(Vector2i(0, 0), piece)

	var mods := grid.get_effective_modifiers()
	assert_almost_eq(mods["drop_quantity"], 4.0, 0.01, "no synergy means no multiplier")


# --- Clear ---

func test_clear_returns_all_pieces() -> void:
	var grid := TotemGrid.new()
	var piece_a := _make_totem("cthulhu")
	var piece_b := _make_totem("hastur")
	grid.place_piece(Vector2i(0, 0), piece_a)
	grid.place_piece(Vector2i(1, 1), piece_b)
	var returned := grid.clear()
	assert_eq(returned.size(), 2, "clear returns both pieces")
	assert_eq(grid.slots.size(), 0, "grid empty after clear")
