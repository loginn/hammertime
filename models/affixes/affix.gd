class_name Affix extends Resource

enum AffixType { IMPLICIT, PREFIX, SUFFIX }

var affix_name: String
var type: AffixType
var min_value: int
var max_value: int
var value: int
var tier: int
var tags: Array[String]
var stat_types: Array[int] = []
var tier_range: Vector2i = Vector2i(1, 8)
var base_min: int = 0
var base_max: int = 0

# Base (unscaled) template bounds for flat damage affixes — stored for from_affix() cloning
var base_dmg_min_lo: int = 0
var base_dmg_min_hi: int = 0
var base_dmg_max_lo: int = 0
var base_dmg_max_hi: int = 0

# Template bounds for flat damage affixes — NEVER changed after construction (tier-scaled)
var dmg_min_lo: int = 0   # Lowest possible add_min for this tier
var dmg_min_hi: int = 0   # Highest possible add_min for this tier
var dmg_max_lo: int = 0   # Lowest possible add_max for this tier
var dmg_max_hi: int = 0   # Highest possible add_max for this tier

# Rolled results — set at item creation, re-rolled by Tuning Hammer
var add_min: int = 0      # Rolled minimum damage contribution per hit
var add_max: int = 0      # Rolled maximum damage contribution per hit


func _init(
	p_name: String = "",
	p_type: AffixType = AffixType.PREFIX,
	p_min: int = 0,
	p_max: int = 0,
	p_tags: Array[String] = [],
	p_stat_types: Array[int] = [],
	p_tier_range: Vector2i = Vector2i(1, 8),
	p_dmg_min_lo: int = 0,
	p_dmg_min_hi: int = 0,
	p_dmg_max_lo: int = 0,
	p_dmg_max_hi: int = 0
) -> void:
	self.affix_name = p_name
	self.type = p_type
	self.tier_range = p_tier_range
	self.base_min = p_min
	self.base_max = p_max
	self.tier = randi_range(tier_range.x, tier_range.y)
	self.tags = p_tags
	self.stat_types = p_stat_types
	# Tier 1 is highest, so higher tier numbers = lower values
	self.min_value = p_min * (tier_range.y + 1 - tier)
	self.max_value = p_max * (tier_range.y + 1 - tier)
	self.value = randi_range(self.min_value, self.max_value)

	# Store unscaled base damage bounds (for from_affix() cloning)
	self.base_dmg_min_lo = p_dmg_min_lo
	self.base_dmg_min_hi = p_dmg_min_hi
	self.base_dmg_max_lo = p_dmg_max_lo
	self.base_dmg_max_hi = p_dmg_max_hi

	# Store tier-scaled template bounds
	self.dmg_min_lo = p_dmg_min_lo * (tier_range.y + 1 - tier)
	self.dmg_min_hi = p_dmg_min_hi * (tier_range.y + 1 - tier)
	self.dmg_max_lo = p_dmg_max_lo * (tier_range.y + 1 - tier)
	self.dmg_max_hi = p_dmg_max_hi * (tier_range.y + 1 - tier)

	# Roll initial damage range if this is a flat damage affix
	if dmg_min_hi > 0 or dmg_max_hi > 0:
		self.add_min = randi_range(self.dmg_min_lo, self.dmg_min_hi)
		self.add_max = randi_range(self.dmg_max_lo, self.dmg_max_hi)
		# Guard: ensure add_min <= add_max
		if self.add_min > self.add_max:
			var tmp = self.add_min
			self.add_min = self.add_max
			self.add_max = tmp
	elif p_type == AffixType.IMPLICIT and (self.min_value > 0 or self.max_value > 0):
		# Implicits with flat damage use min_value/max_value as add_min/add_max
		# (they don't pass dmg bounds but still need add_min/add_max for stat routing)
		self.add_min = self.min_value
		self.add_max = self.max_value


func is_prefix() -> bool:
	return self.type == AffixType.PREFIX


func reroll() -> void:
	if dmg_min_hi > 0 or dmg_max_hi > 0:
		# Damage range affix: re-roll from TEMPLATE bounds (never from rolled values)
		self.add_min = randi_range(self.dmg_min_lo, self.dmg_min_hi)
		self.add_max = randi_range(self.dmg_max_lo, self.dmg_max_hi)
		if self.add_min > self.add_max:
			var tmp = self.add_min
			self.add_min = self.add_max
			self.add_max = tmp
	else:
		# Non-damage affix: existing scalar reroll unchanged
		self.value = randi_range(self.min_value, self.max_value)


func to_dict() -> Dictionary:
	return {
		"affix_name": affix_name,
		"type": int(type),
		"value": value,
		"tier": tier,
		"tags": Array(tags),
		"stat_types": Array(stat_types),
		"tier_range_x": tier_range.x,
		"tier_range_y": tier_range.y,
		"base_min": base_min,
		"base_max": base_max,
		"min_value": min_value,
		"max_value": max_value,
		"base_dmg_min_lo": base_dmg_min_lo,
		"base_dmg_min_hi": base_dmg_min_hi,
		"base_dmg_max_lo": base_dmg_max_lo,
		"base_dmg_max_hi": base_dmg_max_hi,
		"dmg_min_lo": dmg_min_lo,
		"dmg_min_hi": dmg_min_hi,
		"dmg_max_lo": dmg_max_lo,
		"dmg_max_hi": dmg_max_hi,
		"add_min": add_min,
		"add_max": add_max,
	}


static func from_dict(data: Dictionary) -> Affix:
	var tags_array: Array[String] = []
	for t in data.get("tags", []):
		tags_array.append(str(t))

	var stat_types_array: Array[int] = []
	for s in data.get("stat_types", []):
		stat_types_array.append(int(s))

	var tier_range_vec := Vector2i(
		int(data.get("tier_range_x", 1)),
		int(data.get("tier_range_y", 8))
	)

	var affix := Affix.new(
		str(data.get("affix_name", "")),
		int(data.get("type", 0)) as AffixType,
		int(data.get("base_min", 0)),
		int(data.get("base_max", 0)),
		tags_array,
		stat_types_array,
		tier_range_vec
	)

	# Overwrite randomized fields with saved values
	affix.tier = int(data.get("tier", affix.tier))
	affix.value = int(data.get("value", affix.value))
	affix.min_value = int(data.get("min_value", affix.min_value))
	affix.max_value = int(data.get("max_value", affix.max_value))
	affix.base_dmg_min_lo = int(data.get("base_dmg_min_lo", 0))
	affix.base_dmg_min_hi = int(data.get("base_dmg_min_hi", 0))
	affix.base_dmg_max_lo = int(data.get("base_dmg_max_lo", 0))
	affix.base_dmg_max_hi = int(data.get("base_dmg_max_hi", 0))
	affix.dmg_min_lo = int(data.get("dmg_min_lo", 0))
	affix.dmg_min_hi = int(data.get("dmg_min_hi", 0))
	affix.dmg_max_lo = int(data.get("dmg_max_lo", 0))
	affix.dmg_max_hi = int(data.get("dmg_max_hi", 0))
	affix.add_min = int(data.get("add_min", 0))
	affix.add_max = int(data.get("add_max", 0))

	return affix


func display() -> void:
	pass
