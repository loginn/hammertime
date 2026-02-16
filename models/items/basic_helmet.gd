class_name BasicHelmet extends Helmet


func _init() -> void:
	self.rarity = Rarity.NORMAL
	self.item_name = "Basic Helmet"
	self.tier = 8
	self.valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.ENERGY_SHIELD, Tag.MANA]
	self.original_base_armor = 0
	self.original_base_energy_shield = 0
	self.original_base_mana = 0
	self.base_armor = 0
	self.base_energy_shield = 0
	self.base_mana = 0
	self.implicit = Implicit.new("Armor", Affix.AffixType.IMPLICIT, 2, 5, [Tag.ARMOR, Tag.DEFENSE], [Tag.StatType.FLAT_ARMOR])
	self.update_value()
