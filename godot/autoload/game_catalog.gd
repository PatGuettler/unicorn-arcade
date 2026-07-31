extends Node

signal catalog_loaded

var categories: Array = []
var games: Dictionary = {}
var unicorns: Array = []
var furniture: Array = []
var furniture_categories: Array = []
var word_game_ids: Array = []
var all_game_ids: Array = []
var economy: Dictionary = {}

var _loaded := false


func _ready() -> void:
	_load_catalog()


func is_loaded() -> bool:
	return _loaded


func _load_catalog() -> void:
	var file := FileAccess.open("res://data/catalog.json", FileAccess.READ)
	if file == null:
		push_error("GameCatalog: missing res://data/catalog.json — run npm run export:godot-data")
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("GameCatalog: invalid catalog.json")
		return
	categories = data.get("categories", [])
	games = data.get("games", {})
	unicorns = data.get("unicorns", [])
	furniture = data.get("furniture", [])
	furniture_categories = data.get("furniture_categories", [])
	word_game_ids = data.get("word_game_ids", [])
	all_game_ids = data.get("all_game_ids", [])
	economy = data.get("economy", {})
	_loaded = true
	catalog_loaded.emit()


func get_game_entry(category_id: String, game_id: String) -> Dictionary:
	for entry in games.get(category_id, []):
		if entry.get("id") == game_id:
			return entry
	return {}


func get_unicorn(unicorn_id: String) -> Dictionary:
	for u in unicorns:
		if u.get("id") == unicorn_id:
			return u
	return {}


func get_furniture_def(item_id: String) -> Dictionary:
	for f in furniture:
		if f.get("id") == item_id:
			return f
	return {}


func game_scene_path(game_id: String) -> String:
	match game_id:
		"coin":
			return "res://scenes/games/coin_count/coin_count.tscn"
		_:
			return "res://scenes/games/stub/stub_game.tscn"
