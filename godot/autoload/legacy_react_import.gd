extends Node

# Android-only bridge. The native singleton hosts an off-screen WebView at the
# same https://localhost origin used by Capacitor, and returns only the legacy
# localStorage value. Desktop deliberately does nothing and leaves retry state.
const LEGACY_KEY := "unicorn_arcade_v1"
const GAME_IDS := {"unicorn": "unicorn_jump", "sliding": "sliding_window", "coin": "coin_count", "cash": "cash_counter", "mathSwipe": "math_swipe", "mathtris": "mathtris", "spaceUnicorn": "galaxy_unicorn", "unicornBlast": "unicorn_blast", "rhymeRally": "rhyme_rally", "sentenceSprout": "sentence_sprout", "missingMagic": "missing_magic", "sightSpark": "sight_spark", "prefixPotion": "prefix_potion", "vowelVines": "vowel_vines", "letterLift": "letter_lift", "syllableStamp": "syllable_stamp", "captionQuest": "caption_quest", "oppositeOrbit": "opposite_orbit", "scrambleSpell": "scramble_spell", "oddOneOut": "odd_one_out", "sizeLineUp": "size_line_up", "chainLink": "chain_link"}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("try_import")


func try_import() -> void:
	if not OS.has_feature("android"):
		return
	var bridge = Engine.get_singleton("LegacyProfileBridge")
	if bridge == null:
		SaveService.mark_legacy_import("pending_bridge_unavailable")
		return
	SaveService.mark_legacy_import("pending")
	if bridge.has_signal("legacy_json") and not bridge.legacy_json.is_connected(_on_legacy_json):
		bridge.legacy_json.connect(_on_legacy_json)
	bridge.read_legacy_json()


func _on_legacy_json(raw: String) -> void:
	if raw.is_empty():
		SaveService.mark_legacy_import("not_found")
		return
	var parsed = JSON.parse_string(raw)
	if not parsed is Dictionary or not parsed.get("users") is Dictionary:
		SaveService.mark_legacy_import("pending_invalid", str(hash(raw)))
		return
	_import_users(parsed, str(hash(raw)))


func _import_users(payload: Dictionary, source_hash: String) -> void:
	if str(SaveService._envelope.get("legacy_import", {}).get("status", "")) == "success" and str(SaveService._envelope.get("legacy_import", {}).get("hash", "")) == source_hash:
		return
	var selected_name := ""
	for raw_name in payload["users"]:
		var user: Dictionary = payload["users"][raw_name]
		var name := _import_name(str(user.get("name", raw_name)), source_hash)
		var profile := _convert_user(user, name)
		profile["legacy_react_source_hash"] = source_hash
		var created := SaveService.create_profile(name)
		if created.is_empty():
			SaveService.mark_legacy_import("pending_write_failed", source_hash)
			return
		if not SaveService.save_state(profile):
			SaveService.mark_legacy_import("pending_write_failed", source_hash)
			return
		if str(raw_name) == str(payload.get("lastUser", "")):
			selected_name = name
	if not selected_name.is_empty():
		SaveService.select_profile(selected_name)
	# Success is recorded only after the just-written envelope can be read again.
	var reread := SaveService._read_json(SaveService.SAVE_PATH)
	if reread.get("users") is Dictionary:
		SaveService.mark_legacy_import("success", source_hash)
	else:
		SaveService.mark_legacy_import("pending_verify_failed", source_hash)


func _collision_safe_name(candidate: String) -> String:
	var base := candidate.strip_edges()
	if base.is_empty(): base = "React Player"
	var name := base
	var existing := SaveService.profile_names()
	if name in existing:
		name = "%s (React import)" % base
		var ordinal := 2
		while name in existing:
			name = "%s (React import %d)" % [base, ordinal]
			ordinal += 1
	return name


func _import_name(candidate: String, source_hash: String) -> String:
	for key in SaveService._envelope.get("users", {}):
		var record: Dictionary = SaveService._envelope["users"][key]
		var profile: Dictionary = record.get("profile", {})
		if str(record.get("display_name", "")) == candidate and str(profile.get("legacy_react_source_hash", "")) == source_hash:
			return candidate
	return _collision_safe_name(candidate)


func _convert_user(user: Dictionary, name: String) -> Dictionary:
	var profile := SaveService._normalize_profile(user)
	profile["player"]["name"] = name
	profile["player"]["coins"] = int(user.get("coins", profile["player"].get("coins", 1000)))
	profile["owned_companions"] = user.get("ownedUnicorns", profile.get("owned_companions", ["sparkle"]))
	profile["player"]["equipped_companion"] = str(user.get("equippedUnicorn", profile["player"].get("equipped_companion", "sparkle")))
	for source_id in user:
		if source_id in GAME_IDS and user[source_id] is Dictionary:
			var game_id: String = str(GAME_IDS[source_id])
			var old: Dictionary = user[source_id]
			var last_completed := int(old.get("maxLevel", old.get("lastCompletedLevel", 0)))
			var completed: Array = []
			for entry in old.get("times", []):
				if entry is Dictionary:
					completed.append({"level": int(entry.get("level", 1)), "time": int(entry.get("time", 0)), "date": str(entry.get("date", ""))})
			profile["progress"][game_id] = {"max_level": maxi(1, last_completed + 1), "completed": completed}
	return profile
