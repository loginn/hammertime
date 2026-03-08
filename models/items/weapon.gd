class_name Weapon extends Item

var base_damage_min: int = 0
var base_damage_max: int = 0
var base_damage: int:
	get: return (base_damage_min + base_damage_max) / 2
var base_damage_type: String
var base_speed: int
var dps: float
var phys_dps: int
var bleed_dps: int
var lightning_dps: int
var cold_dps: int
var fire_dps: int
var crit_chance: float = 5.0  # Base 5% crit chance
var crit_damage: float = 150.0  # Base 150% crit damage
var base_attack_speed: float = 1.0  # Attacks per second for combat timer (separate from base_speed DPS multiplier)

# Spell damage fields (default 0 for non-spell weapons)
var base_spell_damage_min: int = 0
var base_spell_damage_max: int = 0
var base_spell_damage: int:
	get: return (base_spell_damage_min + base_spell_damage_max) / 2
var base_cast_speed: float = 0.0
var spell_dps: float = 0.0


func update_value() -> void:
	var all_affixes := self.prefixes + self.suffixes
	all_affixes.append(self.implicit)
	self.dps = StatCalculator.calculate_dps(
		self.base_damage, self.base_speed, all_affixes, self.crit_chance, self.crit_damage
	)
	self.spell_dps = StatCalculator.calculate_spell_dps(
		self.base_spell_damage, self.base_cast_speed, all_affixes, self.crit_chance, self.crit_damage
	)
