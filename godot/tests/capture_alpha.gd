extends Node

const MAIN_SCENE = preload("res://scenes/main.tscn")
const WORD_SCENE = preload("res://scenes/games/word_game.tscn")
const CASH_SCENE = preload("res://scenes/games/cash_counter.tscn")


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var mode := "home"
	var game_id := ""
	var output := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--game-id="):
			game_id = argument.trim_prefix("--game-id=")
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	if output.is_empty():
		push_error("capture_alpha requires --output=<absolute png path>")
		get_tree().quit(2)
		return
	AppState.data["player"]["name"] = "Playtester"
	var captured: Node
	if mode == "game":
		AppState.selected_game_id = game_id
		var record := GameRegistry.get_game(game_id)
		var scene_path := str(record.get("scene", ""))
		if scene_path.is_empty():
			push_error("Unknown or unavailable game for capture: %s" % game_id)
			get_tree().quit(2)
			return
		captured = load(scene_path).instantiate()
	else:
		AppState.shell_view = mode
		if mode == "category":
			AppState.selected_category = "Word"
		captured = MAIN_SCENE.instantiate()
	add_child(captured)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var error := get_viewport().get_texture().get_image().save_png(output)
	if error == OK:
		print("ALPHA_CAPTURE_OK: %s" % output)
		get_tree().quit(0)
	else:
		push_error("Unable to save capture %s: %s" % [output, error_string(error)])
		get_tree().quit(1)
