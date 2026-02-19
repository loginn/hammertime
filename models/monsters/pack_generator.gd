class_name PackGenerator extends RefCounted

## Generates scaled monster packs for a given area level.
## Follows the same static utility pattern as LootTable and DefenseCalculator.
## Packs are consumed by the combat loop (Phase 15).
## Level 1: 1.0x | Level 25: ~5.07x | Level 50: ~27.5x | Level 75: ~148x

const PACK_COUNT_MIN: int = 8
const PACK_COUNT_MAX: int = 15
const GROWTH_RATE: float = 0.07  # 7% exponential growth per level
const BIOME_BOUNDARIES: Array[int] = [25, 50, 75]  # Dark Forest, Cursed Woods, Shadow Realm start levels

# Pre-computed avg base HP ratios: new_biome / old_biome
# Used to ensure relief dip accounts for base stat jumps
# Forest avg HP: (36+24+30+15+12+45)/6 = 27.0
# Dark Forest avg HP: (42.5+80+17.5+45+35)/5 = 44.0
# Cursed Woods avg HP: (22.5+85+37.5+45+20)/5 = 42.0
# Shadow Realm avg HP: (47.5+100+25+40+65+17.5)/6 = 49.17
const BIOME_STAT_RATIOS: Dictionary = {
	25: 1.63,   # Dark Forest (44.0) / Forest (27.0)
	50: 0.955,  # Cursed Woods (42.0) / Dark Forest (44.0)
	75: 1.17,   # Shadow Realm (49.17) / Cursed Woods (42.0)
}

## Element variance: multipliers applied to scaled base damage to produce min/max range.
## Ratios from project decisions: Physical 1:1.5, Cold 1:2, Fire 1:2.5, Lightning 1:4.
## Formula: for ratio lo:hi, min_mult = 2*lo/(lo+hi), max_mult = 2*hi/(lo+hi).
## Average is always preserved: (min + max) / 2 = base.
const ELEMENT_VARIANCE: Dictionary = {
	"physical": {"min_mult": 0.80, "max_mult": 1.20},
	"cold": {"min_mult": 0.667, "max_mult": 1.333},
	"fire": {"min_mult": 0.571, "max_mult": 1.429},
	"lightning": {"min_mult": 0.40, "max_mult": 1.60},
}


## Returns the difficulty multiplier for an area level.
## Base: 7% compounding per level. Modified by:
## - Boss wall: +10/20/40% spike on the last 3 levels of each biome
## - Relief dip: first level of new biome drops to ~70% of boss wall peak (accounting for base stat jump)
## - Ramp-back: smooth quadratic ease over 8 levels to rejoin base curve
## - Shadow Realm (75+): smooth 10% compounding after initial ramp-back, no repeating boss walls
static func get_level_multiplier(area_level: int) -> float:
	var level: int = area_level
	var base: float = pow(1.0 + GROWTH_RATE, level - 1)

	# 1. Check if level is a biome boundary (exact match) → return relief multiplier
	for boundary in BIOME_BOUNDARIES:
		if level == boundary:
			var stat_ratio: float = BIOME_STAT_RATIOS[boundary]
			# peak_base is the base multiplier at the last level of the previous biome (boundary - 1)
			var peak_base: float = pow(1.0 + GROWTH_RATE, boundary - 2)
			var relief_mult: float = peak_base * (1.0 + 0.40) * 0.70 / stat_ratio
			return relief_mult

	# 2. Check if level is in boss wall zone (within 3 levels before a boundary)
	# Applies to Forest (22-24), Dark Forest (47-49), and Cursed Woods (72-74).
	# Shadow Realm (75+) has no boss walls — there are no boundaries after 75 to trigger them.
	for boundary in BIOME_BOUNDARIES:
		if boundary - 3 <= level and level < boundary:
			var distance_from_boundary: int = boundary - level  # 3, 2, or 1
			var boss_bonus: float
			match distance_from_boundary:
				3: boss_bonus = 0.10  # Was 0.15
				2: boss_bonus = 0.20  # Was 0.35
				1: boss_bonus = 0.40  # Was 0.60
				_: boss_bonus = 0.0
			return base * (1.0 + boss_bonus)

	# 3. Check if level is in ramp-back zone (within 8 levels after a boundary)
	for boundary in BIOME_BOUNDARIES:
		var levels_into_biome: int = level - boundary
		if levels_into_biome >= 1 and levels_into_biome <= 7:
			# Compute the relief value at this boundary
			var stat_ratio: float = BIOME_STAT_RATIOS[boundary]
			var peak_base: float = pow(1.0 + GROWTH_RATE, boundary - 2)
			var relief_value: float = peak_base * (1.0 + 0.40) * 0.70 / stat_ratio
			# Quadratic ease-in ramp from relief back to base curve
			var t: float = float(levels_into_biome) / 8.0
			var ease_t: float = t * t
			var ramp_mult: float = relief_value + (base - relief_value) * ease_t
			return ramp_mult

	# 4. Default → return base multiplier (pure 10% compounding)
	return base


