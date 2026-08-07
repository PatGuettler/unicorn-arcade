extends Node

const SAVE_VERSION := 4
const SAVE_PATH := "user://unicorn_arcade_v2.json"


func default_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"player": {
			"name": "",
			"coins": 1000,
			"equipped_companion": "sparkle",
		},
		"owned_companions": ["sparkle"],
		"progress": {},
		"inventory": {"companion_sparkle": 1},
		"rooms": {},
		"settings": {
			"music": true,
			"sound": true,
			"reduced_motion": false,
			"tutorials_enabled": true,
		},
		"tutorials": {},
	}


func load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_state()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_state()
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_state()
	return _migrate(parsed)


func save_state(state: Dictionary) -> bool:
	state["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state, "  "))
	file.flush()
	return true


func _migrate(source: Dictionary) -> Dictionary:
	var result := default_state()
	var version := int(source.get("version", 1))
	if version <= 1:
		var old_player: Dictionary = source.get("player", {})
		result["player"]["name"] = str(old_player.get("name", source.get("name", "")))
		result["player"]["coins"] = int(old_player.get("coins", source.get("coins", 1000)))
		result["player"]["equipped_companion"] = str(source.get("equippedCompanion", "sparkle"))
		result["owned_companions"] = source.get("ownedCompanions", ["sparkle"])
		result["progress"] = source.get("progress", {})
		var old_furniture: Dictionary = source.get("furniture", {})
		result["inventory"] = old_furniture.get("inventory", source.get("inventory", {}))
		result["rooms"] = old_furniture.get("placements", source.get("rooms", {}))
	else:
		for key in result.keys():
			if source.has(key):
				result[key] = source[key]
	_normalize_meta(result)
	_normalize_learning_state(result, source, version)
	result["version"] = SAVE_VERSION
	return result


func _normalize_meta(state: Dictionary) -> void:
	if not state.get("inventory") is Dictionary:
		state["inventory"] = {}
	if not state.get("rooms") is Dictionary:
		state["rooms"] = {}
	if not state.get("owned_companions") is Array or state["owned_companions"].is_empty():
		state["owned_companions"] = ["sparkle"]
	for companion_id in state["owned_companions"]:
		var item_id := "companion_%s" % companion_id
		state["inventory"][item_id] = maxi(1, int(state["inventory"].get(item_id, 0)))
	var normalized_rooms := {}
	for room_id in state["rooms"]:
		var normalized_items: Array = []
		var raw_items = state["rooms"][room_id]
		if raw_items is Array:
			for index in raw_items.size():
				var raw: Dictionary = raw_items[index]
				normalized_items.append({
					"instance_id": str(raw.get("instance_id", raw.get("instanceId", "%s_%d" % [room_id, index]))),
					"item_id": str(raw.get("item_id", raw.get("itemId", ""))),
					"x": float(raw.get("x", 50.0)),
					"y": float(raw.get("y", 50.0)),
					"rotation": int(raw.get("rotation", 0)),
					"scale": float(raw.get("scale", 1.0)),
					"z_index": int(raw.get("z_index", raw.get("zIndex", index + 1))),
				})
		normalized_rooms[str(room_id)] = normalized_items
	state["rooms"] = normalized_rooms


func _normalize_learning_state(state: Dictionary, source: Dictionary, source_version: int) -> void:
	if not state.get("settings") is Dictionary:
		state["settings"] = {}
	for setting in {"music": true, "sound": true, "reduced_motion": false, "tutorials_enabled": true}:
		if not state["settings"].has(setting):
			state["settings"][setting] = {"music": true, "sound": true, "reduced_motion": false, "tutorials_enabled": true}[setting]
	if not state.get("tutorials") is Dictionary:
		state["tutorials"] = {}
	# Existing players are never forced backward through lessons they have already
	# mastered. Only the first three previously reached levels are marked complete.
	if source_version < 4 and not source.has("tutorials"):
		for game_id in state.get("progress", {}):
			var max_level := int(state["progress"][game_id].get("max_level", 1))
			var completed_levels: Array[int] = []
			for tutorial_level in range(1, mini(4, max_level)):
				completed_levels.append(tutorial_level)
			state["tutorials"][str(game_id)] = completed_levels
