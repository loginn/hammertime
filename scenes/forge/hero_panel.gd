extends VBoxContainer

signal slot_tab_requested(slot: int)

const STAT_DEFS: Array[Dictionary] = [
	{"key": "max_health", "label": "Life"},
	{"key": "total_energy_shield", "label": "Energy Shield"},
	{"key": "total_armor", "label": "Armor"},
	{"key": "total_evasion", "label": "Evasion"},
	{"key": "_sep1", "label": ""},
	{"key": "total_dps", "label": "DPS"},
	{"key": "total_crit_chance", "label": "Crit Chance", "fmt": "percent"},
	{"key": "total_crit_damage", "label": "Crit Damage", "fmt": "percent"},
	{"key": "_sep2", "label": ""},
	{"key": "total_fire_resistance", "label": "Fire Resist"},
	{"key": "total_cold_resistance", "label": "Cold Resist"},
	{"key": "total_lightning_resistance", "label": "Lightning Resist"},
]

var _slot_rows: Dictionary = {}
var _equip_buttons: Dictionary = {}
var _stat_labels: Dictionary = {}
var _delta_labels: Dictionary = {}
var _bench_item: HeroItem = null


func _ready() -> void:
	_build_header()
	_build_equipped_slots()
	_build_separator()
	_build_stat_display()
	GameEvents.equipment_changed.connect(_on_equipment_changed)
	GameEvents.item_crafted.connect(_on_item_crafted)
	refresh()


func _build_header() -> void:
	var header := Label.new()
	header.text = "The Hero"
	header.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55, 1))
	header.add_theme_font_size_override("font_size", 16)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	add_child(spacer)


func _build_equipped_slots() -> void:
	var slots_header := Label.new()
	slots_header.text = "Equipped"
	slots_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5, 1))
	slots_header.add_theme_font_size_override("font_size", 13)
	add_child(slots_header)

	for slot_val in Tag.ALL_SLOTS:
		var hbox := HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 28)
		add_child(hbox)

		var row := Button.new()
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.flat = true
		row.pressed.connect(_on_slot_row_pressed.bind(slot_val))
		hbox.add_child(row)
		_slot_rows[slot_val] = row

		var equip_btn := Button.new()
		equip_btn.text = "Equip"
		equip_btn.visible = false
		equip_btn.custom_minimum_size = Vector2(50, 0)
		equip_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		equip_btn.pressed.connect(_on_equip_pressed.bind(slot_val))
		hbox.add_child(equip_btn)
		_equip_buttons[slot_val] = equip_btn

	_refresh_equipped_slots()


func _build_separator() -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	add_child(sep)


func _build_stat_display() -> void:
	var stats_header := Label.new()
	stats_header.text = "Stats"
	stats_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5, 1))
	stats_header.add_theme_font_size_override("font_size", 13)
	add_child(stats_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var stat_vbox := VBoxContainer.new()
	stat_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stat_vbox)

	for def in STAT_DEFS:
		var key: String = def["key"]
		if key.begins_with("_sep"):
			var sep := HSeparator.new()
			sep.add_theme_constant_override("separation", 4)
			stat_vbox.add_child(sep)
			continue

		var hbox := HBoxContainer.new()
		stat_vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = def["label"]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 12)
		hbox.add_child(name_label)

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_font_size_override("font_size", 12)
		hbox.add_child(value_label)
		_stat_labels[key] = value_label

		var delta_label := Label.new()
		delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		delta_label.custom_minimum_size = Vector2(60, 0)
		delta_label.add_theme_font_size_override("font_size", 12)
		hbox.add_child(delta_label)
		_delta_labels[key] = delta_label


func refresh() -> void:
	_refresh_equipped_slots()
	_refresh_stats()
	_refresh_equip_buttons()


func update_bench_item(item: HeroItem) -> void:
	_bench_item = item
	_refresh_equip_buttons()


func _refresh_equip_buttons() -> void:
	for slot_val in Tag.ALL_SLOTS:
		var btn: Button = _equip_buttons[slot_val]
		btn.visible = _bench_item != null and _bench_item.slot == slot_val


func _refresh_equipped_slots() -> void:
	var hero: Hero = GameState.hero
	for slot_val in Tag.ALL_SLOTS:
		var slot_name: String = Tag.slot_name(slot_val).capitalize()
		var item: HeroItem = hero.get_equipped(slot_val)
		var row: Button = _slot_rows[slot_val]
		if item != null:
			row.text = "%s: %s" % [slot_name, item.item_name]
			row.add_theme_color_override("font_color", item.get_rarity_color())
		else:
			row.text = "%s: Empty" % slot_name
			row.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))


