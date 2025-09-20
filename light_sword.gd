class_name LightSword extends Item

func _init():
	self.item_name = "Light Sword"
	self.valid_tags = [Tag.PHYSICAL, Tag.ATTACK]
	self.implicit = Implicit.new("Attack Speed", Affix.AffixType.IMPLICIT, 2, 5, [Tag.PHYSICAL, Tag.ATTACK])
