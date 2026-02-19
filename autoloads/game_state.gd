extends Node

var debug_hammers: bool = false  # Set to true for testing

var hero: Hero
var currency_counts: Dictionary = {}

# Crafting state (centralized for persistence)
var crafting_inventory: Dictionary = {}
var crafting_bench_type: String = "weapon"

# Area progress (centralized for persistence)
var max_unlocked_level: int = 1
var area_level: int = 1

# Save corruption flag — checked by toast on scene ready
var save_was_corrupted: bool = false

# Import success flag — survives scene reload, checked by toast on scene ready
var import_just_completed: bool = false


func _ready() -> void:
	initialize_fresh_game()

	# Attempt to load saved game
	var loaded := SaveManager.load_game()
	if not loaded and SaveManager.has_save():
		# Save file exists but couldn't be loaded (corrupted)
		save_was_corrupted = true
		push_warning("GameState: Save file appears corrupted, starting fresh")

	# Debug override: always give hammers regardless of save state
	if debug_hammers:
		for key in currency_counts:
			currency_counts[key] = 999
		print("DEBUG: Spawned with 999 of each hammer")


## Sets up a completely fresh game state. Called before load attempts and by New Game.
func initialize_fresh_game() -> void:
	hero = Hero.new()
	# Initialize empty equipment slots
	hero.equipped_items["weapon"] = null
	hero.equipped_items["helmet"] = null
	hero.equipped_items["armor"] = null
	hero.equipped_items["boots"] = null
	hero.equipped_items["ring"] = null

	# Initialize currency counts
	currency_counts = {
		"runic": 1,
		"forge": 0,
		"tack": 0,
		"grand": 0,
		"claw": 0,
		"tuning": 0
	}

	# Initialize crafting state — per-slot arrays (Phase 28)
	crafting_inventory = {
		"weapon": [],
		"helmet": [],
		"armor": [],
		"boots": [],
		"ring": [],
	}
	# Starter weapon goes into weapon slot array
	crafting_inventory["weapon"] = [LightSword.new()]
	crafting_bench_type = "weapon"

	# Initialize area progress
	max_unlocked_level = 1
	area_level = 1

	# Reset corruption flag
	save_was_corrupted = false


## Adds currencies from a drops dictionary to the inventory
func add_currencies(drops: Dictionary) -> void:
	for currency_type in drops:
		if currency_type in currency_counts:
			currency_counts[currency_type] += drops[currency_type]


## Attempts to spend one currency of the given type
## Returns true if successful, false if not enough currency
func spend_currency(currency_type: String) -> bool:
	if currency_type not in currency_counts:
		return false

	if currency_counts[currency_type] <= 0:
		return false

	currency_counts[currency_type] -= 1
	return true
