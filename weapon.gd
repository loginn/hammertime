class_name Weapon extends Item

var base_damage: int
var base_damage_type: String
var base_speed: int
var dps: int
var phys_dps: int
var bleed_dps: int
var lightning_dps: int
var cold_dps: int
var fire_dps: int

func update_value():
	self.dps = self.compute_dps()

func compute_dps() -> int:
	var affixes = self.prefixes + self.suffixes
	affixes.append(self.implicit)
	
	var new_spd = self.base_speed
	var new_dps = self.base_damage
	
	for affix: Affix in affixes:
	# compute base damage
		if Tag.PHYSICAL in affix.tags and Tag.FLAT in affix.tags:
			new_dps += affix.value
			print(new_dps)
		if Tag.PHYSICAL in affix.tags and Tag.PERCENT in affix.tags:
			new_dps *= (1 + (affix.value / 100))
	# compute attack speed
		if Tag.SPEED in affix.tags:
			new_spd *= affix.value
	new_dps *= new_spd
	return new_dps
