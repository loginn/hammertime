class_name BasicHelmet extends Helmet


func get_item_type_string() -> String:
	return "BasicHelmet"


func _init() -> void:
	self.rarity = Rarity.NORMAL
	self.item_name = "Basic Helmet"
	self.tier = 8
	self.valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.ENERGY_SHIELD, Tag.MANA]
	self.base_armor = 3
	self.base_energy_shield = 0
	self.base_mana = 0
	self.computed_armor = 0
	self.computed_energy_shield = 0
	self.computed_mana = 0
	self.implicit = null
	self.update_value()
