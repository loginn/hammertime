extends Node

@export var debug_hammers: bool = false

var hero: Hero
var currency_counts: Dictionary = {}


func _ready() -> void:
	hero = Hero.new()
	# Initialize empty equipment slots
	hero.equipped_items["weapon"] = null
	hero.equipped_items["helmet"] = null
	hero.equipped_items["armor"] = null
	hero.equipped_items["boots"] = null
	hero.equipped_items["ring"] = null

	# Initialize currency counts
	var start_count := 999 if debug_hammers else 0
	currency_counts = {
		"runic": start_count,
		"forge": start_count,
		"tack": start_count,
		"grand": start_count,
		"claw": start_count,
		"tuning": start_count
	}
	if debug_hammers:
		print("DEBUG: Spawned with 999 of each hammer")


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
