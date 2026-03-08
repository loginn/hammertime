class_name DefenseCalculator extends RefCounted


## Calculates physical damage reduction from armor using PoE-style diminishing returns.
## Formula: armor / (armor + 5 * raw_damage)
##
## Armor is most effective against small hits, less effective against large hits.
## Examples:
## - 100 armor vs 10 damage: 100/(100+50) = 66.7% reduction
## - 100 armor vs 100 damage: 100/(100+500) = 16.7% reduction
## - 500 armor vs 100 damage: 500/(500+500) = 50.0% reduction
##
## Returns damage reduction as a float (0.0 to ~0.9). No hard cap -- diminishing
## returns naturally prevent reaching 100%.
static func calculate_armor_reduction(armor: int, raw_physical_damage: float) -> float:
	if armor <= 0 or raw_physical_damage <= 0.0:
		return 0.0
	return float(armor) / (float(armor) + 5.0 * raw_physical_damage)


## Converts raw evasion stat into dodge chance using hyperbolic diminishing returns.
## Formula: evasion / (evasion + 200)
##
## Evasion only dodges attacks, not spells. Pure RNG -- each attack independently
## rolls against the dodge chance.
##
## Examples:
## - 50 evasion: 50/(50+200) = 20.0% dodge
## - 100 evasion: 100/(100+200) = 33.3% dodge
## - 200 evasion: 200/(200+200) = 50.0% dodge
## - 600 evasion: 600/(600+200) = 75.0% dodge (hits cap)
##
## Returns dodge chance as a float (0.0 to 0.75). Capped at 75%.
static func calculate_dodge_chance(evasion: int) -> float:
	if evasion <= 0:
		return 0.0
	var raw_chance := float(evasion) / (float(evasion) + 200.0)
	return minf(raw_chance, 0.75)


## Calculates elemental damage reduction from resistance.
## Effective resistance is clamped at 75%, but gear can grant over 75% (over-capping).
##
## Examples:
## - 30 resistance: 30% reduction
## - 75 resistance: 75% reduction (cap)
## - 100 resistance: 75% reduction (over-capped, effective clamped)
##
## Returns reduction as a float (0.0 to 0.75).
static func calculate_resistance_reduction(resistance: int) -> float:
	var effective := mini(resistance, 75)
	if effective <= 0:
		return 0.0
	return float(effective) / 100.0


## Splits mitigated damage 50/50 between energy shield and life.
## If ES cannot absorb its full portion, overflow goes to life.
##
## The 50% bypass model means incoming damage (after armor/resistances) splits:
## - 50% targets ES
## - 50% goes directly to life
##
## Returns: { "es_damage": float, "life_damage": float }
static func apply_es_split(
	mitigated_damage: float, current_es: float
) -> Dictionary:
	if current_es <= 0.0:
		return { "es_damage": 0.0, "life_damage": mitigated_damage }

	var es_portion := mitigated_damage * 0.5
	var life_portion := mitigated_damage * 0.5

	# If ES can't absorb its portion, overflow to life
	if es_portion > current_es:
		var overflow := es_portion - current_es
		es_portion = current_es
		life_portion += overflow

	return { "es_damage": es_portion, "life_damage": life_portion }


## Calculates damage taken from a DoT tick. Simplified pipeline:
## - No evasion (DoT bypasses dodge)
## - No armor (DoT bypasses physical mitigation)
## - Resistance: only matching resistance applies (none for physical/bleed)
## - ES/Life split: applies normally (50/50)
##
## Parameters:
## - raw_dot_damage: tick damage before mitigation
## - dot_element: "physical", "chaos", or "fire"
## - hero_fire_res: total fire resistance
## - hero_chaos_res: total chaos resistance
## - current_es: current energy shield amount
##
## Returns: { "life_damage": float, "es_damage": float }
static func calculate_dot_damage_taken(
	raw_dot_damage: float,
	dot_element: String,
	hero_fire_res: int,
	hero_chaos_res: int,
	current_es: float
) -> Dictionary:
	var damage := raw_dot_damage

	# Resistance reduction (element-specific)
	match dot_element:
		"fire":
			var reduction := calculate_resistance_reduction(hero_fire_res)
			damage *= (1.0 - reduction)
		"chaos":
			var reduction := calculate_resistance_reduction(hero_chaos_res)
			damage *= (1.0 - reduction)
		# "physical" (bleed): no resistance exists, full damage passes through

	damage = maxf(0.0, damage)

	# ES/Life split (same as direct hits)
	if current_es > 0.0:
		return apply_es_split(damage, current_es)

	return { "es_damage": 0.0, "life_damage": damage }


## Full defense pipeline: Evasion -> Resistances -> Armor -> ES/Life split.
##
## Defense application order (from CONTEXT.md):
## 1. Evasion: dodge check (attacks only, not spells)
## 2. Resistances: reduce elemental damage portion
## 3. Armor: reduce physical damage portion (physical only, not elemental)
## 4. Remaining damage splits 50/50 to ES and life
##
## Parameters:
## - raw_damage: incoming damage before any mitigation
## - damage_type: "physical", "fire", "cold", or "lightning"
## - is_spell: if true, evasion cannot dodge this attack
## - hero_armor: total armor from gear
## - hero_evasion: total evasion from gear
## - hero_energy_shield: max ES (used to check if hero has ES at all)
## - hero_fire_res/cold_res/lightning_res: total resistances from gear
## - current_es: current energy shield amount (mutable, tracks depletion)
##
## Returns: { "dodged": bool, "life_damage": float, "es_damage": float }
static func calculate_damage_taken(
	raw_damage: float,
	damage_type: String,
	is_spell: bool,
	hero_armor: int,
	hero_evasion: int,
	hero_energy_shield: int,
	hero_fire_res: int,
	hero_cold_res: int,
	hero_lightning_res: int,
	current_es: float
) -> Dictionary:
	var result := {
		"dodged": false,
		"life_damage": 0.0,
		"es_damage": 0.0,
	}

	# Stage 1: Evasion (attacks only, not spells)
	if not is_spell and hero_evasion > 0:
		var dodge_chance := calculate_dodge_chance(hero_evasion)
		if randf() < dodge_chance:
			result["dodged"] = true
			return result

	var damage := raw_damage

	# Stage 2: Resistances (elemental damage only)
	if damage_type in ["fire", "cold", "lightning"]:
		var resistance := 0
		match damage_type:
			"fire":
				resistance = hero_fire_res
			"cold":
				resistance = hero_cold_res
			"lightning":
				resistance = hero_lightning_res
		var reduction := calculate_resistance_reduction(resistance)
		damage *= (1.0 - reduction)

	# Stage 3: Armor (physical damage only)
	if damage_type == "physical" and hero_armor > 0:
		var armor_reduction := calculate_armor_reduction(hero_armor, damage)
		damage *= (1.0 - armor_reduction)

	# Ensure non-negative
	damage = maxf(0.0, damage)

	# Stage 4: ES/Life split
	if current_es > 0.0 and hero_energy_shield > 0:
		var split := apply_es_split(damage, current_es)
		result["life_damage"] = split["life_damage"]
		result["es_damage"] = split["es_damage"]
	else:
		result["life_damage"] = damage

	return result
