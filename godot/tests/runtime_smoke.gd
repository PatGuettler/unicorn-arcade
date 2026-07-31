extends Node

var _failed := false


func _ready() -> void:
	SaveManager.current_user = "runtime-smoke"
	SaveManager.user_data = SaveManager.ensure_data_structure({})

	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(content)
	SceneRouter.set_content_root(content)

	for category_variant in GameCatalog.games.keys():
		var category_id := String(category_variant)
		var games: Array = GameCatalog.games.get(category_id, [])
		for game_variant in games:
			var game: Dictionary = game_variant
			var game_id := String(game.get("id", ""))
			SceneRouter.go_game(category_id, game_id, false)
			await get_tree().process_frame
			if content.get_child_count() != 1:
				push_error("Smoke: %s did not create a game screen" % game_id)
				_failed = true
				continue
			var instance := content.get_child(0)
			if instance.get_script() == null or not instance.has_method("game_arena"):
				push_error("Smoke: %s failed to load playable_game.gd" % game_id)
				_failed = true

	var meta_routes: Array[Callable] = [
		func(): SceneRouter.go_home(false),
		func(): SceneRouter.go_dashboard(false),
		func(): SceneRouter.go_shop(false),
		func(): SceneRouter.go_profile(false),
		func(): SceneRouter.go_alley(false),
		func(): SceneRouter.go_room("sparkle", false),
	]
	for route in meta_routes:
		route.call()
		await get_tree().process_frame
		if content.get_child_count() != 1 or content.get_child(0).get_script() == null:
			push_error("Smoke: meta route failed to create a scripted screen")
			_failed = true

	for furniture_variant in GameCatalog.furniture:
		var furniture: Dictionary = furniture_variant
		var item_id := String(furniture.get("id", ""))
		var model := World3DHelpers.furniture_mesh_for(item_id)
		if model.get_child_count() == 0:
			push_error("Smoke: furniture %s has no 3D geometry" % item_id)
			_failed = true
		model.free()

	if _failed:
		get_tree().quit(1)
	else:
		print("Runtime smoke passed for %d games" % GameCatalog.all_game_ids.size())
		get_tree().quit(0)
