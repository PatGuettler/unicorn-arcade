extends Node

# v5 stores an envelope so accounts do not overwrite each other.  Public callers
# still receive the selected profile's game-state dictionary for backwards compatibility.
const SAVE_VERSION := 5
const SAVE_PATH := "user://unicorn_arcade_v2.json"
const BACKUP_COUNT := 3

var _envelope: Dictionary = {}
var last_error := ""
var _active_key := ""
var _test_in_memory := false
var _test_force_write_failure := false


func begin_test_session() -> bool:
	if not OS.has_feature("editor"):
		return false
	_test_in_memory = true
	_test_force_write_failure = false
	_envelope = default_state()
	_active_key = ""
	return true


func end_test_session() -> void:
	_test_in_memory = false
	_test_force_write_failure = false
	_envelope = {}
	_active_key = ""


func default_profile(display_name := "") -> Dictionary:
	return {
		"player": {"name": display_name, "coins": 1000, "equipped_companion": "sparkle"},
		"owned_companions": ["sparkle"], "progress": {}, "inventory": {"companion_sparkle": 1},
		"rooms": {}, "settings": {"music": true, "sound": true, "reduced_motion": false, "tutorials_enabled": true},
		"tutorials": {},
	}


func default_state() -> Dictionary:
	return {"version": SAVE_VERSION, "last_user": "", "users": {}, "legacy_import": {"status": "not_checked", "hash": "", "time": ""}}


func load_state() -> Dictionary:
	_envelope = _read_best_envelope()
	var selected := str(_envelope.get("last_user", ""))
	if selected.is_empty() or not _envelope["users"].has(selected):
		_active_key = ""
		return default_profile()
	_active_key = selected
	return _profile_from_record(_envelope["users"][selected])


func profile_names() -> Array[String]:
	var names: Array[String] = []
	for key in _envelope.get("users", {}):
		names.append(str(_envelope["users"][key].get("display_name", key)))
	names.sort()
	return names


func select_profile(display_name: String) -> Dictionary:
	var key := _canonical(display_name)
	if key.is_empty() or not _envelope.get("users", {}).has(key):
		return {}
	var candidate := _envelope.duplicate(true)
	candidate["last_user"] = key
	if not _write_envelope(candidate):
		return {}
	_envelope = candidate
	_active_key = key
	return _profile_from_record(candidate["users"][key])


func create_profile(display_name: String) -> Dictionary:
	var shown := display_name.strip_edges()
	var key := _canonical(shown)
	if key.is_empty():
		return {}
	var candidate := _envelope.duplicate(true) if not _envelope.is_empty() else default_state()
	if not candidate.has("users"):
		candidate["users"] = {}
	if not candidate["users"].has(key):
		candidate["users"][key] = {"display_name": shown, "profile": default_profile(shown)}
	candidate["last_user"] = key
	if not _write_envelope(candidate):
		return {}
	_envelope = candidate
	_active_key = key
	return _profile_from_record(candidate["users"][key])


func save_state(profile: Dictionary) -> bool:
	if _envelope.is_empty():
		last_error = "No active profile; refusing to overwrite saved users"
		return false
	if not has_active_profile():
		last_error = "No active profile; refusing to overwrite saved users"
		return false
	var candidate := _envelope.duplicate(true)
	candidate["users"][_active_key] = {"display_name": str(profile.get("player", {}).get("name", _active_key)), "profile": _normalize_profile(profile)}
	if not _write_envelope(candidate):
		return false
	_envelope = candidate
	return true


func deactivate_profile() -> bool:
	# Persist the sign-out before AppState replaces its in-memory profile.  This is
	# deliberately not a profile write, so focus/pause can never blank a user.
	if _envelope.is_empty():
		_active_key = ""
		return true
	var candidate := _envelope.duplicate(true)
	candidate["last_user"] = ""
	if not _write_envelope(candidate):
		return false
	_envelope = candidate
	_active_key = ""
	return true


func has_active_profile() -> bool:
	return not _active_key.is_empty() and _active_key == str(_envelope.get("last_user", "")) and _envelope.get("users") is Dictionary and _envelope["users"].has(_active_key)


