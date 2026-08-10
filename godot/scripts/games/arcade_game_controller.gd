class_name ArcadeGameController
extends Control

const TutorialCatalog = preload("res://scripts/tutorial_catalog.gd")
const LevelRunController = preload("res://scripts/games/level_run_controller.gd")

## Stable public boundary between a game scene and the shared arcade chrome.
## Existing games retain their fields and rules; this base converts them into a
## snapshot so chrome never probes arbitrary game implementation properties.
signal runtime_state_changed(snapshot: Dictionary)
signal run_activity_changed(active: bool)

var _last_runtime_snapshot: Dictionary = {}
var _last_active := false
var _runtime_elapsed := 0.0
var level_run := LevelRunController.new()


func prepare_category_return() -> String:
	var category := level_run.select_category()
	AppState.set_shell_destination("category", category)
	return category


func return_to_category() -> void:
	prepare_category_return()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _process(delta: float) -> void:
	_runtime_elapsed += delta
	if _runtime_elapsed < 0.12:
		return
	_runtime_elapsed = 0.0
	publish_runtime_state()


func runtime_snapshot() -> Dictionary:
	var id := str(get("game_id")) if _has_runtime_property("game_id") else _selected_game_id()
	var level := int(get("level")) if _has_runtime_property("level") else 1
	var active := bool(get("active")) if _has_runtime_property("active") else true
	var retry := can_retry_failure()
	var objective := build_objective_snapshot(id, level)
	return {
		"game_id": id,
		"level": level,
		"active": active,
		"objective_primary": str(objective.get("primary", "YOUR MISSION")),
		"objective_detail": str(objective.get("detail", "Complete the enchanted challenge.")),
		"hint_available": can_show_hint(),
		"retry_available": retry,
		"outcome_message": runtime_outcome_message(),
	}


func publish_runtime_state() -> void:
	var snapshot := runtime_snapshot()
	var active := bool(snapshot.get("active", true))
	if _last_runtime_snapshot != snapshot:
		_last_runtime_snapshot = snapshot
		runtime_state_changed.emit(snapshot)
	if _last_active != active:
		_last_active = active
		run_activity_changed.emit(active)


func request_hint() -> bool:
	if not can_show_hint():
		return false
	_show_hint()
	publish_runtime_state()
	return true


func request_retry() -> bool:
	if not can_retry_failure():
		return false
	retry_failure()
	publish_runtime_state()
	return true


func request_companion_action(_companion_id: String) -> bool:
	return false


func can_show_hint() -> bool:
	return false


func can_retry_failure() -> bool:
	return false


func retry_failure() -> void:
	pass


func _show_hint() -> void:
	pass


func runtime_outcome_message() -> String:
	if _has_runtime_property("message_label"):
		var label = get("message_label")
		if label is Label:
			return str((label as Label).text)
	return "Your next adventure is ready."


func build_objective_snapshot(id: String, level: int) -> Dictionary:
	match id:
		"comet_math_rescue":
			var problem: Dictionary = get("current_problem") if _has_runtime_property("current_problem") else {}
			var operation := str(problem.get("operation", "+"))
			var visible := "×" if operation == "x" else ("÷" if operation == "/" else operation)
			return {"primary": "%d %s %d = ?" % [int(problem.get("left", 0)), visible, int(problem.get("right", 0))], "detail": "SHIELDS %d - RESCUE %d/%d - SCORE %d" % [_runtime_int("lives", 3), _runtime_int("rescues", 0), _runtime_int("target_rescues", 0), _runtime_int("score", 0)]}
		"unicorn_jump":
			var data = get("level_data") if _has_runtime_property("level_data") else []
			var index := _runtime_int("current_index", 0)
			if data is Array and index < data.size():
				var value := int(data[index])
				return {"primary": "%s  %d" % ["JUMP FORWARD" if value >= 0 else "JUMP BACK", absi(value)], "detail": "COUNT EXACTLY %d STONES • TAP THE LANDING" % absi(value)}
			return {"primary": "TRAIL COMPLETE!", "detail": "You reached the rainbow finish."}
		"coin_count": return {"primary": "MAKE $%d.%02d" % [_runtime_int("target", 0) / 100, _runtime_int("target", 0) % 100], "detail": "BUILD THE EXACT TOTAL WITH REAL US COINS"}
		"cash_counter": return {"primary": "MAKE $%d" % _runtime_int("target", 0), "detail": "BUILD THE EXACT TOTAL WITH REAL US BILLS"}
		"mathtris": return {"primary": "MAKE A TRUE EQUATION", "detail": "FIVE TILES ACROSS OR DOWN • SWIPE NEIGHBORS"}
		"galaxy_unicorn": return {"primary": "RAINBOW DEFENSE", "detail": "LEVEL %d • LIVES %d • %d/%d ENEMIES • SCORE %d" % [level, _runtime_int("lives", 3), _runtime_int("kills", 0), _runtime_int("target_kills", 0), _runtime_int("score", 0)]}
	var registry := get_tree().root.get_node_or_null("GameRegistry") if get_tree() != null and get_tree().root != null else null
	var game: Dictionary = registry.get_game(id) if registry != null else {}
	var lessons: Array[String] = TutorialCatalog.lessons(id, level)
	return {"primary": str(game.get("title", "Mission")).to_upper(), "detail": lessons[0] if not lessons.is_empty() else "Complete the enchanted challenge."}


func _runtime_int(property: String, fallback: int) -> int:
	return int(get(property)) if _has_runtime_property(property) else fallback


func _has_runtime_property(property: String) -> bool:
	for definition in get_property_list():
		if str(definition.get("name", "")) == property:
			return true
	return false


func _selected_game_id() -> String:
	var tree := get_tree()
	var state := tree.root.get_node_or_null("AppState") if tree != null and tree.root != null else null
	return str(state.get("selected_game_id")) if state != null else ""
