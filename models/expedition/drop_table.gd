class_name DropTable extends RefCounted

var entries: Array[Dictionary] = []
var drop_rolls: int = 1


static func create_entry(
	type: String,
	key: String,
	material_tier: int,
	weight: int,
	qty_min: int,
	qty_max: int,
	guaranteed: bool
) -> Dictionary:
	return {
		"type": type,
		"key": key,
		"material_tier": material_tier,
		"weight": weight,
		"qty_min": qty_min,
		"qty_max": qty_max,
		"guaranteed": guaranteed,
	}


func roll() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for entry in entries:
		if entry["guaranteed"]:
			results.append(entry)

	var non_guaranteed: Array[Dictionary] = []
	var total_weight: int = 0
	for entry in entries:
		if not entry["guaranteed"]:
			non_guaranteed.append(entry)
			total_weight += entry["weight"]

	if total_weight <= 0 or non_guaranteed.is_empty():
		return results

	for _i in range(drop_rolls):
		var roll_value: int = randi() % total_weight
		var accumulated: int = 0
		for entry in non_guaranteed:
			accumulated += entry["weight"]
			if roll_value < accumulated:
				results.append(entry)
				break

	return results
