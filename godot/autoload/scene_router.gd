extends Node

## Scene stack + Android back handling for meta flow and games.

enum Screen {
	LOGIN,
	HOME,
	DASHBOARD,
	CATEGORY,
	SHOP,
	PROFILE,
	ALLEY,
	ROOM,
	GAME,
}

var _content: Control
var _stack: Array[Dictionary] = []
var _category_id: String = ""
var _game_id: String = ""
var _room_unicorn_id: String = ""


func get_category_id() -> String:
	return _category_id


func get_game_id() -> String:
	return _game_id


func get_room_unicorn_id() -> String:
	return _room_unicorn_id


func set_content_root(node: Control) -> void:
	_content = node


func start_app() -> void:
	_stack.clear()
	if SaveManager.has_last_user():
		SaveManager.current_user = SaveManager.db.lastUser
		SaveManager.user_data = SaveManager.ensure_data_structure(
			SaveManager.db.users[SaveManager.current_user]
		)
		go_home(false)
	else:
		_replace_screen(Screen.LOGIN, {})


func go_login() -> void:
	_stack.clear()
	_replace_screen(Screen.LOGIN, {})


func go_home(push: bool = true) -> void:
	_nav(Screen.HOME, {}, push)


func go_dashboard(push: bool = true) -> void:
	_nav(Screen.DASHBOARD, {}, push)


func go_category(category_id: String, push: bool = true) -> void:
	_category_id = category_id
	_nav(Screen.CATEGORY, { "category_id": category_id }, push)


func go_shop(push: bool = true) -> void:
	_nav(Screen.SHOP, {}, push)


func go_profile(push: bool = true) -> void:
	_nav(Screen.PROFILE, {}, push)


func go_alley(push: bool = true) -> void:
	_nav(Screen.ALLEY, {}, push)


func go_room(unicorn_id: String, push: bool = true) -> void:
	_room_unicorn_id = unicorn_id
	_nav(Screen.ROOM, { "unicorn_id": unicorn_id }, push)


func go_game(category_id: String, game_id: String, push: bool = true) -> void:
	_category_id = category_id
	_game_id = game_id
	_nav(Screen.GAME, { "category_id": category_id, "game_id": game_id }, push)


func pop() -> void:
	if _stack.is_empty():
		get_tree().quit()
		return
	var prev: Dictionary = _stack.pop_back()
	_apply_screen(prev.screen, prev.params, false)


func _nav(screen: Screen, params: Dictionary, push: bool) -> void:
	if push and _content.get_child_count() > 0:
		_stack.append({ "screen": _current_screen(), "params": _current_params() })
	_apply_screen(screen, params, true)


var _current: Screen = Screen.LOGIN


func _current_screen() -> Screen:
	return _current


func _current_params() -> Dictionary:
	match _current:
		Screen.CATEGORY:
			return { "category_id": _category_id }
		Screen.GAME:
			return { "category_id": _category_id, "game_id": _game_id }
		Screen.ROOM:
			return { "unicorn_id": _room_unicorn_id }
		_:
			return {}


func _apply_screen(screen: Screen, params: Dictionary, _track: bool) -> void:
	_current = screen
	match screen:
		Screen.LOGIN:
			_swap_packed(load("res://scenes/meta/login_screen.tscn"))
		Screen.HOME:
			_swap_packed(load("res://scenes/meta/home_screen.tscn"))
		Screen.DASHBOARD:
			_swap_packed(load("res://scenes/meta/dashboard_screen.tscn"))
		Screen.CATEGORY:
			_category_id = params.get("category_id", _category_id)
			_swap_packed(load("res://scenes/meta/category_screen.tscn"))
		Screen.SHOP:
			_swap_packed(load("res://scenes/meta/shop_screen.tscn"))
		Screen.PROFILE:
			_swap_packed(load("res://scenes/meta/profile_screen.tscn"))
		Screen.ALLEY:
			_swap_packed(load("res://scenes/meta/alley_3d.tscn"))
		Screen.ROOM:
			_room_unicorn_id = params.get("unicorn_id", _room_unicorn_id)
			_swap_packed(load("res://scenes/meta/room_editor_3d.tscn"))
		Screen.GAME:
			_category_id = params.get("category_id", _category_id)
			_game_id = params.get("game_id", _game_id)
			var path := GameCatalog.game_scene_path(_game_id)
			_swap_packed(load(path))


func _swap_packed(packed: PackedScene) -> void:
	for child in _content.get_children():
		child.queue_free()
	var inst := packed.instantiate()
	_content.add_child(inst)


func _replace_screen(screen: Screen, params: Dictionary) -> void:
	_stack.clear()
	_apply_screen(screen, params, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pop()
		get_viewport().set_input_as_handled()
