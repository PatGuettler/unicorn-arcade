extends Node

# One owner for Android/keyboard Back.  Scenes can keep their normal forward links;
# Back is intentionally derived from the current route so it never quits mid-game.
var _handling := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if _handling or not event.is_action_pressed("ui_cancel"):
		return
	_handling = true
	get_viewport().set_input_as_handled()
	go_back.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not _handling:
		_handling = true
		go_back.call_deferred()


func go_back() -> void:
	_handling = false
	var scene := get_tree().current_scene
	if scene == null: return
	if _dismiss_top_overlay(scene): return
	var policy := back_policy(str(scene.scene_file_path), AppState.shell_view)
	match str(policy["kind"]):
		"game":
			AppState.set_shell_destination("category", AppState.selected_category)
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		"room":
			get_tree().change_scene_to_file("res://scenes/meta/unicorn_alley.tscn")
		"meta":
			AppState.shell_view = "home"
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		"shell":
			match str(policy["target"]):
				"category": AppState.shell_view = "dashboard"; scene._show_view("dashboard")
				"dashboard", "profile": AppState.shell_view = "home"; scene._show_view("home")
				_: get_tree().quit()
		_:
			get_tree().quit()


static func back_policy(path: String, shell: String) -> Dictionary:
	if path.begins_with("res://scenes/games/"): return {"kind": "game", "target": "category"}
	if path.ends_with("room_editor.tscn"): return {"kind": "room", "target": "alley"}
	if path.ends_with("unicorn_alley.tscn") or path.ends_with("marketplace.tscn"): return {"kind": "meta", "target": "home"}
	if path.ends_with("main.tscn"): return {"kind": "shell", "target": shell}
	return {"kind": "quit", "target": ""}


static func platform_back_notifications_enabled() -> bool:
	return not bool(ProjectSettings.get_setting("application/config/auto_accept_quit", true)) and not bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true))


func _dismiss_top_overlay(root: Node) -> bool:
	# These are explicit owned modal surfaces, not a name-based sweep that can hide
	# arbitrary game UI. Room editor exposes its own close method.
	for node_name in ["GuidedTutorialOverlay", "CompanionAbilityNotice", "InGameProfileOverlay"]:
		var overlay := root.get_node_or_null(node_name)
		if overlay != null and overlay.visible:
			overlay.queue_free()
			return true
	if root.has_method("close_top_overlay") and bool(root.call("close_top_overlay")):
		return true
	return false
