extends Node

const SAVE_PATH = "user://hammertime_save.json"
const SAVE_VERSION = 2
const AUTO_SAVE_INTERVAL = 300.0  # 5 minutes

var auto_save_timer: Timer
var _save_pending: bool = false


func _ready() -> void:
	# Auto-save timer
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	auto_save_timer.one_shot = false
	auto_save_timer.timeout.connect(_on_auto_save)
	add_child(auto_save_timer)
	auto_save_timer.start()

	# Event-driven save triggers
	GameEvents.item_crafted.connect(_on_save_trigger)
	GameEvents.equipment_changed.connect(_on_equipment_save_trigger)
	GameEvents.area_cleared.connect(_on_area_save_trigger)


## Saves the full game state to a JSON file. Returns true on success.
func save_game() -> bool:
	var save_data := _build_save_data()
	var json_string := JSON.stringify(save_data, "\t")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: Failed to open save file for writing: " + str(FileAccess.get_open_error()))
		return false

	file.store_string(json_string)
	return true


## Loads game state from the JSON save file. Returns true on success.
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: Failed to open save file for reading: " + str(FileAccess.get_open_error()))
		return false

	var json_text := file.get_as_text()
	var parsed = JSON.parse_string(json_text)

	if parsed == null or not (parsed is Dictionary):
		push_warning("SaveManager: Save file contains invalid JSON")
		return false

	var data: Dictionary = parsed
	data = _migrate_save(data)

	return _restore_state(data)


## Checks whether a save file exists.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Deletes the save file. Used by New Game flow.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## Builds the save data dictionary from current game state.
func _build_save_data() -> Dictionary:
	var hero_equipment := {}
	for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
		var item = GameState.hero.equipped_items.get(slot)
		if item != null:
			hero_equipment[slot] = item.to_dict()
		else:
			hero_equipment[slot] = null

	var crafting_inv := {}
	for type_name in GameState.crafting_inventory:
		var item = GameState.crafting_inventory[type_name]
		if item != null:
			crafting_inv[type_name] = item.to_dict()
		else:
			crafting_inv[type_name] = null

	var bench_item_data = null
	if GameState.crafting_bench_item != null:
		bench_item_data = GameState.crafting_bench_item.to_dict()

	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"hero_equipment": hero_equipment,
		"currencies": GameState.currency_counts.duplicate(),
		"crafting_inventory": crafting_inv,
		"crafting_bench_item": bench_item_data,
		"crafting_bench_type": GameState.crafting_bench_type,
		"max_unlocked_level": GameState.max_unlocked_level,
		"area_level": GameState.area_level,
	}


## Restores game state from a parsed save dictionary. Returns true on success.
func _restore_state(data: Dictionary) -> bool:
	# Restore hero equipment
	var hero_equipment: Dictionary = data.get("hero_equipment", {})
	for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
		var item_data = hero_equipment.get(slot)
		if item_data != null and item_data is Dictionary:
			var item := Item.create_from_dict(item_data)
			if item != null:
				GameState.hero.equipped_items[slot] = item
			else:
				GameState.hero.equipped_items[slot] = null
		else:
			GameState.hero.equipped_items[slot] = null

	# Restore currencies
	var saved_currencies: Dictionary = data.get("currencies", {})
	for currency_type in saved_currencies:
		GameState.currency_counts[currency_type] = int(saved_currencies[currency_type])

	# Restore crafting inventory
	var saved_crafting: Dictionary = data.get("crafting_inventory", {})
	for type_name in saved_crafting:
		var item_data = saved_crafting[type_name]
		if item_data != null and item_data is Dictionary:
			var item := Item.create_from_dict(item_data)
			GameState.crafting_inventory[type_name] = item
		else:
			GameState.crafting_inventory[type_name] = null

	# Restore crafting bench
	var bench_data = data.get("crafting_bench_item")
	if bench_data != null and bench_data is Dictionary:
		GameState.crafting_bench_item = Item.create_from_dict(bench_data)
	else:
		GameState.crafting_bench_item = null

	GameState.crafting_bench_type = str(data.get("crafting_bench_type", "weapon"))

	# Restore area progress
	GameState.max_unlocked_level = int(data.get("max_unlocked_level", 1))
	GameState.area_level = int(data.get("area_level", 1))

	# Recalculate all derived hero stats from restored equipment
	GameState.hero.update_stats()

	return true


