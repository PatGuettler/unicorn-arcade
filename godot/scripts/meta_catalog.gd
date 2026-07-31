class_name MetaCatalog
extends RefCounted

const DATA_PATH := "res://data/meta_catalog.json"
static var _cache: Dictionary = {}


static func data() -> Dictionary:
	if _cache.is_empty():
		var file := FileAccess.open(DATA_PATH, FileAccess.READ)
		if file == null:
			return {}
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_cache = parsed
	return _cache


static func companions() -> Array:
	return data().get("companions", [])


static func furniture() -> Array:
	return data().get("furniture", [])


static func categories() -> Array:
	return data().get("categories", [])


static func companion(companion_id: String) -> Dictionary:
	for item in companions():
		if str(item.get("id", "")) == companion_id:
			return item
	return {}


static func furniture_item(item_id: String) -> Dictionary:
	for item in furniture():
		if str(item.get("id", "")) == item_id:
			return item
	return {}


static func filtered_furniture(category: String, query: String) -> Array:
	var normalized := query.strip_edges().to_lower()
	return furniture().filter(func(item: Dictionary) -> bool:
		var category_match := category.is_empty() or category == "all" or str(item.get("category", "")) == category
		var query_match := normalized.is_empty() or normalized in str(item.get("name", "")).to_lower() or normalized in str(item.get("desc", "")).to_lower() or normalized in str(item.get("category", "")).to_lower()
		return category_match and query_match
	)
