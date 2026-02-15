class_name BasicBoots extends Boots


func _init() -> void:
	self.rarity = Rarity.NORMAL
	self.item_name = "Basic Boots"
	self.tier = 8
	self.valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.SPEED, Tag.ENERGY_SHIELD]
	self.original_base_armor = 8
	self.original_base_movement_speed = 0
	self.original_base_energy_shield = 0
	self.base_armor = 8
	self.base_movement_speed = 0
	self.base_energy_shield = 0
	self.implicit = Implicit.new(
		"Movement Speed", Affix.AffixType.IMPLICIT, 1, 3, [Tag.SPEED, Tag.MOVEMENT]
	)
	self.update_value()
