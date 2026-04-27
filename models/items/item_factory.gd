class_name ItemFactory extends RefCounted

static var _base_items: Dictionary = {}


static func _get_base_items() -> Dictionary:
	if _base_items.is_empty():
		_base_items = _build_base_items()
	return _base_items


static func _build_base_items() -> Dictionary:
	return {
		"iron_shortsword": {
			"name": "Iron Shortsword",
			"slot": Tag_List.ItemSlot.WEAPON,
			"material_tier": Tag_List.MaterialTier.IRON,
			"valid_tags": [Tag_List.PHYSICAL, Tag_List.ATTACK, Tag_List.CRITICAL, Tag_List.WEAPON],
			"base_damage_min": 8,
			"base_damage_max": 12,
			"base_speed": 1,
			"base_attack_speed": 1.8,
			"implicit": { "name": "Attack Speed", "min": 2, "max": 5, "tags": [Tag_List.SPEED, Tag_List.ATTACK], "stat_types": [Tag_List.StatType.INCREASED_SPEED] },
		},
		"steel_longsword": {
			"name": "Steel Longsword",
			"slot": Tag_List.ItemSlot.WEAPON,
			"material_tier": Tag_List.MaterialTier.STEEL,
			"valid_tags": [Tag_List.PHYSICAL, Tag_List.ATTACK, Tag_List.CRITICAL, Tag_List.WEAPON],
			"base_damage_min": 14,
			"base_damage_max": 22,
			"base_speed": 1,
			"base_attack_speed": 1.6,
			"implicit": { "name": "Attack Speed", "min": 3, "max": 7, "tags": [Tag_List.SPEED, Tag_List.ATTACK], "stat_types": [Tag_List.StatType.INCREASED_SPEED] },
		},
		"iron_vest": {
			"name": "Iron Vest",
			"slot": Tag_List.ItemSlot.ARMOR,
			"material_tier": Tag_List.MaterialTier.IRON,
			"valid_tags": [Tag_List.DEFENSE, Tag_List.ARMOR, Tag_List.ENERGY_SHIELD],
			"base_armor": 5,
		},
		"steel_chainmail": {
			"name": "Steel Chainmail",
			"slot": Tag_List.ItemSlot.ARMOR,
			"material_tier": Tag_List.MaterialTier.STEEL,
			"valid_tags": [Tag_List.DEFENSE, Tag_List.ARMOR, Tag_List.ENERGY_SHIELD],
			"base_armor": 12,
		},
		"iron_cap": {
			"name": "Iron Cap",
			"slot": Tag_List.ItemSlot.HELMET,
			"material_tier": Tag_List.MaterialTier.IRON,
			"valid_tags": [Tag_List.DEFENSE, Tag_List.ARMOR, Tag_List.ENERGY_SHIELD, Tag_List.MANA],
			"base_armor": 3,
		},
		"steel_helm": {
			"name": "Steel Helm",
			"slot": Tag_List.ItemSlot.HELMET,
			"material_tier": Tag_List.MaterialTier.STEEL,
			"valid_tags": [Tag_List.DEFENSE, Tag_List.ARMOR, Tag_List.ENERGY_SHIELD, Tag_List.MANA],
			"base_armor": 8,
		},
		"iron_sandals": {
			"name": "Iron Sandals",
			"slot": Tag_List.ItemSlot.BOOTS,
			"material_tier": Tag_List.MaterialTier.IRON,
			"valid_tags": [Tag_List.DEFENSE, Tag_List.ARMOR, Tag_List.SPEED, Tag_List.ENERGY_SHIELD],
			"base_movement_speed": 0,
			"implicit": { "name": "Movement Speed", "min": 1, "max": 3, "tags": [Tag_List.SPEED, Tag_List.MOVEMENT], "stat_types": [Tag_List.StatType.MOVEMENT_SPEED] },
		},
		"steel_greaves": {
			"name": "Steel Greaves",
			"slot": Tag_List.ItemSlot.BOOTS,
			"material_tier": Tag_List.MaterialTier.STEEL,
			"valid_tags": [Tag_List.DEFENSE, Tag_List.ARMOR, Tag_List.SPEED, Tag_List.ENERGY_SHIELD],
			"base_armor": 4,
			"base_movement_speed": 0,
			"implicit": { "name": "Movement Speed", "min": 2, "max": 5, "tags": [Tag_List.SPEED, Tag_List.MOVEMENT], "stat_types": [Tag_List.StatType.MOVEMENT_SPEED] },
		},
		"iron_band": {
			"name": "Iron Band",
			"slot": Tag_List.ItemSlot.RING,
			"material_tier": Tag_List.MaterialTier.IRON,
			"valid_tags": [Tag_List.ATTACK, Tag_List.CRITICAL, Tag_List.SPEED, Tag_List.WEAPON],
			"base_damage_min": 2,
			"base_damage_max": 4,
			"base_speed": 1,
			"implicit": { "name": "Crit Chance", "min": 1, "max": 2, "tags": [Tag_List.CRITICAL, Tag_List.ATTACK], "stat_types": [Tag_List.StatType.CRIT_CHANCE] },
		},
		"steel_signet": {
			"name": "Steel Signet",
			"slot": Tag_List.ItemSlot.RING,
			"material_tier": Tag_List.MaterialTier.STEEL,
			"valid_tags": [Tag_List.ATTACK, Tag_List.CRITICAL, Tag_List.SPEED, Tag_List.WEAPON],
			"base_damage_min": 4,
			"base_damage_max": 8,
			"base_speed": 1,
			"implicit": { "name": "Crit Chance", "min": 2, "max": 4, "tags": [Tag_List.CRITICAL, Tag_List.ATTACK], "stat_types": [Tag_List.StatType.CRIT_CHANCE] },
		},
	}


