extends Control


func _ready() -> void:
	UiFactory.add_background(self)
	var game_id := SceneRouter.get_game_id()
	var entry := GameCatalog.get_game_entry(SceneRouter.get_category_id(), game_id)
	UiFactory.make_header_bar(self, {
		"subscreen": true,
		"title": String(entry.get("title", game_id)),
		"coins": int(SaveManager.user_data.get("coins", 0)),
		"on_back": func(): SceneRouter.pop(),
		"on_profile": func(): SceneRouter.go_home(false),
	})

	var body := UiFactory.make_screen_body(self, 88)
	var label := UiFactory.make_subtitle("This mini-game is still being ported to Godot.")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(label)
