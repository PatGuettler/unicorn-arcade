extends Control


func _ready() -> void:
	UiFactory.make_panel(self)
	UiFactory.make_header(self, "Categories", func(): SceneRouter.pop(), int(SaveManager.user_data.coins))

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 72
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = DisplayProfile.grid_columns(1, 2)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	for cat in GameCatalog.categories:
		var btn := UiFactory.make_button("%s\n%s" % [cat.title, cat.desc], UiFactory.VIOLET)
		btn.custom_minimum_size = Vector2(160, 88)
		var cat_id: String = cat.id
		btn.pressed.connect(func(): SceneRouter.go_category(cat_id))
		grid.add_child(btn)
