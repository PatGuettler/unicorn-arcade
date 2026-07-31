extends Node

signal state_changed
signal coins_changed(coins: int)

var data: Dictionary = {}
var selected_game_id := ""
var selected_category := "Number"
var shell_view := "home"


func _ready() -> void:
	data = SaveService.load_state()


func coins() -> int:
	return int(data.get("player", {}).get("coins", 1000))


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
