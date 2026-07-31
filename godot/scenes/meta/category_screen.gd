extends Control


func _ready() -> void:
	UiFactory.make_panel(self)
	var cat_id := SceneRouter.get_category_id()
	var title := cat_id
	for cat in GameCatalog.categories:
		if cat.id == cat_id:
			title = cat.title
			break

	UiFactory.make_header(self, title, func(): SceneRouter.pop(), int(SaveManager.user_data.coins))

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 72
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = DisplayProfile.grid_columns(2, 3)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for game in GameCatalog.games.get(cat_id, []):
		var label := "%s %s" % [game.get("icon", ""), game.get("title", game.get("id"))]
		if not game.get("parity_ok", false):
			label += "\n(coming soon)"
		var btn := UiFactory.make_button(label, UiFactory.CYAN if game.get("parity_ok") else UiFactory.VIOLET)
		btn.custom_minimum_size = Vector2(140, 72)
		var game_id: String = game.id
		btn.pressed.connect(func(): SceneRouter.go_game(cat_id, game_id))
		grid.add_child(btn)
