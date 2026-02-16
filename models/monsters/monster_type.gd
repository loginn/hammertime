class_name MonsterType extends Resource

## Named monster type template with base stats.
## Base stats are pre-scaling — PackGenerator applies area level multiplier.
## Attack speed is NOT scaled (preserves type identity: fast imps stay fast, slow bears stay slow).

var type_name: String = ""
var base_hp: float = 0.0
var base_damage: float = 0.0
var base_attack_speed: float = 1.0  # Attacks per second


func _init(
	p_name: String = "",
	p_hp: float = 0.0,
	p_dmg: float = 0.0,
	p_speed: float = 1.0
) -> void:
	type_name = p_name
	base_hp = p_hp
	base_damage = p_dmg
	base_attack_speed = p_speed


static func create(
	p_name: String, p_hp: float, p_dmg: float, p_speed: float
) -> MonsterType:
	var mt := MonsterType.new(p_name, p_hp, p_dmg, p_speed)
	return mt
