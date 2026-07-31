extends Node

const MetaCatalog = preload("res://scripts/meta_catalog.gd")
const RoomRules = preload("res://scripts/room_rules.gd")

signal state_changed
signal coins_changed(coins: int)

var data: Dictionary = {}
var selected_game_id := ""
var selected_category := "Number"
var shell_view := "home"
var active_room_companion := "sparkle"


func _ready() -> void:
	data = SaveService.load_state()


func coins() -> int:
	return int(data.get("player", {}).get("coins", 1000))


func owned_companions() -> Array:
	return data.get("owned_companions", ["sparkle"])


func equipped_companion() -> String:
	return str(data.get("player", {}).get("equipped_companion", "sparkle"))


func player_name() -> String:
	return str(data.get("player", {}).get("name", ""))


func set_player_name(value: String) -> void:
	data["player"]["name"] = value.strip_edges()
	_save_and_emit()


func logout() -> void:
	data["player"]["name"] = ""
	shell_view = "home"
	_save_and_emit()


func current_level(game_id: String) -> int:
	var record: Dictionary = data.get("progress", {}).get(game_id, {})
	return maxi(1, int(record.get("max_level", 1)))


func progress_for_game(game_id: String) -> Dictionary:
	return data.get("progress", {}).get(game_id, {}).duplicate(true)


func completed_run_count() -> int:
	var count := 0
	for record in data.get("progress", {}).values():
		count += record.get("completed", []).size()
	return count


func select_game(game_id: String, category: String) -> void:
	selected_game_id = game_id
	selected_category = category
	shell_view = "category"


func set_shell_destination(view: String, category := "") -> void:
	shell_view = view
	if not category.is_empty():
		selected_category = category


func setting(key: String, fallback = false):
	return data.get("settings", {}).get(key, fallback)


func set_setting(key: String, value) -> void:
	data["settings"][key] = value
	_save_and_emit()


func spend_hint(level: int) -> bool:
	var cost := RewardService.hint_cost(level)
	if coins() < cost:
		return false
	data["player"]["coins"] = coins() - cost
	_save_and_emit()
	return true


func buy_companion(companion_id: String) -> bool:
	var definition := MetaCatalog.companion(companion_id)
	if definition.is_empty() or companion_id in owned_companions():
		return false
	var price := int(definition.get("price", 0))
	if coins() < price:
		return false
	data["player"]["coins"] = coins() - price
	data["owned_companions"].append(companion_id)
	data["inventory"]["companion_%s" % companion_id] = 1
	_save_and_emit()
	return true


func equip_companion(companion_id: String) -> bool:
	if companion_id not in owned_companions():
		return false
	data["player"]["equipped_companion"] = companion_id
	_save_and_emit()
	return true


func buy_furniture(item_id: String) -> bool:
	var definition := MetaCatalog.furniture_item(item_id)
	if definition.is_empty():
		return false
	var price := int(definition.get("price", 0))
	if coins() < price:
		return false
	data["player"]["coins"] = coins() - price
	data["inventory"][item_id] = int(data["inventory"].get(item_id, 0)) + 1
	_save_and_emit()
	return true


func sell_furniture(item_id: String) -> bool:
	if item_id.begins_with("companion_") or available_count(item_id) <= 0:
		return false
	var definition := MetaCatalog.furniture_item(item_id)
	if definition.is_empty():
		return false
	var remaining := int(data["inventory"].get(item_id, 0)) - 1
	if remaining <= 0:
		data["inventory"].erase(item_id)
	else:
		data["inventory"][item_id] = remaining
	data["player"]["coins"] = coins() + RoomRules.sell_refund(int(definition.get("price", 0)))
	_save_and_emit()
	return true


func placed_count(item_id: String) -> int:
	var count := 0
	for room_items in data.get("rooms", {}).values():
		for item in room_items:
			if str(item.get("item_id", "")) == item_id:
				count += 1
	return count


func available_count(item_id: String) -> int:
	return maxi(0, int(data.get("inventory", {}).get(item_id, 0)) - placed_count(item_id))


func room_items(companion_id: String) -> Array:
	return data.get("rooms", {}).get(companion_id, []).duplicate(true)


func place_room_item(companion_id: String, item: Dictionary) -> bool:
	var rooms: Dictionary = data.get("rooms", {})
	var items: Array = rooms.get(companion_id, [])
	var normalized := RoomRules.normalized(item, items.size())
	var existing := -1
	for index in items.size():
		if str(items[index].get("instance_id", "")) == str(normalized["instance_id"]):
			existing = index
			break
	if existing < 0 and available_count(str(normalized["item_id"])) <= 0:
		return false
	if existing >= 0:
		items[existing] = normalized
	else:
		items.append(normalized)
	rooms[companion_id] = items
	data["rooms"] = rooms
	_save_and_emit()
	return true


func remove_room_item(companion_id: String, instance_id: String) -> bool:
	var items := room_items(companion_id)
	var next := items.filter(func(item: Dictionary) -> bool: return str(item.get("instance_id", "")) != instance_id)
	if next.size() == items.size():
		return false
	data["rooms"][companion_id] = next
	_save_and_emit()
	return true


func reorder_room_item(companion_id: String, instance_id: String, direction: String) -> void:
	data["rooms"][companion_id] = RoomRules.reorder(room_items(companion_id), instance_id, direction)
	_save_and_emit()


func reset_room(companion_id: String) -> void:
	data["rooms"][companion_id] = []
	_save_and_emit()


func complete_level(game_id: String, level: int, elapsed_ms: int) -> int:
	var reward := RewardService.level_reward(level)
	data["player"]["coins"] = coins() + reward
	var progress: Dictionary = data.get("progress", {})
	var record: Dictionary = progress.get(game_id, {"max_level": 1, "completed": []})
	var completed: Array = record.get("completed", [])
	completed.append({"level": level, "time": elapsed_ms, "date": Time.get_datetime_string_from_system(true)})
	record["completed"] = completed
	record["max_level"] = maxi(int(record.get("max_level", 1)), level + 1)
	progress[game_id] = record
	data["progress"] = progress
	_save_and_emit()
	return reward


func _save_and_emit() -> void:
	SaveService.save_state(data)
	state_changed.emit()
	coins_changed.emit(coins())