## Migrates save data from older versions to current version.
func _migrate_save(data: Dictionary) -> Dictionary:
	var saved_version: int = int(data.get("version", 1))

	if saved_version < SAVE_VERSION:
		print("SaveManager: Migrating save from v%d to v%d" % [saved_version, SAVE_VERSION])

	if saved_version < 2:
		data = _migrate_v1_to_v2(data)

	data["version"] = SAVE_VERSION
	return data


## Migrates v1 save data to v2 format (per-slot inventory arrays).
func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var old_inv: Dictionary = data.get("crafting_inventory", {})
	var new_inv := {}
	for slot in ["weapon", "helmet", "armor", "boots", "ring"]:
		var item_data = old_inv.get(slot)
		if item_data != null and item_data is Dictionary:
			new_inv[slot] = [item_data]
		else:
			new_inv[slot] = []
	data["crafting_inventory"] = new_inv

	# Strip orphaned crafting_bench_item
	data.erase("crafting_bench_item")

	return data


# --- Export/Import save strings ---


## Exports the full game state as a portable save string (HT1:base64:md5 format).
func export_save_string() -> String:
	var save_data := _build_save_data()
	var json_string := JSON.stringify(save_data)
	var base64 := Marshalls.utf8_to_base64(json_string)
	var checksum := base64.md5_text()
	return "HT1:" + base64 + ":" + checksum


## Imports a save string, validates it, restores game state, and persists to disk.
## Returns {"success": bool, "error": String}.
func import_save_string(save_string: String) -> Dictionary:
	# Strip whitespace/newlines that clipboard managers may insert
	var cleaned := save_string.strip_edges().replace("\n", "").replace("\r", "").replace(" ", "")

	# Prefix check
	if not cleaned.begins_with("HT1:"):
		return {"success": false, "error": "not_hammertime"}

	# Strip prefix, split base64 and checksum at last colon
	var payload := cleaned.substr(4)
	var colon_pos := payload.rfind(":")
	if colon_pos < 0:
		return {"success": false, "error": "invalid_format"}

	var base64_part := payload.substr(0, colon_pos)
	var checksum_part := payload.substr(colon_pos + 1)

	# Verify checksum
	if base64_part.md5_text() != checksum_part:
		return {"success": false, "error": "corrupted"}

	# Decode Base64
	var json_string := Marshalls.base64_to_utf8(base64_part)
	if json_string.is_empty():
		return {"success": false, "error": "decode_failed"}

	# Parse JSON
	var parsed = JSON.parse_string(json_string)
	if parsed == null or not (parsed is Dictionary):
		return {"success": false, "error": "invalid_json"}

	var data: Dictionary = parsed

	# Version check — reject saves from newer game versions
	if int(data.get("version", 0)) > SAVE_VERSION:
		return {"success": false, "error": "newer_version"}

	# Migrate and restore
	data = _migrate_save(data)
	if not _restore_state(data):
		return {"success": false, "error": "restore_failed"}

	# Persist to disk immediately
	save_game()

	# Set flag for post-reload toast (scene reloads after import)
	GameState.import_just_completed = true

	return {"success": true, "error": ""}


# --- Auto-save and event-driven save triggers ---


func _on_auto_save() -> void:
	_trigger_save()


func _on_save_trigger(_arg = null) -> void:
	_trigger_save()


func _on_equipment_save_trigger(_slot: String, _item: Item) -> void:
	_trigger_save()


func _on_area_save_trigger(_level: int) -> void:
	_trigger_save()


## Debounced save trigger — prevents multiple saves in the same frame.
func _trigger_save() -> void:
	if _save_pending:
		return
	_save_pending = true
	call_deferred("_deferred_save")


## Executes the save after the current frame completes.
func _deferred_save() -> void:
	_save_pending = false
	var success := save_game()
	if success:
		GameEvents.save_completed.emit()
	else:
		GameEvents.save_failed.emit()
