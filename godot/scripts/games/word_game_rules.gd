class_name WordGameRules
extends RefCounted

const DATA_PATH := "res://data/word_games.json"

static var _cache: Dictionary = {}


static func data() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open word-game data: %s" % DATA_PATH)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Word-game data is not a JSON object")
		return {}
	_cache = parsed
	return _cache


static func target_for_level(level: int) -> int:
	return mini(12, 3 + int(floor(1.2 * maxi(level, 1))))


static func caption_target(level: int) -> int:
	return mini(4, target_for_level(level))


static func odd_one_out_target(level: int) -> int:
	return mini(6, target_for_level(level))


static func cash_target_bounds(level: int) -> Vector2i:
	if level <= 3:
		return Vector2i(1, 20)
	if level <= 8:
		return Vector2i(20, 99)
	return Vector2i(100, 999)


static func selection_window(size: int, seed: int) -> Vector2i:
	if size <= 0:
		return Vector2i.ZERO
	var safe_seed := maxi(1, seed)
	var ceiling := mini(size, maxi(4, roundi(safe_seed * 1.5)))
	var floor_index := maxi(0, ceiling - maxi(5, roundi(ceiling * 0.6)))
	return Vector2i(floor_index, ceiling)


static func pick_for_level(key: String, seed: int, rng: RandomNumberGenerator) -> Dictionary:
	var entries: Array = data().get(key, [])
	if entries.is_empty():
		return {}
	var window := selection_window(entries.size(), seed)
	return entries[rng.randi_range(window.x, window.y - 1)].duplicate(true)


static func words_for_level(level: int) -> Array:
	var tier := "easy"
	if level > 14:
		tier = "expert"
	elif level > 8:
		tier = "hard"
	elif level > 3:
		tier = "medium"
	return data().get("falling_words", {}).get(tier, []).duplicate()


static func sight_flash_ms(level: int) -> int:
	return maxi(800, 2200 - maxi(level, 1) * 80)


static func blast_speed(level: int) -> float:
	# The early words now have enough readable, tappable fall time while the
	# level curve still gets meaningfully quicker.
	return 0.075 + maxi(level, 1) * 0.008


static func blast_spawn_ms(level: int) -> int:
	return maxi(1400, 2800 - maxi(level, 1) * 120)


static func is_chain_link(start: String, candidate: String) -> bool:
	if start.is_empty() or candidate.is_empty():
		return false
	return start.right(1).to_lower() == candidate.left(1).to_lower()
