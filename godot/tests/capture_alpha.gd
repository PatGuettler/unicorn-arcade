extends Node

const MAIN_SCENE = preload("res://scenes/main.tscn")
const WORD_SCENE = preload("res://scenes/games/word_game.tscn")
const CASH_SCENE = preload("res://scenes/games/cash_counter.tscn")


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var mode := "home"
	var game_id := ""
	var companion_id := "sparkle"
	var output := ""
	var camera_position := Vector3.ZERO
	var camera_target := Vector3.ZERO
	var camera_override := false
	var ortho_size := 0.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--game-id="):
			game_id = argument.trim_prefix("--game-id=")
		elif argument.begins_with("--companion-id="):
			companion_id = argument.trim_prefix("--companion-id=")
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		elif argument.begins_with("--camera="):
			camera_position = _parse_vector3(argument.trim_prefix("--camera="))
			camera_override = true
		elif argument.begins_with("--target="):
			camera_target = _parse_vector3(argument.trim_prefix("--target="))
		elif argument.begins_with("--ortho="):
			ortho_size = float(argument.trim_prefix("--ortho="))
	if output.is_empty():
		push_error("capture_alpha requires --output=<absolute png path>")
		get_tree().quit(2)
		return
	AppState.data["player"]["name"] = "" if mode == "login" else "Playtester"
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
	elif mode in ["marketplace", "marketplace_decor", "alley", "room", "room_selected", "room_bag"]:
		var meta_paths := {
			"marketplace": "res://scenes/meta/marketplace.tscn",
			"marketplace_decor": "res://scenes/meta/marketplace.tscn",
			"alley": "res://scenes/meta/unicorn_alley.tscn",
			"room": "res://scenes/meta/room_editor.tscn",
			"room_selected": "res://scenes/meta/room_editor.tscn",
			"room_bag": "res://scenes/meta/room_editor.tscn",
		}
		AppState.active_room_companion = companion_id
		if mode in ["room", "room_selected", "room_bag"]:
			AppState.data["inventory"]["lamp"] = 2
			AppState.data["inventory"]["rug"] = 2
			AppState.data["inventory"]["plant"] = 2
			AppState.data["rooms"][companion_id] = [
				{"instance_id": "preview_lamp", "item_id": "lamp", "x": 24.0, "y": 32.0, "rotation": 0, "scale": 1.0, "z_index": 1},
				{"instance_id": "preview_rug", "item_id": "rug", "x": 50.0, "y": 76.0, "rotation": 0, "scale": 1.4, "z_index": 2},
				{"instance_id": "preview_plant", "item_id": "plant", "x": 76.0, "y": 58.0, "rotation": -45, "scale": 1.1, "z_index": 3},
			]
		captured = load(meta_paths[mode]).instantiate()
	else:
		AppState.shell_view = mode
		if mode == "category":
			AppState.selected_category = "Word"
		captured = MAIN_SCENE.instantiate()
	add_child(captured)
	if camera_override:
		var camera := _find_camera(captured)
		if camera != null:
			camera.look_at_from_position(camera_position, camera_target, Vector3.UP)
			if ortho_size > 0.0:
				camera.size = ortho_size
	if mode == "marketplace_decor":
		captured.call("_show_decor")
	elif mode == "room_selected":
		captured.selected_id = "preview_rug"
		captured.call("_mark_selected")
	elif mode == "room_bag":
		captured.call("_show_bag")
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


func _parse_vector3(raw: String) -> Vector3:
	var parts := raw.split(",")
	if parts.size() != 3:
		return Vector3.ZERO
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var found := _find_camera(child)
		if found != null:
			return found
	return null