## Selects a random element from biome weights using weighted random.
## Normalizes weights for robustness (same pattern as LootTable.roll_rarity).
## Returns one of "physical", "fire", "cold", "lightning".
static func roll_element(biome: BiomeConfig) -> String:
	var total_weight := 0.0
	for element in biome.element_weights:
		total_weight += biome.element_weights[element]

	if total_weight <= 0.0:
		return biome.primary_element

	var roll := randf() * total_weight
	var accumulated := 0.0
	for element in biome.element_weights:
		accumulated += biome.element_weights[element]
		if roll < accumulated:
			return element

	# Fallback (should never reach with valid weights)
	return biome.primary_element


## Creates a single MonsterPack scaled to the given area level.
## HP and damage scale with level multiplier. Attack speed is NOT scaled
## (preserves type identity: fast imps stay fast, slow bears stay slow).
## Difficulty bonus set based on monster type HP relative to biome average (for drop scaling).
static func create_pack(
	monster_type: MonsterType, area_level: int, element: String, biome: BiomeConfig = null
) -> MonsterPack:
	var multiplier := get_level_multiplier(area_level)
	var pack := MonsterPack.new()
	pack.pack_name = monster_type.type_name
	pack.hp = monster_type.base_hp * multiplier
	pack.max_hp = pack.hp
	# Compute damage range using element variance constants
	var scaled_base := monster_type.base_damage * multiplier
	var variance: Dictionary = ELEMENT_VARIANCE.get(element, ELEMENT_VARIANCE["physical"])
	pack.damage_min = scaled_base * variance["min_mult"]
	pack.damage_max = scaled_base * variance["max_mult"]
	# Backward compat: existing damage field = average of range
	pack.damage = (pack.damage_min + pack.damage_max) / 2.0
	pack.attack_speed = monster_type.base_attack_speed
	pack.element = element

	# Calculate difficulty bonus based on monster type's base_hp relative to biome average
	if biome != null and biome.monster_types.size() > 0:
		var avg_hp := 0.0
		for mt in biome.monster_types:
			avg_hp += mt.base_hp
		avg_hp /= float(biome.monster_types.size())
		pack.difficulty_bonus = 1.5 if monster_type.base_hp > avg_hp else 1.0

	return pack


## Generates 8-15 monster packs for a map at the given area level.
## All packs use the SAME level multiplier (no escalation within a map).
## Monster types are selected randomly from the biome's pool.
## Element is rolled per-pack from the biome's weighted distribution.
static func generate_packs(area_level: int) -> Array[MonsterPack]:
	var biome := BiomeConfig.get_biome_for_level(area_level)
	var pack_count := randi_range(PACK_COUNT_MIN, PACK_COUNT_MAX)
	var packs: Array[MonsterPack] = []

	for i in range(pack_count):
		var monster_type: MonsterType = biome.monster_types.pick_random()
		var element := roll_element(biome)
		var pack := create_pack(monster_type, area_level, element, biome)
		packs.append(pack)

	return packs


## Debug method for development-time verification.
## Prints a formatted summary of generated packs for a given area level.
static func debug_generate(area_level: int) -> void:
	var biome := BiomeConfig.get_biome_for_level(area_level)
	var multiplier := get_level_multiplier(area_level)
	var packs := generate_packs(area_level)

	print("=== Pack Generation: Area Level %d (%s) ===" % [area_level, biome.biome_name])
	print("Multiplier: %.1fx" % multiplier)
	print("Packs: %d" % packs.size())
	print("---")

	var element_counts := {"physical": 0, "fire": 0, "cold": 0, "lightning": 0}
	for i in range(packs.size()):
		var pack := packs[i]
		print(
			"Pack %d: %s | HP: %.0f | DMG: %.1f-%.1f | SPD: %.1f/s | %s"
			% [i + 1, pack.pack_name, pack.hp, pack.damage_min, pack.damage_max, pack.attack_speed, pack.element]
		)
		if pack.element in element_counts:
			element_counts[pack.element] += 1

	print("---")
	print(
		"Element distribution: physical=%d, fire=%d, cold=%d, lightning=%d"
		% [
			element_counts["physical"],
			element_counts["fire"],
			element_counts["cold"],
			element_counts["lightning"],
		]
	)
