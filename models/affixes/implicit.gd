class_name Implicit extends Affix


static func from_dict(data: Dictionary) -> Implicit:
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

	var imp := Implicit.new(
		str(data.get("affix_name", "")),
		int(data.get("type", 0)) as AffixType,
		int(data.get("base_min", 0)),
		int(data.get("base_max", 0)),
		tags_array,
		stat_types_array,
		tier_range_vec
	)

	# Overwrite randomized fields with saved values
	imp.tier = int(data.get("tier", imp.tier))
	imp.value = int(data.get("value", imp.value))
	imp.min_value = int(data.get("min_value", imp.min_value))
	imp.max_value = int(data.get("max_value", imp.max_value))

	return imp
