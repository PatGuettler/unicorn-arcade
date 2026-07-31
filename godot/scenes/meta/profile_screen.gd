extends Control


func _ready() -> void:
	UiFactory.make_panel(self)
	UiFactory.make_header(self, "Profile", func(): SceneRouter.pop(), int(SaveManager.user_data.coins))

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 72
	add_child(scroll)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)

	var name_l := Label.new()
	name_l.text = "Player: %s" % SaveManager.current_user
	name_l.add_theme_font_size_override("font_size", 22)
	body.add_child(name_l)

	for cat in GameCatalog.categories:
		var games: Array = GameCatalog.games.get(cat.id, [])
		if games.is_empty():
			continue
		var header := Label.new()
		header.text = cat.title
		header.add_theme_color_override("font_color", UiFactory.CYAN)
		body.add_child(header)
		for g in games:
			var block: Dictionary = SaveManager.user_data.get(g.id, {})
			var line := Label.new()
			line.text = "  %s — max level %d" % [g.title, int(block.get("maxLevel", 0))]
			body.add_child(line)
