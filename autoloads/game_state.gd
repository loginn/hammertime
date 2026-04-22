extends Node

var debug_mode: bool = false

var hero: Hero
var currency_counts: Dictionary = {}

var crafting_inventory: Dictionary = {}
var crafting_bench_item: Item = null

var expedition_resolver: ExpeditionResolver = null

const CURRENCY_KEYS: Array[String] = [
	"tack", "tuning", "forge", "grand", "runic", "claw", "scour"
]

var _currency_classes: Dictionary = {}

const CURRENCY_DISPLAY_NAMES: Dictionary = {
	"tack": "Tack Hammer",
	"tuning": "Tuning Hammer",
	"forge": "Forge Hammer",
	"grand": "Grand Hammer",
	"runic": "Runic Hammer",
	"claw": "Claw Hammer",
	"scour": "Scour Hammer",
}


func _ready() -> void:
	initialize_fresh_game()
	if debug_mode:
		_apply_debug_resources()


func initialize_fresh_game() -> void:
	hero = Hero.new()

	currency_counts = {}
	for key in CURRENCY_KEYS:
		currency_counts[key] = 0

	crafting_inventory = {}
	for slot_val in Tag.ALL_SLOTS:
		crafting_inventory[slot_val] = []

	crafting_bench_item = null
	expedition_resolver = ExpeditionResolver.new()


func wipe_run_state() -> void:
	currency_counts = {}
	for key in CURRENCY_KEYS:
		currency_counts[key] = 0

	crafting_inventory = {}
	for slot_val in Tag.ALL_SLOTS:
		crafting_inventory[slot_val] = []

	crafting_bench_item = null

	if expedition_resolver != null:
		expedition_resolver.cancel_expedition()
	expedition_resolver = ExpeditionResolver.new()

	for slot_val in Tag.ALL_SLOTS:
		hero.unequip_item(slot_val)

	hero.update_stats()


func add_currencies(drops: Dictionary) -> void:
	for currency_type in drops:
		if currency_type in currency_counts:
			currency_counts[currency_type] += drops[currency_type]


func spend_currency(currency_type: String, amount: int = 1) -> bool:
	if currency_type not in currency_counts:
		return false
	if currency_counts[currency_type] < amount:
		return false
	currency_counts[currency_type] -= amount
	GameEvents.currency_changed.emit(currency_type, currency_counts[currency_type])
	return true


func add_item_to_inventory(item: Item) -> void:
	if item.slot in crafting_inventory:
		crafting_inventory[item.slot].append(item)
		GameEvents.inventory_changed.emit(item.slot)


func remove_item_from_inventory(item: Item) -> void:
	if item.slot in crafting_inventory:
		crafting_inventory[item.slot].erase(item)
		GameEvents.inventory_changed.emit(item.slot)


func get_currency_instance(currency_key: String) -> Currency:
	if _currency_classes.is_empty():
		_currency_classes = {
			"tack": TackHammer,
			"tuning": TuningHammer,
			"forge": ForgeHammer,
			"grand": GrandHammer,
			"runic": RunicHammer,
			"claw": ClawHammer,
			"scour": ScourHammer,
		}
	if currency_key not in _currency_classes:
		return null
	return _currency_classes[currency_key].new()


func _apply_debug_resources() -> void:
	for key in CURRENCY_KEYS:
		currency_counts[key] = 999
	print("DEBUG: Spawned with 999 of each hammer")
