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
## Matches existing biome boundaries: <100 Forest, <200 Dark Forest, <300 Cursed Woods, 300+ Shadow Realm.
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

	# Forest (levels 1-99): Natural beasts, mostly physical
	biomes.append(BiomeConfig.new(
		"Forest", 1, 100, "physical",
		{"physical": 0.40, "fire": 0.20, "cold": 0.20, "lightning": 0.20},
		[
			MonsterType.create("Forest Bear", 120.0, 12.0, 0.8),
			MonsterType.create("Timber Wolf", 80.0, 10.0, 1.2),
			MonsterType.create("Wild Boar", 100.0, 14.0, 0.9),
			MonsterType.create("Venomous Spider", 50.0, 11.0, 1.8),
			MonsterType.create("Forest Sprite", 40.0, 8.0, 2.0),
			MonsterType.create("Bramble Golem", 150.0, 7.0, 0.6),
		]
	))

	# Dark Forest (levels 100-199): Corrupted/burning, mostly fire
	biomes.append(BiomeConfig.new(
		"Dark Forest", 100, 200, "fire",
		{"fire": 0.40, "physical": 0.25, "cold": 0.20, "lightning": 0.15},
		[
			MonsterType.create("Ember Hound", 85.0, 15.0, 1.5),
			MonsterType.create("Charred Treant", 160.0, 11.0, 0.5),
			MonsterType.create("Flame Wisp", 35.0, 16.0, 2.2),
			MonsterType.create("Ash Stalker", 90.0, 13.0, 1.1),
			MonsterType.create("Cinder Beetle", 70.0, 9.0, 1.7),
		]
	))

	# Cursed Woods (levels 200-299): Frozen/cursed, mostly cold
	biomes.append(BiomeConfig.new(
		"Cursed Woods", 200, 300, "cold",
		{"cold": 0.40, "lightning": 0.25, "fire": 0.20, "physical": 0.15},
		[
			MonsterType.create("Frost Wraith", 45.0, 18.0, 1.6),
			MonsterType.create("Frozen Troll", 170.0, 12.0, 0.5),
			MonsterType.create("Ice Crawler", 75.0, 14.0, 1.3),
			MonsterType.create("Cursed Dryad", 90.0, 15.0, 0.9),
			MonsterType.create("Blizzard Imp", 40.0, 11.0, 2.3),
		]
	))

	# Shadow Realm (levels 300+): Eldritch horrors, mostly lightning
	biomes.append(BiomeConfig.new(
		"Shadow Realm", 300, -1, "lightning",
		{"lightning": 0.40, "fire": 0.25, "cold": 0.25, "physical": 0.10},
		[
			MonsterType.create("Void Stalker", 95.0, 20.0, 1.4),
			MonsterType.create("Eldritch Horror", 200.0, 16.0, 0.4),
			MonsterType.create("Storm Phantom", 50.0, 19.0, 2.0),
			MonsterType.create("Shadow Fiend", 80.0, 17.0, 1.2),
			MonsterType.create("Abyssal Crawler", 130.0, 13.0, 0.8),
			MonsterType.create("Rift Elemental", 35.0, 22.0, 1.8),
		]
	))

	return biomes
