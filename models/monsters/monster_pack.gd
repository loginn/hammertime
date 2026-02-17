class_name MonsterPack extends Resource

## Scaled monster pack instance for combat.
## Created by PackGenerator with area-level-scaled stats from MonsterType templates.
## Each pack deals a single elemental damage type. Combat loop (Phase 15) consumes these.

var pack_name: String = ""
var hp: float = 0.0
var max_hp: float = 0.0
var damage: float = 0.0
var attack_speed: float = 1.0  # Attacks per second (from MonsterType, not scaled)
var element: String = "physical"  # "physical", "fire", "cold", "lightning"
var difficulty_bonus: float = 1.0  # Drop rate multiplier based on pack toughness (1.0 normal, 1.5 tough)


func is_alive() -> bool:
	return hp > 0.0


func take_damage(amount: float) -> void:
	hp -= amount
	hp = maxf(0.0, hp)


func get_hp_percentage() -> float:
	if max_hp <= 0.0:
		return 0.0
	return hp / max_hp
