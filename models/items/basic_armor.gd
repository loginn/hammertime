class_name BasicArmor extends Armor


func _init() -> void:
	self.rarity = Rarity.NORMAL
	self.item_name = "Basic Armor"
	self.tier = 8
	self.valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.ENERGY_SHIELD]
	self.original_base_armor = 0
	self.original_base_energy_shield = 0
	self.original_base_health = 0
	self.base_armor = 0
	self.base_energy_shield = 0
	self.base_health = 0
	self.implicit = Implicit.new("Armor", Affix.AffixType.IMPLICIT, 3, 8, [Tag.ARMOR, Tag.DEFENSE], [Tag.StatType.FLAT_ARMOR])
	self.update_value()
