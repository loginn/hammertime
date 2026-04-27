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
const EXPEDITION_1_BASE_TIME: float = 10.0
const EXPEDITION_2_BASE_TIME: float = 38.0
const EXPEDITION_HERO_POWER_SCALING: float = 0.005

# Currencies hidden from all UI surfaces (code preserved, drops intact)
const HIDDEN_CURRENCIES: Array[String] = ["scour"]

# Base item creation material costs
const BASE_ITEM_IRON_COST: int = 1
const BASE_ITEM_STEEL_COST: int = 1

# Prestige
const PRESTIGE_TACK_HAMMER_COST: int = 100
const PRESTIGE_REWARD_AMOUNT: int = 999

const PRESTIGE_LEVELS: Array[Dictionary] = [
	{"level": 1, "cost": 100, "reward_amount": 999, "tier_unlocked": 7, "description": "Unlocks Item Tier 7"},
	{"level": 2, "cost": 250, "reward_amount": 999, "tier_unlocked": 6, "description": "Unlocks Item Tier 6"},
	{"level": 3, "cost": 500, "reward_amount": 999, "tier_unlocked": 5, "description": "Unlocks Item Tier 5"},
	{"level": 4, "cost": 1000, "reward_amount": 999, "tier_unlocked": 4, "description": "Unlocks Item Tier 4"},
	{"level": 5, "cost": 2000, "reward_amount": 999, "tier_unlocked": 3, "description": "Unlocks Item Tier 3"},
	{"level": 6, "cost": 4000, "reward_amount": 999, "tier_unlocked": 2, "description": "Unlocks Item Tier 2"},
	{"level": 7, "cost": 8000, "reward_amount": 999, "tier_unlocked": 1, "description": "Unlocks Item Tier 1"},
]
