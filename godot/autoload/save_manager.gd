extends Node

## Persists unicorn_arcade_v1-compatible save data under user://save.json

const SAVE_PATH := "user://save.json"

var db: Dictionary = { "users": {}, "lastUser": "" }
var current_user: String = ""
var user_data: Dictionary = {}


func _ready() -> void:
	_load()
	GameCatalog.catalog_loaded.connect(_on_catalog_ready, CONNECT_ONE_SHOT)
	if GameCatalog.is_loaded():
		_on_catalog_ready()


func _on_catalog_ready() -> void:
	if current_user != "":
		user_data = ensure_data_structure(db.users.get(current_user, {}))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		db = parsed


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(db))


func has_last_user() -> bool:
	return db.lastUser != "" and db.users.has(db.lastUser)


func login(username: String) -> void:
	var name := username.strip_edges()
	if name.is_empty():
		return
	current_user = name
	db.lastUser = name
	if not db.users.has(name):
		db.users[name] = _new_user()
	user_data = ensure_data_structure(db.users[name])
	save()


func logout() -> void:
	current_user = ""
	user_data = {}


func ensure_data_structure(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return _new_user()
	if not data.has("coins"):
		data.coins = 0
	if not data.has("ownedUnicorns"):
		data.ownedUnicorns = ["sparkle"]
	if not data.has("equippedUnicorn"):
		data.equippedUnicorn = "sparkle"
	if not data.has("furniture"):
		data.furniture = { "inventory": {}, "placements": {} }
	var placements: Dictionary = data.furniture.placements
	for room_id in placements.keys():
		var items: Array = placements[room_id]
		for i in items.size():
			items[i] = normalize_placed_item(items[i], i)
		placements[room_id] = items
	for game_id in GameCatalog.all_game_ids:
		if not data.has(game_id):
			data[game_id] = { "maxLevel": 0, "times": [] }
	return data


func _new_user() -> Dictionary:
	var user := {
		"coins": 0,
		"ownedUnicorns": ["sparkle"],
		"equippedUnicorn": "sparkle",
		"furniture": { "inventory": {}, "placements": {} },
	}
	for game_id in GameCatalog.all_game_ids:
		user[game_id] = { "maxLevel": 0, "times": [] }
	return user


func persist_user() -> void:
	if current_user.is_empty():
		return
	db.users[current_user] = user_data
	save()


func calc_coins(level: int) -> int:
	var econ := GameCatalog.economy
	return int(econ.coin_formula_base) + level * int(econ.coin_formula_per_level)


func save_game_progress(game_id: String, level: int, time_sec: float) -> void:
	var block: Dictionary = user_data.get(game_id, { "maxLevel": 0, "times": [] })
	if level > int(block.get("maxLevel", 0)):
		block.maxLevel = level
	var times: Array = block.get("times", [])
	times.append({ "level": level, "time": time_sec })
	block.times = times
	user_data[game_id] = block
	user_data.coins = int(user_data.coins) + calc_coins(level)
	persist_user()


func spend_coins(amount: int) -> bool:
	if int(user_data.coins) < amount:
		return false
	user_data.coins = int(user_data.coins) - amount
	persist_user()
	return true


func buy_unicorn(unicorn_id: String, price: int) -> bool:
	if unicorn_id in user_data.ownedUnicorns:
		return false
	if not spend_coins(price):
		return false
	user_data.ownedUnicorns.append(unicorn_id)
	persist_user()
	return true


func buy_furniture(item_id: String, price: int) -> bool:
	if not spend_coins(price):
		return false
	var inv: Dictionary = user_data.furniture.inventory
	inv[item_id] = int(inv.get(item_id, 0)) + 1
	user_data.furniture.inventory = inv
	persist_user()
	return true


func normalize_placed_item(item: Dictionary, index: int) -> Dictionary:
	var normalized := item.duplicate(true)
	if not normalized.has("uid"):
		normalized.uid = "%s_%d" % [normalized.get("itemId", "item"), index]
	if not normalized.has("x"):
		normalized.x = 50.0
	if not normalized.has("y"):
		normalized.y = 50.0
	if not normalized.has("rotation"):
		normalized.rotation = 0.0
	if not normalized.has("scale"):
		normalized.scale = 1.0
	if not normalized.has("zIndex"):
		normalized.zIndex = index
	return normalized


func get_game_last_level(game_id: String) -> int:
	var block: Dictionary = user_data.get(game_id, {})
	return int(block.get("maxLevel", 0))
