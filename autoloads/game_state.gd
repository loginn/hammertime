extends Node

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
	currency_counts = {
		"runic": 0,
		"forge": 0,
		"tack": 0,
		"grand": 0,
		"claw": 0,
		"tuning": 0
	}


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
