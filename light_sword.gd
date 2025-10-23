class_name LightSword extends Weapon

func _init():
	self.item_name = "Light Sword"
	self.tier = 8  # Light Sword is tier 8 (weakest)
	self.valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL]
	self.base_damage_type = Tag.PHYSICAL
	self.implicit = Implicit.new("Attack Speed", Affix.AffixType.IMPLICIT, 2, 5, [Tag.SPEED, Tag.ATTACK])
	self.base_damage = 10
	self.base_speed = 1
	self.dps = self.compute_dps()
