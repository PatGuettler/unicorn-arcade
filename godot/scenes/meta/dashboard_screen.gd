extends Control


func _ready() -> void:
	UiFactory.add_background(self)
	var coins: int = int(SaveManager.user_data.get("coins", 0))
	UiFactory.make_header_bar(self, {
		"subscreen": true,
		"title": "Play",
		"coins": coins,
		"on_back": func(): SceneRouter.pop(),
		"on_profile": func(): SceneRouter.go_home(false),
	})

	var body := UiFactory.make_screen_body(self, 88)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	body.add_child(layout)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = DisplayProfile.grid_columns(1, 2)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	for cat_variant in GameCatalog.categories:
		var cat: Dictionary = cat_variant
		var title: String = String(cat.get("title", ""))
		var desc: String = String(cat.get("desc", ""))
		var btn := UiFactory.make_button("%s\n%s" % [title, desc], UiFactory.VIOLET, 88)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cat_id: String = String(cat.get("id", ""))
		btn.pressed.connect(func(): SceneRouter.go_category(cat_id))
		grid.add_child(btn)

	var alley := UiFactory.make_button("🦄 Unicorn Alley (3D)", UiFactory.PINK, 52)
	alley.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alley.pressed.connect(func(): SceneRouter.go_alley())
	layout.add_child(alley)
