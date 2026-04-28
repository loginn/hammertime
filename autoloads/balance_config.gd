class_name BalanceConfig extends RefCounted

# Hero base stats
const BASE_HEALTH: float = 100.0
const BASE_CRIT_CHANCE: float = 5.0
const BASE_CRIT_DAMAGE: float = 150.0

# Defense pipeline
const ARMOR_DIVISOR: float = 5.0
const EVASION_DIVISOR: float = 200.0
const DODGE_CAP: float = 0.75
const RESISTANCE_CAP: int = 75
const ES_SPLIT_RATIO: float = 0.5
const ES_RECHARGE_RATE: float = 0.33

# Hero power formula tuning
const ARMOR_SCALING: float = 500.0    # armor value that doubles effective HP contribution
const EVASION_SCALING: float = 300.0  # evasion value that adds +100% avoidance factor
const DEFENSE_WEIGHT: float = 0.5     # how much defensive_score contributes vs DPS

# Affix system
const MAGIC_MAX_PREFIXES: int = 1
const MAGIC_MAX_SUFFIXES: int = 1
const RARE_MAX_PREFIXES: int = 3
const RARE_MAX_SUFFIXES: int = 3

# Expedition timing
const EXPEDITION_TRANSMUTE_TIME: float = 7.0
const EXPEDITION_AUGMENTATION_TIME: float = 60.0
const EXPEDITION_ALTERATION_TIME: float = 280.0
const EXPEDITION_ALCHEMY_TIME: float = 480.0
const EXPEDITION_EXALTATION_TIME: float = 1800.0
const EXPEDITION_ANNULMENT_TIME: float = 5400.0
const EXPEDITION_HERO_POWER_SCALING: float = 0.02

# Currencies hidden from all UI surfaces (code preserved, drops intact)
const HIDDEN_CURRENCIES: Array[String] = ["scour"]

# Base item creation material costs
const BASE_ITEM_IRON_COST: int = 1
const BASE_ITEM_STEEL_COST: int = 1
const BASE_TOTEM_ASH_COST: int = 1
const BASE_TOTEM_OAK_COST: int = 1

# Prestige
const PRESTIGE_LEVELS: Array[Dictionary] = [
	{"level": 1, "cost": 100, "cost_currency": "tuning", "description": "Unlocks rare expedition zones"},
	{"level": 2, "cost": 100, "cost_currency": "claw", "description": "Unlocks Totem crafting tab"},
]
