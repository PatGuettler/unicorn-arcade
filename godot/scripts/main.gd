extends Control

const NAVY := Color("08112f")
const PANEL := Color("14214a")
const PANEL_HOVER := Color("24366b")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const TEXT := Color("f7f1ff")
const MUTED := Color("aab7e8")
const MEADOW_BACKGROUND = preload("res://assets/meta/environments/magical_meadow_v1.png")
const RoomItemPreviewScene = preload("res://scripts/meta/room_item_preview_3d.gd")

var page: VBoxContainer
var status_label: Label
var coin_label: Label


func _ready() -> void:
	if AppState.player_name().is_empty():
		_show_login()
	else:
		_show_view(AppState.shell_view)


func _show_view(view: String) -> void:
	if AppState.player_name().is_empty():
		_show_login()
		return
	AppState.shell_view = view
	match view:
		"dashboard": _show_dashboard()
		"category": _show_category(AppState.selected_category)
		"profile": _show_profile()
		_: _show_home()


func _reset_page(use_meadow: bool = false) -> VBoxContainer:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if use_meadow:
		var meadow := TextureRect.new()
		meadow.texture = MEADOW_BACKGROUND
		meadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		meadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		meadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		meadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(meadow)
		var meadow_tint := ColorRect.new()
		meadow_tint.color = Color(0.12, 0.08, 0.22, 0.24)
		meadow_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		meadow_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(meadow_tint)
	else:
		var background := ColorRect.new()
		background.color = NAVY
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(background)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	return page


func _show_login() -> void:
	_reset_page(true)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(spacer)
	var brand := Label.new()
	brand.text = "UNICORN\nARCADE"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_font_size_override("font_size", 52)
	brand.add_theme_color_override("font_color", PINK)
	page.add_child(brand)
	var tagline := Label.new()
	tagline.text = "Train your brain with code-based games."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", MUTED)
	tagline.add_theme_font_size_override("font_size", 17)
	page.add_child(tagline)
	page.add_child(_build_sparkle_preview())
	var name_input := LineEdit.new()
	name_input.placeholder_text = "Enter player name…"
	name_input.custom_minimum_size = Vector2(0, 64)
	name_input.add_theme_font_size_override("font_size", 21)
	page.add_child(name_input)
	var enter := _make_button("ENTER ARCADE", CYAN, 68)
	enter.disabled = true
	name_input.text_changed.connect(func(value: String) -> void: enter.disabled = value.strip_edges().is_empty())
	var submit := func() -> void:
		if name_input.text.strip_edges().is_empty():
			return
		AppState.set_player_name(name_input.text)
		AppState.shell_view = "home"
		_show_home()
	enter.pressed.connect(submit)
	name_input.text_submitted.connect(func(_value: String) -> void: submit.call())
	page.add_child(enter)
	var bottom := Control.new()
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(bottom)
	name_input.grab_focus()


func _show_home() -> void:
	_reset_page(true)
	_add_header("", false, false)
	var welcome := Label.new()
	welcome.text = "WELCOME, %s" % AppState.player_name().to_upper()
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.add_theme_font_size_override("font_size", 18)
	welcome.add_theme_color_override("font_color", MUTED)
	page.add_child(welcome)
	var companion := Label.new()
	var equipped := MetaCatalog.companion(AppState.equipped_companion())
	companion.text = str(equipped.get("name", "Sparkle")).to_upper()
	companion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	companion.add_theme_font_size_override("font_size", 48)
	companion.add_theme_color_override("font_color", PINK)
	page.add_child(companion)
	var identity := Label.new()
	identity.text = "Current Companion  •  %d playable games" % GameRegistry.playable_count()
	identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identity.add_theme_color_override("font_color", CYAN)
	page.add_child(identity)
	var hero := Control.new()
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.custom_minimum_size.y = 300
	page.add_child(hero)
	var preview := _build_sparkle_preview()
	hero.add_child(preview)
	preview.anchor_left = 0.0
	preview.anchor_right = 1.0
	preview.anchor_top = 0.5
	preview.anchor_bottom = 0.5
	preview.offset_left = 0
	preview.offset_right = 0
	preview.offset_top = -150
	preview.offset_bottom = 150
	var play := _make_button("▶  PLAY", Color("36d399"), 82)
	play.add_theme_font_size_override("font_size", 28)
	play.pressed.connect(func() -> void: _show_dashboard())
	page.add_child(play)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	page.add_child(row)
	var profile := _make_button("PROFILE", PANEL, 74)
	profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile.pressed.connect(func() -> void: _show_profile())
	row.add_child(profile)
	var shop := _make_button("SHOP", PANEL, 74)
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta/marketplace.tscn"))
	row.add_child(shop)
	var alley := _make_button("UNICORN ALLEY", PINK, 68)
	alley.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta/unicorn_alley.tscn"))
	page.add_child(alley)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 44)
	status_label.add_theme_color_override("font_color", YELLOW)
	page.add_child(status_label)


func _show_home_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message


