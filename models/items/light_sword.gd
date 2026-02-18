class_name LightSword extends Weapon


func get_item_type_string() -> String:
	return "LightSword"


func _init() -> void:
	self.rarity = Rarity.NORMAL
	self.item_name = "Light Sword"
	self.tier = 8  # Light Sword is tier 8 (weakest)
	self.valid_tags = [Tag.PHYSICAL, Tag.ATTACK, Tag.CRITICAL, Tag.WEAPON]
	self.base_damage_type = Tag.PHYSICAL
	self.implicit = Implicit.new(
		"Attack Speed", Affix.AffixType.IMPLICIT, 2, 5, [Tag.SPEED, Tag.ATTACK], [Tag.StatType.INCREASED_SPEED]
	)
	self.base_damage_min = 8
	self.base_damage_max = 12
	self.base_speed = 1
	self.base_attack_speed = 1.8  # Fast sword: ~0.56s between hits
	self.update_value()
