class_name TotemGrid extends RefCounted

const VALID_POSITIONS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0),
	Vector2i(0, 1), Vector2i(1, 1),
]

var slots: Dictionary = {}


func place_piece(pos: Vector2i, piece) -> bool:
	if pos not in VALID_POSITIONS:
		print_debug("TotemGrid: invalid position ", pos)
		return false
	if slots.has(pos):
		print_debug("TotemGrid: slot ", pos, " is occupied")
		return false
	slots[pos] = piece
	return true


func remove_piece(pos: Vector2i) -> Object:
	if not slots.has(pos):
		return null
	var piece = slots[pos]
	slots.erase(pos)
	return piece


func get_piece(pos: Vector2i) -> Object:
	return slots.get(pos, null)


func get_adjacent_slots(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for offset in offsets:
		var neighbor: Vector2i = pos + offset
		if neighbor in VALID_POSITIONS:
			neighbors.append(neighbor)
	return neighbors


func compute_synergies() -> Array[Dictionary]:
	var synergies: Array[Dictionary] = []
	var checked_pairs: Array = []

	for pos_a: Vector2i in VALID_POSITIONS:
		if not slots.has(pos_a):
			continue
		var piece_a = slots[pos_a]
		if piece_a.deity_tag.is_empty():
			continue
		for pos_b: Vector2i in get_adjacent_slots(pos_a):
			if not slots.has(pos_b):
				continue
			var piece_b = slots[pos_b]
			if piece_b.deity_tag != piece_a.deity_tag:
				continue
			# Avoid duplicate pairs (A,B) and (B,A)
			var pair := [pos_a, pos_b] if pos_a < pos_b else [pos_b, pos_a]
			if pair in checked_pairs:
				continue
			checked_pairs.append(pair)
			synergies.append({
				"pos_a": pos_a,
				"pos_b": pos_b,
				"deity_tag": piece_a.deity_tag,
				"multiplier": 1.5,
			})

	return synergies


func get_synergy_pairs() -> Array[Dictionary]:
	return compute_synergies()


func get_effective_modifiers() -> Dictionary:
	var base_keys: Array[String] = [
		"drop_quantity", "drop_quality", "duration_reduction",
		"hammer_chance", "steel_chance", "wood_chance", "bonus_roll_chance",
	]
	var result: Dictionary = {}
	for key in base_keys:
		result[key] = 0.0

	var synergies: Array[Dictionary] = compute_synergies()
	var synergy_positions: Array = []
	for s in synergies:
		if s["pos_a"] not in synergy_positions:
			synergy_positions.append(s["pos_a"])
		if s["pos_b"] not in synergy_positions:
			synergy_positions.append(s["pos_b"])

	for pos: Vector2i in slots:
		var piece = slots[pos]
		var mods: Dictionary = piece.get_expedition_modifiers()
		var multiplier: float = 1.5 if pos in synergy_positions else 1.0
		for key in base_keys:
			result[key] += mods.get(key, 0) * multiplier

	return result


func clear() -> Array:
	var pieces: Array = []
	for pos: Vector2i in slots:
		pieces.append(slots[pos])
	slots.clear()
	return pieces
