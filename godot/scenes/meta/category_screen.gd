extends Control


func _ready() -> void:
	UiFactory.add_background(self)
	var cat_id := SceneRouter.get_category_id()
	var title: String = cat_id
	for cat_variant in GameCatalog.categories:
		var cat: Dictionary = cat_variant
		if cat.get("id", "") == cat_id:
			title = String(cat.get("title", cat_id))
			break

	var coins: int = int(SaveManager.user_data.get("coins", 0))
	UiFactory.make_header_bar(self, {
		"subscreen": true,
		"title": title,
		"coins": coins,
		"on_back": func(): SceneRouter.pop(),
		"on_profile": func(): SceneRouter.go_home(false),
	})

	var body := UiFactory.make_screen_body(self, 88)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = DisplayProfile.grid_columns(2, 3)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for game_variant in GameCatalog.games.get(cat_id, []):
		var game: Dictionary = game_variant
		var label: String = "%s %s" % [game.get("icon", ""), game.get("title", game.get("id"))]
		var btn := UiFactory.make_button(label, UiFactory.CYAN, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var game_id: String = String(game.get("id", ""))
		btn.pressed.connect(func(): SceneRouter.go_game(cat_id, game_id))
		grid.add_child(btn)
