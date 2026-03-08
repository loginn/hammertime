class_name MonsterPack extends Resource

## Scaled monster pack instance for combat.
## Created by PackGenerator with area-level-scaled stats from MonsterType templates.
## Each pack deals a single elemental damage type. Combat loop (Phase 15) consumes these.

var pack_name: String = ""
var hp: float = 0.0
var max_hp: float = 0.0
var damage: float = 0.0
var damage_min: float = 0.0
var damage_max: float = 0.0
var attack_speed: float = 1.0  # Attacks per second (from MonsterType, not scaled)
var element: String = "physical"  # "physical", "fire", "cold", "lightning"
var difficulty_bonus: float = 1.0  # Drop rate multiplier based on pack toughness (1.0 normal, 1.5 tough)

# Active DoT effects applied by hero
# Each entry: {"type": String, "damage_per_tick": float, "ticks_remaining": int, "element": String}
var active_dots: Array = []


func is_alive() -> bool:
	return hp > 0.0


func take_damage(amount: float) -> void:
	hp -= amount
	hp = maxf(0.0, hp)


func get_hp_percentage() -> float:
	if max_hp <= 0.0:
		return 0.0
	return hp / max_hp


## Applies a DoT effect following stacking rules per type.
## Returns the current stack count for this dot_type after application.
func apply_dot(dot_type: String, damage_per_tick: float, dot_element: String) -> int:
	var duration := 4
	match dot_type:
		"bleed":
			# Max 8 stacks. If at cap, replace stack with lowest ticks_remaining.
			var bleed_stacks := active_dots.filter(func(d): return d["type"] == "bleed")
			if bleed_stacks.size() >= 8:
				var lowest: Dictionary = bleed_stacks[0]
				for stack in bleed_stacks:
					if stack["ticks_remaining"] < lowest["ticks_remaining"]:
						lowest = stack
				lowest["damage_per_tick"] = damage_per_tick
				lowest["ticks_remaining"] = duration
				lowest["element"] = dot_element
			else:
				active_dots.append({
					"type": "bleed",
					"damage_per_tick": damage_per_tick,
					"ticks_remaining": duration,
					"element": dot_element,
				})
		"poison":
			# Unlimited stacks. Always add a new stack.
			active_dots.append({
				"type": "poison",
				"damage_per_tick": damage_per_tick,
				"ticks_remaining": duration,
				"element": dot_element,
			})
		"burn":
			# Max 1 stack. Replace existing burn if present.
			var existing := active_dots.filter(func(d): return d["type"] == "burn")
			if existing.size() > 0:
				existing[0]["damage_per_tick"] = damage_per_tick
				existing[0]["ticks_remaining"] = duration
				existing[0]["element"] = dot_element
			else:
				active_dots.append({
					"type": "burn",
					"damage_per_tick": damage_per_tick,
					"ticks_remaining": duration,
					"element": dot_element,
				})
	return get_dot_count(dot_type)


## Processes all active DoTs: accumulates damage per type, decrements ticks, removes expired.
## Returns array of {"type": String, "damage": float} for each type that ticked.
func process_dot_tick() -> Array:
	var damage_by_type: Dictionary = {}
	for dot in active_dots:
		var t: String = dot["type"]
		if t not in damage_by_type:
			damage_by_type[t] = 0.0
		damage_by_type[t] += dot["damage_per_tick"]
		dot["ticks_remaining"] -= 1

	# Remove expired entries
	active_dots = active_dots.filter(func(d): return d["ticks_remaining"] > 0)

	# Build result array
	var results: Array = []
	for t in damage_by_type:
		results.append({"type": t, "damage": damage_by_type[t]})
	return results


## Removes all active DoT effects.
func clear_dots() -> void:
	active_dots.clear()


## Returns number of active stacks for a given type.
func get_dot_count(dot_type: String) -> int:
	var count := 0
	for dot in active_dots:
		if dot["type"] == dot_type:
			count += 1
	return count
