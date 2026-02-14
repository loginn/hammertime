extends Node

var hero: Hero


func _ready() -> void:
	hero = Hero.new()
	# Initialize empty equipment slots
	hero.equipped_items["weapon"] = null
	hero.equipped_items["helmet"] = null
	hero.equipped_items["armor"] = null
	hero.equipped_items["boots"] = null
	hero.equipped_items["ring"] = null
