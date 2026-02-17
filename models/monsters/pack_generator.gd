class_name PackGenerator extends RefCounted

## Generates scaled monster packs for a given area level.
## Follows the same static utility pattern as LootTable and DefenseCalculator.
## Packs are consumed by the combat loop (Phase 15).

const PACK_COUNT_MIN: int = 8
const PACK_COUNT_MAX: int = 15
const GROWTH_RATE: float = 0.06  # 6% exponential growth per level


## Returns the exponential scaling multiplier for an area level.
## Compound growth: base * (1 + rate)^(level - 1)
## Level 1: 1.0x | Level 100: ~321x | Level 300: ~42,012x
static func get_level_multiplier(area_level: int) -> float:
	return pow(1.0 + GROWTH_RATE, area_level - 1)


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
	pack.damage = monster_type.base_damage * multiplier
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
			"Pack %d: %s | HP: %.0f | DMG: %.1f | SPD: %.1f/s | %s"
			% [i + 1, pack.pack_name, pack.hp, pack.damage, pack.attack_speed, pack.element]
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