func set_test_write_failure(enabled: bool) -> void:
	if _test_in_memory and OS.has_feature("editor"):
		_test_force_write_failure = enabled


func import_profile(display_name: String, profile: Dictionary) -> bool:
	var shown := display_name.strip_edges()
	var key := _canonical(shown)
	if key.is_empty():
		last_error = "Imported profile needs a name"
		return false
	var candidate := _envelope.duplicate(true) if not _envelope.is_empty() else default_state()
	if not candidate.has("users"):
		candidate["users"] = {}
	candidate["users"][key] = {"display_name": shown, "profile": _normalize_profile(profile)}
	if not _write_envelope(candidate):
		return false
	_envelope = candidate
	return true


func mark_legacy_import(status: String, source_hash := "") -> bool:
	var candidate := _envelope.duplicate(true) if not _envelope.is_empty() else default_state()
	candidate["legacy_import"] = {"status": status, "hash": source_hash, "time": Time.get_datetime_string_from_system(true)}
	if not _write_envelope(candidate):
		return false
	_envelope = candidate
	return true


func _read_best_envelope() -> Dictionary:
	var candidates := [SAVE_PATH]
	for index in range(BACKUP_COUNT): candidates.append("%s.bak%d" % [SAVE_PATH, index + 1])
	for path in candidates:
		var parsed := _read_json(path)
		if not parsed.is_empty():
			if path != SAVE_PATH:
				_preserve_corrupt_primary()
				# The backup is known-good; copy it to a temp and promote atomically.
				_write_text("%s.tmp" % SAVE_PATH, JSON.stringify(parsed))
				_promote_temp()
			return _migrate(parsed)
	return default_state()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _migrate(source: Dictionary) -> Dictionary:
	if int(source.get("version", 0)) >= SAVE_VERSION and source.get("users") is Dictionary:
		var result := default_state()
		result.merge(source, true)
		for key in result["users"]: result["users"][key]["profile"] = _normalize_profile(result["users"][key].get("profile", {}))
		return result
	# All earlier formats were a single flat profile, including current v4.
	var profile := _normalize_profile(source)
	var name := str(profile.get("player", {}).get("name", "")).strip_edges()
	var key := _canonical(name)
	if key.is_empty(): key = "player"
	var migrated := default_state()
	migrated["last_user"] = key
	migrated["users"][key] = {"display_name": name, "profile": profile}
	migrated["legacy_import"] = {"status": "migrated_v%d" % int(source.get("version", 1)), "hash": "", "time": Time.get_datetime_string_from_system(true)}
	return migrated


func _profile_from_record(record: Dictionary) -> Dictionary:
	return _normalize_profile(record.get("profile", {}))


