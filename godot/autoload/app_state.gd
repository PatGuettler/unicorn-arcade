extends Node

signal state_changed
signal coins_changed(coins: int)

var data: Dictionary = {}


func _ready() -> void:
	data = SaveService.load_state()


func coins() -> int:
	return int(data.get("player", {}).get("coins", 1000))


func current_level(game_id: String) -> int:
	var record: Dictionary = data.get("progress", {}).get(game_id, {})
	return maxi(1, int(record.get("max_level", 1)))


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