static func can_afford_base(base_id: String) -> bool:
	var items := _get_base_items()
	if base_id not in items:
		return false
	var tier: Tag_List.MaterialTier = items[base_id]["material_tier"]
	var material_key: String = "iron" if tier == Tag_List.MaterialTier.IRON else "steel"
	var cost: int = BalanceConfig.BASE_ITEM_IRON_COST if tier == Tag_List.MaterialTier.IRON else BalanceConfig.BASE_ITEM_STEEL_COST
	return GameState.currency_counts.get(material_key, 0) >= cost


static func create_base(base_id: String) -> HeroItem:
	var items := _get_base_items()
	if base_id not in items:
		push_error("Unknown base item: " + base_id)
		return null

	var def: Dictionary = items[base_id]
	var tier: Tag_List.MaterialTier = def["material_tier"]
	var material_key: String = "iron" if tier == Tag_List.MaterialTier.IRON else "steel"
	var cost: int = BalanceConfig.BASE_ITEM_IRON_COST if tier == Tag_List.MaterialTier.IRON else BalanceConfig.BASE_ITEM_STEEL_COST
	if not GameState.spend_currency(material_key, cost):
		return null
	var item := HeroItem.new()
	item.base_id = base_id
	item.item_name = def["name"]
	item.slot = def["slot"]
	item.material_tier = def["material_tier"]
	item.valid_tags.assign(def["valid_tags"])
	item.rarity = CraftableItem.Rarity.NORMAL

	item.base_damage_min = def.get("base_damage_min", 0)
	item.base_damage_max = def.get("base_damage_max", 0)
	item.base_speed = def.get("base_speed", 1)
	item.base_attack_speed = def.get("base_attack_speed", 1.0)
	item.base_armor = def.get("base_armor", 0)
	item.base_evasion = def.get("base_evasion", 0)
	item.base_energy_shield = def.get("base_energy_shield", 0)
	item.base_health = def.get("base_health", 0)
	item.base_movement_speed = def.get("base_movement_speed", 0)
	item.base_mana = def.get("base_mana", 0)

	if "implicit" in def:
		var imp_def: Dictionary = def["implicit"]
		var imp_tags: Array[String] = []
		imp_tags.assign(imp_def["tags"])
		var imp_stats: Array[int] = []
		imp_stats.assign(imp_def["stat_types"])
		item.implicit = Implicit.new(
			imp_def["name"],
			Affix.AffixType.IMPLICIT,
			imp_def["min"],
			imp_def["max"],
			imp_tags,
			imp_stats
		)

	item.update_value()
	return item


static func get_bases_for_slot(slot: Tag_List.ItemSlot) -> Array[String]:
	var items := _get_base_items()
	var result: Array[String] = []
	for base_id in items:
		if items[base_id]["slot"] == slot:
			result.append(base_id)
	return result


static func get_bases_for_material(tier: Tag_List.MaterialTier) -> Array[String]:
	var items := _get_base_items()
	var result: Array[String] = []
	for base_id in items:
		if items[base_id]["material_tier"] == tier:
			result.append(base_id)
	return result


static func get_base_for_slot_and_material(slot: Tag_List.ItemSlot, tier: Tag_List.MaterialTier) -> String:
	var items := _get_base_items()
	for base_id in items:
		var def: Dictionary = items[base_id]
		if def["slot"] == slot and def["material_tier"] == tier:
			return base_id
	return ""
