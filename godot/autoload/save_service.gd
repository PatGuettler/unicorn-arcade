extends Node

const SAVE_VERSION := 2
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
		"inventory": {},
		"rooms": {},
		"settings": {
			"music": true,
			"sound": true,
			"reduced_motion": false,
		},
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
		result["inventory"] = source.get("inventory", {})
		result["rooms"] = source.get("rooms", {})
	else:
		for key in result.keys():
			if source.has(key):
				result[key] = source[key]
	result["version"] = SAVE_VERSION
	return result
