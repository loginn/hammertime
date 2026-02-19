class_name BasicArmor extends Armor


func get_item_type_string() -> String:
	return "BasicArmor"


func _init() -> void:
	self.rarity = Rarity.NORMAL
	self.item_name = "Basic Armor"
	self.tier = 8
	self.valid_tags = [Tag.DEFENSE, Tag.ARMOR, Tag.ENERGY_SHIELD]
	self.base_armor = 5
	self.base_energy_shield = 0
	self.base_health = 0
	self.computed_armor = 0
	self.computed_energy_shield = 0
	self.computed_health = 0
	self.implicit = null
	self.update_value()
