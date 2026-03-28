class_name BiomeConfig extends Resource

## Biome configuration with level range, elemental distribution, and monster type pool.
## Each biome declares a primary element (~40% weight) with ~60% distributed across others.
## Biomes are alpha placeholders — designed for easy reconfiguration.

var biome_name: String = ""
var level_min: int = 0
var level_max: int = -1  # -1 = uncapped (Shadow Realm)
var primary_element: String = "physical"
var element_weights: Dictionary = {}  # {"physical": 0.40, "fire": 0.20, ...}
var monster_types: Array[MonsterType] = []

# Lazily initialized biome registry
static var _biomes: Array[BiomeConfig] = []


func _init(
	p_name: String = "",
	p_min: int = 0,
	p_max: int = -1,
	p_element: String = "physical",
	p_weights: Dictionary = {},
	p_types: Array[MonsterType] = []
) -> void:
	biome_name = p_name
	level_min = p_min
	level_max = p_max
	primary_element = p_element
	element_weights = p_weights
	monster_types = p_types


## Returns the biome config for a given area level.
## Compressed biome boundaries: <25 Forest, <50 Dark Forest, <75 Cursed Woods, 75+ Shadow Realm.
static func get_biome_for_level(area_level: int) -> BiomeConfig:
	var biomes := get_biomes()
	for biome in biomes:
		if biome.level_max == -1:
			# Uncapped biome (Shadow Realm) — matches everything above level_min
			if area_level >= biome.level_min:
				return biome
		elif area_level >= biome.level_min and area_level < biome.level_max:
			return biome
	# Fallback to first biome (should never happen with valid config)
	return biomes[0]


## Returns the lazily-initialized biome registry.
static func get_biomes() -> Array[BiomeConfig]:
	if _biomes.is_empty():
		_biomes = _build_biomes()
	return _biomes


static func _build_biomes() -> Array[BiomeConfig]:
	var biomes: Array[BiomeConfig] = []

	# Forest (levels 1-24): Natural beasts, mostly physical
	biomes.append(BiomeConfig.new(
		"Forest", 1, 25, "physical",
		{"physical": 0.40, "fire": 0.20, "cold": 0.20, "lightning": 0.20},
		[
			MonsterType.create("Forest Bear",     20.0, 3.5, 0.8),
			MonsterType.create("Timber Wolf",     14.0, 3.0, 1.2),
			MonsterType.create("Wild Boar",       18.0, 4.0, 0.9),
			MonsterType.create("Venomous Spider",  9.0, 3.5, 1.8),
			MonsterType.create("Forest Sprite",    7.0, 2.5, 2.0),
			MonsterType.create("Bramble Golem",   26.0, 2.0, 0.6),
		]
	))

	# Dark Forest (levels 25-49): Corrupted/burning, mostly fire
	biomes.append(BiomeConfig.new(
		"Dark Forest", 25, 50, "fire",
		{"fire": 0.40, "physical": 0.25, "cold": 0.20, "lightning": 0.15},
		[
			MonsterType.create("Ember Hound", 42.5, 15.0, 1.5),
			MonsterType.create("Charred Treant", 80.0, 11.0, 0.5),
			MonsterType.create("Flame Wisp", 17.5, 16.0, 2.2),
			MonsterType.create("Ash Stalker", 45.0, 13.0, 1.1),
			MonsterType.create("Cinder Beetle", 35.0, 9.0, 1.7),
		]
	))

	# Cursed Woods (levels 50-74): Frozen/cursed, mostly cold
	biomes.append(BiomeConfig.new(
		"Cursed Woods", 50, 75, "cold",
		{"cold": 0.40, "lightning": 0.25, "fire": 0.20, "physical": 0.15},
		[
			MonsterType.create("Frost Wraith", 22.5, 18.0, 1.6),
			MonsterType.create("Frozen Troll", 85.0, 12.0, 0.5),
			MonsterType.create("Ice Crawler", 37.5, 14.0, 1.3),
			MonsterType.create("Cursed Dryad", 45.0, 15.0, 0.9),
			MonsterType.create("Blizzard Imp", 20.0, 11.0, 2.3),
		]
	))

	# Shadow Realm (levels 75+): Eldritch horrors, mostly lightning
	biomes.append(BiomeConfig.new(
		"Shadow Realm", 75, -1, "lightning",
		{"lightning": 0.40, "fire": 0.25, "cold": 0.25, "physical": 0.10},
		[
			MonsterType.create("Void Stalker", 47.5, 20.0, 1.4),
			MonsterType.create("Eldritch Horror", 100.0, 16.0, 0.4),
			MonsterType.create("Storm Phantom", 25.0, 19.0, 2.0),
			MonsterType.create("Shadow Fiend", 40.0, 17.0, 1.2),
			MonsterType.create("Abyssal Crawler", 65.0, 13.0, 0.8),
			MonsterType.create("Rift Elemental", 17.5, 22.0, 1.8),
		]
	))

	return biomes