func _show_dashboard() -> void:
	AppState.shell_view = "dashboard"
	_reset_page()
	_add_header("GAME CATEGORIES", true, true, func() -> void: _show_home())
	var intro := Label.new()
	intro.text = "Choose a path"
	intro.add_theme_font_size_override("font_size", 28)
	intro.add_theme_color_override("font_color", TEXT)
	page.add_child(intro)
	var categories := [
		{"name": "Number", "desc": "Logic & arithmetic", "color": CYAN},
		{"name": "Word", "desc": "Vocabulary, spelling & rhymes", "color": PINK},
		{"name": "Mystery", "desc": "Detective word puzzles", "color": Color("9b8cff")},
		{"name": "Arcade", "desc": "Experimental action", "color": Color("62e6a7")},
	]
	for category in categories:
		var games := GameRegistry.games_in_category(category["name"])
		var text := "%s\n%s  •  %d/%d playable" % [str(category["name"]).to_upper(), category["desc"], GameRegistry.playable_count(category["name"]), games.size()]
		var button := _make_button(text, category["color"], 104)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_show_category.bind(category["name"]))
		page.add_child(button)


func _show_category(category: String) -> void:
	AppState.set_shell_destination("category", category)
	_reset_page()
	_add_header("%s GAMES" % category.to_upper(), true, true, func() -> void: _show_dashboard())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for game in GameRegistry.games_in_category(category):
		var playable := not str(game["scene"]).is_empty()
		var level := AppState.current_level(game["id"])
		var text := "%s\n%s" % [game["title"], "LEVEL %d" % level if playable else "COMING IN PORT"]
		var button := _make_button(text, PANEL if playable else Color("111a35"), 102)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_open_game.bind(game))
		grid.add_child(button)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", YELLOW)
	content.add_child(status_label)


func _open_game(game: Dictionary) -> void:
	if str(game["scene"]).is_empty():
		status_label.text = "%s is registered for exact parity but is not ported yet." % game["title"]
		return
	AppState.select_game(game["id"], game["category"])
	get_tree().change_scene_to_file(game["scene"])


func _show_profile() -> void:
	AppState.shell_view = "profile"
	_reset_page()
	_add_header("PROFILE", true, true, func() -> void: _show_home())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	var player := Label.new()
	player.text = "%s\n★ %d coins  •  %d completed runs" % [AppState.player_name(), AppState.coins(), AppState.completed_run_count()]
	player.add_theme_font_size_override("font_size", 24)
	player.add_theme_color_override("font_color", CYAN)
	content.add_child(player)
	var progress_title := Label.new()
	progress_title.text = "GAME PROGRESS"
	progress_title.add_theme_font_size_override("font_size", 18)
	progress_title.add_theme_color_override("font_color", PINK)
	content.add_child(progress_title)
	for category in ["Number", "Word", "Mystery", "Arcade"]:
		var category_label := Label.new()
		category_label.text = category.to_upper()
		category_label.add_theme_color_override("font_color", YELLOW)
		content.add_child(category_label)
		for game in GameRegistry.games_in_category(category):
			var record := AppState.progress_for_game(game["id"])
			var completed: Array = record.get("completed", [])
			var row := Label.new()
			row.text = "%s — Level %d, %d runs" % [game["title"], AppState.current_level(game["id"]), completed.size()]
			row.add_theme_color_override("font_color", TEXT if not completed.is_empty() else MUTED)
			content.add_child(row)
	var settings_title := Label.new()
	settings_title.text = "SETTINGS"
	settings_title.add_theme_font_size_override("font_size", 18)
	settings_title.add_theme_color_override("font_color", PINK)
	content.add_child(settings_title)
	for setting_data in [
		{"key": "music", "label": "Music"},
		{"key": "sound", "label": "Sound effects"},
		{"key": "reduced_motion", "label": "Reduced motion"},
	]:
		var toggle := CheckButton.new()
		toggle.text = setting_data["label"]
		toggle.button_pressed = bool(AppState.setting(setting_data["key"], setting_data["key"] != "reduced_motion"))
		toggle.toggled.connect(func(value: bool) -> void: AppState.set_setting(setting_data["key"], value))
		content.add_child(toggle)
	var logout := _make_button("LOG OUT", Color("7c2948"), 60)
	logout.pressed.connect(func() -> void:
		AppState.logout()
		_show_login()
	)
	content.add_child(logout)


func _add_header(title: String, show_back: bool, show_home: bool, back_action: Callable = Callable()) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	page.add_child(header)
	if show_back:
		var back := Button.new()
		back.text = "‹ BACK"
		back.pressed.connect(back_action)
		header.add_child(back)
	var label := Label.new()
	label.text = title if not title.is_empty() else "UNICORN ARCADE"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", PINK)
	header.add_child(label)
	coin_label = Label.new()
	coin_label.text = "★ %d" % AppState.coins()
	coin_label.add_theme_color_override("font_color", YELLOW)
	header.add_child(coin_label)
	if show_home:
		var home := Button.new()
		home.text = "⌂"
		home.pressed.connect(func() -> void: _show_home())
		header.add_child(home)


func _make_button(text: String, color: Color, height: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(color))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12)))
	return button


func _build_sparkle_preview() -> SubViewportContainer:
	var container := RoomItemPreviewScene.new()
	container.custom_minimum_size = Vector2(0, 300)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.setup({"id": "companion_%s" % AppState.equipped_companion(), "category": "companions"})
	return container


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(CYAN, 0.30)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style