func _normalize_profile(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	var old_player: Dictionary = source.get("player", {}) if source.get("player") is Dictionary else {}
	if not result.has("player") or not result["player"] is Dictionary: result["player"] = {}
	result["player"]["name"] = str(result["player"].get("name", source.get("name", "")))
	result["player"]["coins"] = int(result["player"].get("coins", source.get("coins", 1000)))
	result["player"]["equipped_companion"] = str(result["player"].get("equipped_companion", source.get("equippedUnicorn", source.get("equippedCompanion", old_player.get("equippedCompanion", "sparkle")))))
	if not result.has("owned_companions") and source.has("ownedUnicorns"): result["owned_companions"] = source["ownedUnicorns"]
	if not result.has("owned_companions") and source.has("ownedCompanions"): result["owned_companions"] = source["ownedCompanions"]
	if not result.has("progress") and source.has("gameProgress"): result["progress"] = source["gameProgress"]
	if not result.has("inventory") and source.get("furniture") is Dictionary: result["inventory"] = source["furniture"].get("inventory", {})
	if not result.has("rooms") and source.get("furniture") is Dictionary: result["rooms"] = source["furniture"].get("placements", {})
	for key in default_profile().keys():
		if not result.has(key): result[key] = default_profile()[key]
	if not result.get("player") is Dictionary: result["player"] = default_profile()["player"]
	if not result.get("settings") is Dictionary: result["settings"] = {}
	for setting in {"music": true, "sound": true, "reduced_motion": false, "tutorials_enabled": true}:
		if not result["settings"].has(setting): result["settings"][setting] = {"music": true, "sound": true, "reduced_motion": false, "tutorials_enabled": true}[setting]
	if not result.get("tutorials") is Dictionary: result["tutorials"] = {}
	if not result.get("progress") is Dictionary: result["progress"] = {}
	if not result.get("inventory") is Dictionary: result["inventory"] = {}
	if not result.get("rooms") is Dictionary: result["rooms"] = {}
	var normalized_rooms := {}
	for room_id in result["rooms"]:
		var normalized: Array = []
		if result["rooms"][room_id] is Array:
			for index in result["rooms"][room_id].size():
				var raw: Dictionary = result["rooms"][room_id][index] if result["rooms"][room_id][index] is Dictionary else {}
				normalized.append({"instance_id": str(raw.get("instance_id", raw.get("instanceId", "%s_%d" % [room_id, index]))), "item_id": str(raw.get("item_id", raw.get("itemId", ""))), "x": float(raw.get("x", 50.0)), "y": float(raw.get("y", 50.0)), "rotation": int(raw.get("rotation", 0)), "scale": float(raw.get("scale", 1.0)), "z_index": int(raw.get("z_index", raw.get("zIndex", index + 1)))})
		normalized_rooms[str(room_id)] = normalized
	result["rooms"] = normalized_rooms
	if not result.get("owned_companions") is Array or result["owned_companions"].is_empty(): result["owned_companions"] = ["sparkle"]
	for companion_id in result["owned_companions"]: result["inventory"]["companion_%s" % companion_id] = maxi(1, int(result["inventory"].get("companion_%s" % companion_id, 0)))
	return result


func _write_envelope(envelope: Dictionary) -> bool:
	last_error = ""
	envelope["version"] = SAVE_VERSION
	if _test_in_memory:
		if _test_force_write_failure:
			last_error = "Simulated test write failure"
			return false
		return true
	var text := JSON.stringify(envelope, "  ")
	var temp := "%s.tmp" % SAVE_PATH
	if not _write_text(temp, text): return false
	if _read_json(temp).is_empty():
		last_error = "Temporary save validation failed"
		return false
	_rotate_backups()
	if not _promote_temp():
		last_error = "Could not promote temporary save"
		return false
	return true


func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not open save file"
		return false
	file.store_string(text)
	file.flush()
	file.close()
	return true


func _rotate_backups() -> void:
	var dir := DirAccess.open("user://")
	if dir == null: return
	for index in range(BACKUP_COUNT, 1, -1):
		var older := "unicorn_arcade_v2.json.bak%d" % (index - 1)
		var newer := "unicorn_arcade_v2.json.bak%d" % index
		if FileAccess.file_exists("user://%s" % older):
			if FileAccess.file_exists("user://%s" % newer): dir.remove(newer)
			dir.rename(older, newer)
	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists("user://unicorn_arcade_v2.json.bak1"): dir.remove("unicorn_arcade_v2.json.bak1")
		dir.rename("unicorn_arcade_v2.json", "unicorn_arcade_v2.json.bak1")


func _promote_temp() -> bool:
	var dir := DirAccess.open("user://")
	if dir == null: return false
	if FileAccess.file_exists(SAVE_PATH): dir.remove("unicorn_arcade_v2.json")
	return dir.rename("unicorn_arcade_v2.json.tmp", "unicorn_arcade_v2.json") == OK


func _preserve_corrupt_primary() -> void:
	if not FileAccess.file_exists(SAVE_PATH) or not _read_json(SAVE_PATH).is_empty(): return
	var dir := DirAccess.open("user://")
	if dir == null: return
	var stamp := str(Time.get_unix_time_from_system())
	dir.rename("unicorn_arcade_v2.json", "unicorn_arcade_v2.corrupt.%s.json" % stamp)


func _canonical(value: String) -> String:
	return value.strip_edges().to_lower().replace(" ", "_")
