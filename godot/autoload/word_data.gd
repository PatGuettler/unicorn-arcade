extends Node

var _lists: Dictionary = {}
var _mysteries: Dictionary = {}


func _ready() -> void:
	_load_json("res://data/word_lists.json", _lists)
	_load_json("res://data/word_mysteries.json", _mysteries)


func _load_json(path: String, into: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("WordData: missing %s" % path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in parsed.keys():
			into[key] = parsed[key]


func list(name: String) -> Array:
	var entry = get_entry(name)
	if typeof(entry) == TYPE_ARRAY:
		return entry
	return []


func get_entry(name: String) -> Variant:
	if _mysteries.has(name):
		return _mysteries[name]
	if _lists.has(name):
		return _lists[name]
	return null


func vowel_word_list(vowel: String) -> Array:
	var bucket = get_entry("VOWEL_WORDS")
	if typeof(bucket) == TYPE_DICTIONARY:
		return bucket.get(vowel, [])
	return []


func pick_for_level(arr: Array, seed: int) -> Variant:
	var len_arr := arr.size()
	if len_arr == 0:
		return null
	var s := maxi(1, seed)
	var ceil := mini(len_arr, maxi(4, int(round(s * 1.5))))
	var floor_i := maxi(0, ceil - maxi(5, int(round(ceil * 0.6))))
	var span := maxi(1, ceil - floor_i)
	var idx := mini(len_arr - 1, floor_i + randi() % span)
	return arr[idx]


func shuffle_array(arr: Array) -> Array:
	var copy: Array = arr.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy


func target_for_level(level: int) -> int:
	return mini(12, 3 + int(floor(level * 1.2)))


func words_for_level(level: int) -> Array:
	var key := "expert"
	if level <= 3:
		key = "easy"
	elif level <= 8:
		key = "medium"
	elif level <= 14:
		key = "hard"
	var bucket = _lists.get("FALLING_WORDS", {})
	if typeof(bucket) == TYPE_DICTIONARY and bucket.has(key):
		return bucket[key]
	return []
