class_name RoomRules
extends RefCounted

const GRID_STEP := 8.0
const SELL_RATIO := 0.5


static func snap(value: float, enabled := true) -> float:
	return round(value / GRID_STEP) * GRID_STEP if enabled else value


static func sell_refund(price: int) -> int:
	return int(floor(price * SELL_RATIO))


static func next_z(items: Array) -> int:
	var result := 0
	for item in items:
		result = maxi(result, int(item.get("z_index", 0)))
	return result + 1


static func normalized(item: Dictionary, fallback_index := 0) -> Dictionary:
	return {
		"instance_id": str(item.get("instance_id", "%d_%d" % [Time.get_ticks_msec(), fallback_index])),
		"item_id": str(item.get("item_id", "")),
		"x": float(item.get("x", 50.0)),
		"y": float(item.get("y", 50.0)),
		"rotation": int(item.get("rotation", 0)),
		"scale": float(item.get("scale", 1.0)),
		"z_index": int(item.get("z_index", fallback_index + 1)),
	}


static func reorder(items: Array, instance_id: String, direction: String) -> Array:
	var sorted := items.duplicate(true)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("z_index", 0)) < int(b.get("z_index", 0)))
	var index := -1
	for candidate in sorted.size():
		if str(sorted[candidate].get("instance_id", "")) == instance_id:
			index = candidate
			break
	if index < 0:
		return items
	var swap_index := index + 1 if direction == "front" else index - 1
	if swap_index < 0 or swap_index >= sorted.size():
		return sorted
	var old_z := int(sorted[index].get("z_index", index + 1))
	sorted[index]["z_index"] = int(sorted[swap_index].get("z_index", swap_index + 1))
	sorted[swap_index]["z_index"] = old_z
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("z_index", 0)) < int(b.get("z_index", 0)))
	return sorted
