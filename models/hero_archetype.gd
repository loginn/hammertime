class_name HeroArchetype extends Resource

enum Archetype { STR, DEX, INT }
enum Subvariant { HIT, DOT, ELEMENTAL }

var id: String
var archetype: Archetype
var subvariant: Subvariant
var title: String
var color: Color
var spell_user: bool
var passive_bonuses: Dictionary

const REGISTRY: Dictionary = {
	# STR heroes -- Red -- attack_damage_more: 0.25 channel bonus (D-04)
	"str_hit": {
		"archetype": Archetype.STR,
		"subvariant": Subvariant.HIT,
		"title": "The Berserker",           # D-01 format
		"color": Color("#C0392B"),           # deep red (D-02)
		"spell_user": false,                 # D-07
		"passive_bonuses": {
			"attack_damage_more": 0.25,      # D-04 STR channel
			"physical_damage_more": 0.25,    # D-05 Hit subvariant
		},
	},
	"str_dot": {
		"archetype": Archetype.STR,
		"subvariant": Subvariant.DOT,
		"title": "The Reaver",
		"color": Color("#E74C3C"),           # medium red
		"spell_user": false,
		"passive_bonuses": {
			"attack_damage_more": 0.25,      # D-04 STR channel
			"bleed_chance_more": 0.20,       # D-05 DoT: STR=bleed
			"bleed_damage_more": 0.15,       # D-05 DoT damage
		},
	},
	"str_elem": {
		"archetype": Archetype.STR,
		"subvariant": Subvariant.ELEMENTAL,
		"title": "The Fire Knight",
		"color": Color("#FF6B6B"),           # bright red-orange
		"spell_user": false,
		"passive_bonuses": {
			"attack_damage_more": 0.25,      # D-04 STR channel
			"fire_damage_more": 0.25,        # D-05/D-09 STR elem=fire
		},
	},
	# DEX heroes -- Green -- damage_more: 0.15 channel bonus (D-04)
	"dex_hit": {
		"archetype": Archetype.DEX,
		"subvariant": Subvariant.HIT,
		"title": "The Assassin",
		"color": Color("#27AE60"),           # deep green
		"spell_user": false,
		"passive_bonuses": {
			"damage_more": 0.15,             # D-04 DEX channel (general)
			"physical_damage_more": 0.25,    # D-05 Hit subvariant
		},
	},
	"dex_dot": {
		"archetype": Archetype.DEX,
		"subvariant": Subvariant.DOT,
		"title": "The Plague Hunter",
		"color": Color("#2ECC71"),           # medium green
		"spell_user": false,
		"passive_bonuses": {
			"damage_more": 0.15,             # D-04 DEX channel
			"poison_chance_more": 0.20,      # D-05 DoT: DEX=poison
			"poison_damage_more": 0.15,      # D-05 DoT damage
		},
	},
	"dex_elem": {
		"archetype": Archetype.DEX,
		"subvariant": Subvariant.ELEMENTAL,
		"title": "The Frost Ranger",
		"color": Color("#A8E6CF"),           # light mint green
		"spell_user": false,
		"passive_bonuses": {
			"damage_more": 0.15,             # D-04 DEX channel
			"cold_damage_more": 0.25,        # D-05/D-09 DEX elem=cold
		},
	},
	# INT heroes -- Blue -- spell_damage_more: 0.25 channel bonus (D-04), spell_user: true (D-07)
	"int_hit": {
		"archetype": Archetype.INT,
		"subvariant": Subvariant.HIT,
		"title": "The Arcanist",             # D-08 arcane force/gravity
		"color": Color("#2980B9"),           # deep blue
		"spell_user": true,
		"passive_bonuses": {
			"spell_damage_more": 0.25,       # D-04 INT channel
			"physical_damage_more": 0.25,    # D-05 Hit + D-08 physical-spell
		},
	},
	"int_dot": {
		"archetype": Archetype.INT,
		"subvariant": Subvariant.DOT,
		"title": "The Warlock",
		"color": Color("#3498DB"),           # medium blue
		"spell_user": true,
		"passive_bonuses": {
			"spell_damage_more": 0.25,       # D-04 INT channel
			"burn_chance_more": 0.20,        # D-05 DoT: INT=burn
			"burn_damage_more": 0.15,        # D-05 DoT damage
		},
	},
	"int_elem": {
		"archetype": Archetype.INT,
		"subvariant": Subvariant.ELEMENTAL,
		"title": "The Storm Mage",
		"color": Color("#7FB3D3"),           # light blue
		"spell_user": true,
		"passive_bonuses": {
			"spell_damage_more": 0.25,       # D-04 INT channel
			"lightning_damage_more": 0.25,   # D-05/D-09 INT elem=lightning
		},
	},
}


const BONUS_LABELS: Dictionary = {
	"attack_damage_more": "Attack Damage",
	"physical_damage_more": "Physical Damage",
	"damage_more": "Damage",
	"bleed_chance_more": "Bleed Chance",
	"bleed_damage_more": "Bleed Damage",
	"poison_chance_more": "Poison Chance",
	"poison_damage_more": "Poison Damage",
	"burn_chance_more": "Burn Chance",
	"burn_damage_more": "Burn Damage",
	"fire_damage_more": "Fire Damage",
	"cold_damage_more": "Cold Damage",
	"lightning_damage_more": "Lightning Damage",
	"spell_damage_more": "Spell Damage",
}

static func format_bonuses(bonuses: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in bonuses:
		var pct: int = roundi(bonuses[key] * 100)
		var label: String = BONUS_LABELS.get(key, key)
		result.append("+%d%% %s" % [pct, label])
	return result


static func from_id(hero_id: String) -> HeroArchetype:
	if hero_id not in REGISTRY:
		push_warning("HeroArchetype.from_id: unknown id '%s'" % hero_id)
		return null
	var data: Dictionary = REGISTRY[hero_id]
	var h := HeroArchetype.new()
	h.id = hero_id
	h.archetype = data["archetype"]
	h.subvariant = data["subvariant"]
	h.title = data["title"]
	h.color = data["color"]
	h.spell_user = data["spell_user"]
	h.passive_bonuses = data["passive_bonuses"].duplicate()
	return h


static func generate_choices() -> Array[HeroArchetype]:
	var by_archetype: Dictionary = {
		Archetype.STR: [],
		Archetype.DEX: [],
		Archetype.INT: [],
	}
	for hero_id in REGISTRY:
		var data: Dictionary = REGISTRY[hero_id]
		by_archetype[data["archetype"]].append(hero_id)
	var choices: Array[HeroArchetype] = []
	for arch in [Archetype.STR, Archetype.DEX, Archetype.INT]:
		var ids: Array = by_archetype[arch]
		choices.append(from_id(ids.pick_random()))
	return choices
