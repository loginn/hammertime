class_name Tag_List extends Node

enum Element {
	PHYSICAL,
	FIRE,
	COLD,
	LIGHTNING,
}

enum ItemSlot {
	WEAPON,
	ARMOR,
	HELMET,
	BOOTS,
	RING,
}

enum MaterialTier {
	IRON,
	STEEL,
	ASH,
	OAK,
}

enum Rarity {
	NORMAL,
	MAGIC,
	RARE,
}

const PHYSICAL = "PHYSICAL"
const ELEMENTAL = "ELEMENTAL"
const LIGHTNING = "LIGHTNING"
const FIRE = "FIRE"
const COLD = "COLD"
const DEFENSE = "DEFENSE"
const ATTACK = "ATTACK"
const MAGIC = "MAGIC"
const DOT = "DOT"
const SPEED = "SPEED"
const FLAT = "FLAT"
const PERCENTAGE = "PERCENTAGE"
const CRITICAL = "CRITICAL"
const WEAPON = "WEAPON"
const ARMOR = "ARMOR"
const ENERGY_SHIELD = "ENERGY_SHIELD"
const MANA = "MANA"
const MOVEMENT = "MOVEMENT"
const UTILITY = "UTILITY"
const EVASION = "EVASION"
const EXPEDITION = "EXPEDITION"
const TOTEM = "TOTEM"
const DROP_QUANTITY = "DROP_QUANTITY"
const DROP_QUALITY = "DROP_QUALITY"
const DURATION = "DURATION"
const HAMMER_CHANCE = "HAMMER_CHANCE"
const MATERIAL_CHANCE = "MATERIAL_CHANCE"

# Deity tags for Cthulhu mythos totem affixes
const CTHULHU = "CTHULHU"
const NYARLATHOTEP = "NYARLATHOTEP"
const HASTUR = "HASTUR"
const DAGON = "DAGON"
const YOG_SOTHOTH = "YOG_SOTHOTH"
const SHUB_NIGGURATH = "SHUB_NIGGURATH"

enum StatType {
	FLAT_DAMAGE,
	INCREASED_DAMAGE,
	INCREASED_SPEED,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	FLAT_ARMOR,
	FLAT_ENERGY_SHIELD,
	FLAT_HEALTH,
	FLAT_MANA,
	MOVEMENT_SPEED,
	PERCENT_ARMOR,
	PERCENT_EVASION,
	PERCENT_ENERGY_SHIELD,
	PERCENT_HEALTH,
	FLAT_EVASION,
	FIRE_RESISTANCE,
	COLD_RESISTANCE,
	LIGHTNING_RESISTANCE,
	ALL_RESISTANCE,
}

const ELEMENT_NAMES: Dictionary = {
	Element.PHYSICAL: "physical",
	Element.FIRE: "fire",
	Element.COLD: "cold",
	Element.LIGHTNING: "lightning",
}

const SLOT_NAMES: Dictionary = {
	ItemSlot.WEAPON: "weapon",
	ItemSlot.ARMOR: "armor",
	ItemSlot.HELMET: "helmet",
	ItemSlot.BOOTS: "boots",
	ItemSlot.RING: "ring",
}

const ALL_SLOTS: Array[int] = [
	ItemSlot.WEAPON, ItemSlot.ARMOR, ItemSlot.HELMET, ItemSlot.BOOTS, ItemSlot.RING
]

const MATERIAL_TIER_CONFIG: Dictionary = {
	MaterialTier.IRON: {
		"name": "Iron",
		"min_affix_tier": 5,
		"max_affix_tier": 8,
		"base_stat_multiplier": 1.0,
	},
	MaterialTier.STEEL: {
		"name": "Steel",
		"min_affix_tier": 1,
		"max_affix_tier": 4,
		"base_stat_multiplier": 1.8,
	},
	MaterialTier.ASH: {
		"name": "Ash",
		"min_affix_tier": 5,
		"max_affix_tier": 8,
		"base_stat_multiplier": 1.0,
	},
	MaterialTier.OAK: {
		"name": "Oak",
		"min_affix_tier": 1,
		"max_affix_tier": 4,
		"base_stat_multiplier": 1.8,
	},
}

static func slot_name(slot: ItemSlot) -> String:
	return SLOT_NAMES[slot]

static func element_name(element: Element) -> String:
	return ELEMENT_NAMES[element]

static func material_name(tier: MaterialTier) -> String:
	return MATERIAL_TIER_CONFIG[tier]["name"]
