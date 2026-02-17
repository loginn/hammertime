class_name BasicRing extends Ring


func get_item_type_string() -> String:
	return "BasicRing"


func _init() -> void:
	self.rarity = Rarity.NORMAL
	self.item_name = "Basic Ring"
	self.tier = 8
	self.valid_tags = [Tag.ATTACK, Tag.CRITICAL, Tag.SPEED, Tag.WEAPON, Tag.DEFENSE]
	self.base_damage = 3
	self.base_damage_type = Tag.PHYSICAL
	self.base_speed = 1
	self.crit_chance = 5.0
	self.crit_damage = 150.0
	self.implicit = Implicit.new(
		"Crit Chance", Affix.AffixType.IMPLICIT, 1, 2, [Tag.CRITICAL, Tag.ATTACK], [Tag.StatType.CRIT_CHANCE]
	)
	self.update_value()