func _refresh_stats() -> void:
	var hero: Hero = GameState.hero
	for def in STAT_DEFS:
		var key: String = def["key"]
		if key.begins_with("_sep"):
			continue
		var value: float = _get_hero_stat(hero, key)
		var label: Label = _stat_labels[key]
		if def.get("fmt") == "percent":
			label.text = "%.1f%%" % value
		elif key == "total_dps":
			label.text = "%.1f" % value
		else:
			label.text = str(int(value))


func _get_hero_stat(hero: Hero, key: String) -> float:
	match key:
		"max_health": return hero.max_health
		"total_energy_shield": return float(hero.total_energy_shield)
		"total_armor": return float(hero.total_armor)
		"total_evasion": return float(hero.total_evasion)
		"total_dps": return hero.total_dps
		"total_crit_chance": return hero.total_crit_chance
		"total_crit_damage": return hero.total_crit_damage
		"total_fire_resistance": return float(hero.total_fire_resistance)
		"total_cold_resistance": return float(hero.total_cold_resistance)
		"total_lightning_resistance": return float(hero.total_lightning_resistance)
	return 0.0


func show_deltas(bench_item: HeroItem) -> void:
	_clear_deltas()
	if bench_item == null:
		return

	var hero: Hero = GameState.hero
	var slot: int = bench_item.slot
	var original_item: HeroItem = hero.get_equipped(slot)

	if original_item == bench_item:
		return

	var old_stats: Dictionary = _snapshot_stats(hero)
	var new_stats: Dictionary = _simulate_stats_with(hero, bench_item, slot, original_item)

	for key in old_stats:
		var delta: float = new_stats[key] - old_stats[key]
		if absf(delta) < 0.01:
			_delta_labels[key].text = ""
			continue
		var def: Dictionary = _find_stat_def(key)
		if def.get("fmt") == "percent":
			if delta > 0:
				_delta_labels[key].text = "+%.1f%%" % delta
			else:
				_delta_labels[key].text = "%.1f%%" % delta
		elif key == "total_dps":
			if delta > 0:
				_delta_labels[key].text = "+%.1f" % delta
			else:
				_delta_labels[key].text = "%.1f" % delta
		else:
			if delta > 0:
				_delta_labels[key].text = "+%d" % int(delta)
			else:
				_delta_labels[key].text = "%d" % int(delta)

		if delta > 0:
			_delta_labels[key].add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		else:
			_delta_labels[key].add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))


func _clear_deltas() -> void:
	for key in _delta_labels:
		_delta_labels[key].text = ""
		_delta_labels[key].remove_theme_color_override("font_color")


func _simulate_stats_with(hero: Hero, bench_item: HeroItem, slot: int, original_item: HeroItem) -> Dictionary:
	hero.equipped_items[slot] = bench_item
	hero.update_stats()
	var stats := _snapshot_stats(hero)
	hero.equipped_items[slot] = original_item
	hero.update_stats()
	return stats


func _snapshot_stats(hero: Hero) -> Dictionary:
	return {
		"max_health": hero.max_health,
		"total_energy_shield": float(hero.total_energy_shield),
		"total_armor": float(hero.total_armor),
		"total_evasion": float(hero.total_evasion),
		"total_dps": hero.total_dps,
		"total_crit_chance": hero.total_crit_chance,
		"total_crit_damage": hero.total_crit_damage,
		"total_fire_resistance": float(hero.total_fire_resistance),
		"total_cold_resistance": float(hero.total_cold_resistance),
		"total_lightning_resistance": float(hero.total_lightning_resistance),
	}


func _find_stat_def(key: String) -> Dictionary:
	for def in STAT_DEFS:
		if def["key"] == key:
			return def
	return {}


func _on_equip_pressed(slot_val: int) -> void:
	if _bench_item == null or _bench_item.slot != slot_val:
		return
	var hero: Hero = GameState.hero
	var currently_equipped: HeroItem = hero.get_equipped(slot_val)
	if currently_equipped != null:
		GameState.add_item_to_inventory(currently_equipped)
	hero.equip_item(_bench_item)
	hero.update_stats()
	GameState.remove_item_from_inventory(_bench_item)
	GameState.crafting_bench_item = null
	GameEvents.equipment_changed.emit(slot_val, _bench_item)
	GameEvents.inventory_changed.emit(slot_val)
	_bench_item = null
	_refresh_equip_buttons()


func _on_slot_row_pressed(slot_val: int) -> void:
	slot_tab_requested.emit(slot_val)


func _on_equipment_changed(_slot: int, _item: HeroItem) -> void:
	refresh()


func _on_item_crafted(_item: HeroItem) -> void:
	refresh()
