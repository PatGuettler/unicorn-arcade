extends Control

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const NAVY := Color("08112f")
const PANEL := Color("14214a")
const PANEL_HOVER := Color("24366b")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const TEXT := Color("f7f1ff")
const MUTED := Color("aab7e8")
const MEADOW_BACKGROUND = preload("res://assets/meta/environments/magical_meadow_v1.png")
const TITLE_SIGN = preload("res://assets/ui/title_sign_option3_v1.png")
const HOME_TITLE_SIGN = preload("res://assets/ui/title_sign_option3_compact_v1.png")
const ALLEY_STREET_SIGN = preload("res://assets/ui/unicorn_alley_street_sign_compact_v1.png")
const PENNY_TEXTURE_PATH := "res://assets/games/currency/penny.png"
const RoomItemPreviewScene = preload("res://scripts/meta/room_item_preview_3d.gd")
const ArcadePictogramScene = preload("res://scripts/ui/arcade_pictogram.gd")
const ProgressRingScene = preload("res://scripts/ui/progress_ring.gd")

var page: VBoxContainer
var status_label: Label
var coin_label: Label
var profile_category_filter := "All"
var _page_generation := 0


func _ready() -> void:
	if AppState.player_name().is_empty():
		_show_login()
	else:
		_show_view(AppState.shell_view)
	_sync_ad_bar()


func _sync_ad_bar() -> void:
	AdBarService.attach_to(self, AppState.player_name())


func _show_view(view: String) -> void:
	if AppState.player_name().is_empty():
		_show_login()
		_sync_ad_bar()
		return
	AppState.shell_view = view
	match view:
		"dashboard": _show_dashboard()
		"category": _show_category(AppState.selected_category)
		"profile": _show_profile()
		_: _show_home()
	_sync_ad_bar()


func _reset_page(use_meadow: bool = false) -> VBoxContainer:
	_page_generation += 1
	for child in get_children():
		if child.name == "AdDisclosure":
			continue
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
		meadow_tint.color = Color(0.16, 0.08, 0.20, 0.10)
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
	var ad_reserve := 20.0
	if (
		AdBarService.should_show_for_player_logged_in(AppState.player_name())
		and AdBarService.ads_enabled()
	):
		ad_reserve = maxf(20.0, AdBarService.banner_height() + 8.0)
	margin.add_theme_constant_override("margin_bottom", int(ad_reserve))
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
	var brand := TextureRect.new()
	brand.name = "IllustratedTitleSign"
	brand.texture = TITLE_SIGN
	brand.custom_minimum_size = Vector2(0, 245)
	brand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(brand)
	var tagline_plaque := PanelContainer.new()
	tagline_plaque.name = "TaglinePlaque"
	tagline_plaque.custom_minimum_size = Vector2(0, 56)
	tagline_plaque.add_theme_stylebox_override("panel", StorybookUI.plaque_style())
	page.add_child(tagline_plaque)
	var tagline := Label.new()
	tagline.text = "Train your brain with code-based games."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", StorybookUI.INK)
	tagline.add_theme_color_override("font_outline_color", Color("fff3d600"))
	tagline.add_theme_constant_override("outline_size", 0)
	tagline.add_theme_font_size_override("font_size", 19)
	tagline_plaque.add_child(tagline)
	var name_prompt := Label.new()
	name_prompt.name = "PlayerNamePrompt"
	name_prompt.text = "WHAT SHOULD WE CALL YOU?"
	name_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_prompt.add_theme_font_size_override("font_size", 22)
	name_prompt.add_theme_color_override("font_color", StorybookUI.INK)
	name_prompt.add_theme_color_override("font_outline_color", StorybookUI.CREAM)
	name_prompt.add_theme_constant_override("outline_size", 3)
	page.add_child(name_prompt)
	var name_input := LineEdit.new()
	name_input.name = "PlayerNameInput"
	name_input.placeholder_text = "Tap here and enter your name"
	name_input.custom_minimum_size = Vector2(0, 64)
	name_input.add_theme_font_size_override("font_size", 21)
	page.add_child(name_input)
	var enter := _make_button("ENTER ARCADE", StorybookUI.NAVY, 68)
	enter.disabled = true
	name_input.text_changed.connect(func(value: String) -> void: enter.disabled = value.strip_edges().is_empty())
	var submit := func() -> void:
		if name_input.text.strip_edges().is_empty():
			return
		AppState.set_player_name(name_input.text)
		AppState.shell_view = "home"
		_show_view("home")
	enter.pressed.connect(submit)
	name_input.text_submitted.connect(func(_value: String) -> void: submit.call())
	page.add_child(enter)
	var preview := _build_sparkle_preview()
	preview.name = "LoginCompanionPreview"
	preview.custom_minimum_size.y = 210
	page.add_child(preview)
	var bottom := Control.new()
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(bottom)
	# Leave the field unfocused. Android otherwise opens its keyboard before
	# the child chooses to type and covers the lower half of the form.
	_sync_ad_bar()


func _show_home() -> void:
	_reset_page(true)
	_add_header("", false, false)
	var welcome := Label.new()
	welcome.name = "HomeWelcomeText"
	welcome.text = "WELCOME, %s" % AppState.player_name().to_upper()
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.add_theme_font_size_override("font_size", 22)
	welcome.add_theme_color_override("font_color", StorybookUI.INK)
	welcome.add_theme_color_override("font_outline_color", Color(StorybookUI.CREAM, 0.90))
	welcome.add_theme_constant_override("outline_size", 3)
	page.add_child(welcome)
	var companion := Label.new()
	var equipped := MetaCatalog.companion(AppState.equipped_companion())
	companion.text = str(equipped.get("name", "Sparkle")).to_upper()
	companion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	companion.add_theme_font_size_override("font_size", 48)
	companion.add_theme_color_override("font_color", PINK)
	page.add_child(companion)
	var identity := Label.new()
	identity.name = "HomeCompanionSummary"
	identity.text = "Current Companion  •  %d playable games" % GameRegistry.playable_count()
	identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identity.add_theme_font_size_override("font_size", 21)
	identity.add_theme_color_override("font_color", Color("254b54"))
	identity.add_theme_color_override("font_outline_color", Color(StorybookUI.CREAM, 0.90))
	identity.add_theme_constant_override("outline_size", 3)
	page.add_child(identity)
	var hero := Control.new()
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.custom_minimum_size.y = 300
	page.add_child(hero)
	var meadow_companions := Control.new()
	meadow_companions.name = "OwnedMeadowCompanions"
	meadow_companions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meadow_companions.z_index = 4
	hero.add_child(meadow_companions)
	meadow_companions.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_meadow_companions(meadow_companions)
	var preview := _build_sparkle_preview()
	preview.name = "EquippedMeadowHero"
	hero.add_child(preview)
	preview.anchor_left = 0.0
	preview.anchor_right = 1.0
	preview.anchor_top = 0.5
	preview.anchor_bottom = 0.5
	preview.offset_left = 0
	preview.offset_right = 0
	preview.offset_top = -70
	preview.offset_bottom = 230
	var play := _make_button("▶  PLAY", StorybookUI.NAVY, 82)
	play.add_theme_font_size_override("font_size", 28)
	play.pressed.connect(func() -> void: _show_dashboard())
	page.add_child(play)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	page.add_child(row)
	var profile := _make_button("PROFILE", StorybookUI.NAVY, 74)
	profile.name = "ProfileButton"
	profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Defer the screen replacement until the button event has completed. This
	# keeps Android touch dispatch alive while the profile starts building.
	profile.pressed.connect(func() -> void: _show_view.call_deferred("profile"))
	row.add_child(profile)
	var shop := _make_button("SHOP", StorybookUI.NAVY, 74)
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta/marketplace.tscn"))
	row.add_child(shop)
	var alley := _make_art_button("UNICORN ALLEY", ALLEY_STREET_SIGN, 150)
	alley.name = "UnicornAlleyStreetSignButton"
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
		var button := _make_category_card(category, GameRegistry.playable_count(category["name"]), games.size())
		button.pressed.connect(_show_category.bind(category["name"]))
		page.add_child(button)


func _show_category(category: String) -> void:
	AppState.set_shell_destination("category", category)
	_reset_page()
	_add_header("%s GAMES" % category.to_upper(), true, true, func() -> void: _show_dashboard())
	var content := _make_vertical_scroll("CategoryContent", 12)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for game in GameRegistry.games_in_category(category):
		var playable := not str(game["scene"]).is_empty()
		var level := AppState.current_level(game["id"])
		var button := _make_game_card(game, playable, level)
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
	var generation := _page_generation
	_add_header("PROFILE", true, true, func() -> void: _show_home())
	var content := _make_vertical_scroll("ProfileContent", 18)
	var loading := Label.new()
	loading.name = "ProfileLoading"
	loading.text = "Opening your profile…"
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.add_theme_font_size_override("font_size", 20)
	loading.add_theme_color_override("font_color", MUTED)
	content.add_child(loading)
	_populate_profile.call_deferred(content, generation)


func _populate_profile(content: VBoxContainer, generation: int) -> void:
	if not _profile_page_is_current(content, generation):
		return
	var loading := content.get_node_or_null("ProfileLoading")
	if is_instance_valid(loading):
		loading.queue_free()
	content.add_child(_build_profile_unicorn_banner())
	content.add_child(_build_profile_stat_strip())
	content.add_child(_profile_section_title("MAGIC RINGS"))
	content.add_child(_build_profile_progress_rings())
	await get_tree().process_frame
	if not _profile_page_is_current(content, generation):
		return
	content.add_child(_profile_section_title("YOUR GAMES"))
	content.add_child(_build_profile_category_chips())
	var game_grid := _build_profile_game_grid_shell()
	content.add_child(game_grid)
	await _populate_profile_game_grid(game_grid, generation)
	if not _profile_page_is_current(content, generation):
		return
	content.add_child(_profile_section_title("SETTINGS & LEARNING"))
	content.add_child(_build_profile_settings())
	var logout := _make_button("LOG OUT", Color("7c2948"), 60)
	logout.pressed.connect(func() -> void:
		AppState.logout()
		_show_login()
	)
	content.add_child(logout)
	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size.y = 24
	content.add_child(bottom_pad)


func _profile_page_is_current(content: Control, generation: int) -> bool:
	return (
		generation == _page_generation
		and is_instance_valid(content)
		and content.is_inside_tree()
		and AppState.shell_view == "profile"
	)


func _build_profile_unicorn_banner() -> PanelContainer:
	var companion := MetaCatalog.companion(AppState.equipped_companion())
	var ability_definition := CompanionAbilityService.definition()
	var banner := PanelContainer.new()
	banner.name = "EquippedUnicornBanner"
	banner.custom_minimum_size.y = 268
	banner.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("241c55"), Color("f26fa7"), 24))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	banner.add_child(stack)
	var eyebrow := Label.new()
	eyebrow.text = "EQUIPPED UNICORN"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", Color("f4d37f"))
	stack.add_child(eyebrow)
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 14)
	stack.add_child(hero_row)
	var preview := _build_companion_preview(AppState.equipped_companion(), "profile", 188)
	preview.custom_minimum_size = Vector2(188, 168)
	hero_row.add_child(preview)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override("separation", 8)
	hero_row.add_child(identity)
	identity.add_child(_card_label(AppState.player_name().to_upper(), 28, Color("fff3d6"), HORIZONTAL_ALIGNMENT_CENTER))
	identity.add_child(_card_label(str(companion.get("name", "Sparkle")).to_upper(), 24, Color("f26fa7"), HORIZONTAL_ALIGNMENT_CENTER))
	var power := Label.new()
	power.text = "✦ %s\n%s" % [str(ability_definition.get("name", "Companion Power")).to_upper(), str(ability_definition.get("description", ""))]
	power.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	power.add_theme_font_size_override("font_size", 17)
	power.add_theme_color_override("font_color", Color("c9d3ef"))
	identity.add_child(power)
	var alley := _make_button("VISIT UNICORN ALLEY", Color("c45186"), 54)
	alley.pressed.connect(func() -> void: _show_dashboard())
	stack.add_child(alley)
	return banner


func _build_profile_stat_strip() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "ProfileStatStrip"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for card in [
		_profile_money_stat(AppState.coins(), "COINS"),
		_profile_stat("%d" % AppState.completed_run_count(), "RUNS"),
		_profile_stat("%d / 6" % AppState.owned_companions().size(), "UNICORNS"),
		_profile_stat("%d" % AppState.data.get("inventory", {}).size(), "DECOR"),
	]:
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
	return grid


func _build_profile_progress_rings() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "ProfileProgressRings"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("17254d"), StorybookUI.GOLD, 20))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	card.add_child(grid)
	for category in ["Number", "Word", "Mystery", "Arcade"]:
		var progress := _category_progress_ratio(category)
		var runs := _category_run_count(category)
		var ring := ProgressRingScene.new()
		ring.setup(progress, category.to_upper(), "%d RUNS" % runs, _category_color(category))
		ring.custom_minimum_size = Vector2(0, 148)
		ring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(ring)
	return card


func _build_profile_category_chips() -> HFlowContainer:
	var row := HFlowContainer.new()
	row.name = "ProfileCategoryChips"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	for category in ["All", "Number", "Word", "Mystery", "Arcade"]:
		var chip := Button.new()
		chip.text = category.to_upper()
		chip.custom_minimum_size = Vector2(88, 48)
		chip.toggle_mode = true
		chip.button_pressed = profile_category_filter == category
		var fill := Color("22345f")
		if profile_category_filter == category:
			fill = StorybookUI.GOLD if category == "All" else _category_color(category)
		StorybookUI.apply_button(chip, fill, profile_category_filter == category and category == "All", 14)
		chip.pressed.connect(func() -> void:
			profile_category_filter = category
			_show_profile()
		)
		row.add_child(chip)
	return row


func _build_profile_game_grid_shell() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "ProfileGameGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	return grid


func _populate_profile_game_grid(grid: GridContainer, generation: int) -> void:
	var categories := ["Number", "Word", "Mystery", "Arcade"] if profile_category_filter == "All" else [profile_category_filter]
	var added := 0
	for category in categories:
		for game in GameRegistry.games_in_category(category):
			if not _profile_page_is_current(grid, generation):
				return
			grid.add_child(_build_profile_game_tile(game, category))
			added += 1
			if added % 4 == 0:
				await get_tree().process_frame


func _build_profile_game_tile(game: Dictionary, category: String) -> PanelContainer:
	var completed: Array = AppState.progress_for_game(game["id"]).get("completed", [])
	var level := AppState.current_level(game["id"])
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(0, 126)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("fff3d6"), _category_color(category), 14))
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 4)
	tile.add_child(stack)
	var pictogram := ArcadePictogramScene.new()
	pictogram.custom_minimum_size = Vector2(58, 58)
	pictogram.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pictogram.setup(str(game["id"]), _category_color(category))
	stack.add_child(pictogram)
	var title_line := Label.new()
	title_line.text = str(game["title"]).to_upper()
	title_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_line.add_theme_font_size_override("font_size", 15)
	title_line.add_theme_color_override("font_color", StorybookUI.INK)
	stack.add_child(title_line)
	var progress_line := Label.new()
	progress_line.text = "LV %d  •  %d RUNS" % [level, completed.size()]
	progress_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_line.add_theme_font_size_override("font_size", 14)
	progress_line.add_theme_color_override("font_color", Color("254b54"))
	stack.add_child(progress_line)
	return tile


func _build_profile_settings() -> PanelContainer:
	var settings_card := PanelContainer.new()
	settings_card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("fff3d6"), StorybookUI.GOLD, 18))
	var settings_stack := VBoxContainer.new()
	settings_stack.add_theme_constant_override("separation", 8)
	settings_card.add_child(settings_stack)
	for setting_data in [
		{"key": "music", "label": "Music"},
		{"key": "sound", "label": "Sound effects"},
		{"key": "reduced_motion", "label": "Reduced motion"},
		{"key": "tutorials_enabled", "label": "Guided first three levels"},
	]:
		var toggle := CheckButton.new()
		toggle.text = setting_data["label"]
		toggle.button_pressed = bool(AppState.setting(setting_data["key"], setting_data["key"] != "reduced_motion"))
		toggle.custom_minimum_size.y = 56
		toggle.add_theme_font_size_override("font_size", 19)
		toggle.add_theme_color_override("font_color", StorybookUI.INK)
		toggle.toggled.connect(func(value: bool) -> void: AppState.set_setting(setting_data["key"], value))
		settings_stack.add_child(toggle)
	var reset_tutorials := _make_button("RESET ALL TUTORIALS", Color("6d3f83"), 60)
	reset_tutorials.pressed.connect(func() -> void:
		var dialog := ConfirmationDialog.new()
		dialog.title = "Reset tutorials?"
		dialog.dialog_text = "The first three guided levels will be available again in every game."
		page.add_child(dialog)
		dialog.confirmed.connect(func() -> void:
			AppState.reset_tutorials()
			status_label.text = "Tutorial progress reset."
			dialog.queue_free()
		)
		dialog.popup_centered(Vector2i(520, 260))
	)
	settings_stack.add_child(reset_tutorials)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color("254b54"))
	settings_stack.add_child(status_label)
	return settings_card


func _category_progress_ratio(category: String) -> float:
	var games := GameRegistry.games_in_category(category)
	if games.is_empty():
		return 0.0
	var total := 0.0
	for game in games:
		total += clampf(float(AppState.current_level(game["id"]) - 1) / 20.0, 0.0, 1.0)
	return total / float(games.size())


func _category_run_count(category: String) -> int:
	var completed_count := 0
	for game in GameRegistry.games_in_category(category):
		completed_count += AppState.progress_for_game(game["id"]).get("completed", []).size()
	return completed_count


func _make_vertical_scroll(content_name: String, separation: int = 14) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "%sScroll" % content_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.clip_contents = true
	page.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = content_name
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", separation)
	scroll.add_child(content)
	# Keep the scroll child as wide as the viewport so tiles wrap instead of clipping.
	scroll.resized.connect(func() -> void:
		if is_instance_valid(content):
			content.custom_minimum_size.x = scroll.size.x
	)
	return content


func _profile_stat(value: String, caption: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 70)
	card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("f7d8eb"), Color("d16b9e"), 12))
	var label := Label.new()
	label.text = "%s\n%s" % [value, caption]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", StorybookUI.INK)
	card.add_child(label)
	return card


func _profile_money_stat(amount: int, caption: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 70)
	card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("f7d8eb"), Color("d16b9e"), 12))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var coin := TextureRect.new()
	coin.texture = load(PENNY_TEXTURE_PATH) as Texture2D
	coin.custom_minimum_size = Vector2(34, 34)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(coin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(stack)
	var value := Label.new()
	value.text = str(amount)
	value.add_theme_font_size_override("font_size", 22)
	value.add_theme_color_override("font_color", StorybookUI.INK)
	stack.add_child(value)
	var cap := Label.new()
	cap.text = caption
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 14)
	cap.add_theme_color_override("font_color", Color("254b54"))
	stack.add_child(cap)
	return card


func _profile_section_title(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("9c356d"))
	label.add_theme_color_override("font_outline_color", StorybookUI.CREAM)
	label.add_theme_constant_override("outline_size", 3)
	return label


func _add_header(title: String, show_back: bool, show_home: bool, back_action: Callable = Callable()) -> void:
	var header := GridContainer.new()
	header.name = "CenteredHeader"
	header.columns = 3
	header.add_theme_constant_override("h_separation", 8)
	header.custom_minimum_size.y = 150 if title.is_empty() else 60
	page.add_child(header)
	var left := HBoxContainer.new()
	left.custom_minimum_size.x = 125
	header.add_child(left)
	if show_back:
		var back := Button.new()
		back.text = "‹ BACK"
		back.pressed.connect(back_action)
		left.add_child(back)
	var center := Control.new()
	center.name = "TrueCenterHeaderSlot"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.custom_minimum_size.y = 150 if title.is_empty() else 60
	center.clip_contents = true
	header.add_child(center)
	if title.is_empty():
		var sign := TextureRect.new()
		sign.name = "HomeTitleSign"
		sign.texture = HOME_TITLE_SIGN
		sign.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sign.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(sign)
		sign.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var label := Label.new()
		label.name = "CenteredHeaderTitle"
		label.text = title
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", StorybookUI.CREAM)
		label.add_theme_color_override("font_outline_color", StorybookUI.PLUM)
		label.add_theme_constant_override("outline_size", 3)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(label)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var right := HBoxContainer.new()
	right.custom_minimum_size.x = 125
	right.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(right)
	coin_label = Label.new()
	coin_label.name = "CoinBalanceLabel"
	coin_label.text = "★ %d" % AppState.coins()
	coin_label.add_theme_color_override("font_color", YELLOW)
	coin_label.add_theme_color_override("font_outline_color", StorybookUI.PLUM)
	coin_label.add_theme_constant_override("outline_size", 3)
	coin_label.add_theme_font_size_override("font_size", 24)
	coin_label.custom_minimum_size.y = 48
	coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right.add_child(coin_label)
	if show_home:
		var home := Button.new()
		home.name = "HeaderHomeButton"
		home.tooltip_text = "Return home"
		StorybookUI.apply_home_button(home)
		home.pressed.connect(func() -> void: _show_home())
		right.add_child(home)


func _make_button(text: String, color: Color, height: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.add_theme_font_size_override("font_size", 18)
	StorybookUI.apply_button(button, color, StorybookUI.uses_dark_ink(color))
	return button


func _make_category_card(definition: Dictionary, playable_count: int, game_count: int) -> Button:
	var category_name := str(definition["name"])
	var color: Color = definition["color"]
	var button := _make_button(category_name, color, 126)
	button.name = "CategoryCard_%s" % category_name
	button.tooltip_text = "%s Games. %s. %d of %d playable." % [category_name, definition["desc"], playable_count, game_count]
	_hide_native_button_text(button)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	var icon := ArcadePictogramScene.new()
	icon.name = "CategoryIcon"
	icon.custom_minimum_size = Vector2(82, 82)
	icon.setup(category_name.to_lower(), color)
	row.add_child(icon)
	var details := VBoxContainer.new()
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	row.add_child(details)
	details.add_child(_card_label("%s GAMES" % category_name.to_upper(), 23, StorybookUI.INK))
	details.add_child(_card_label(str(definition["desc"]), 19, Color(StorybookUI.INK, 0.82)))
	details.add_child(_card_label("%d / %d PLAYABLE" % [playable_count, game_count], 19, Color("254b54")))
	return button


func _make_game_card(game: Dictionary, playable: bool, level: int) -> Button:
	var title_text := str(game["title"])
	var game_id := str(game["id"])
	var color := _category_color(str(game["category"]))
	var status := "LEVEL %d" % level if playable else "COMING IN PORT"
	var button := _make_button(title_text, PANEL if playable else Color("111a35"), 184)
	button.name = "GameCard_%s" % game_id
	button.tooltip_text = "%s. %s." % [title_text, status]
	_hide_native_button_text(button)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)
	var icon := ArcadePictogramScene.new()
	icon.name = "GameIcon"
	icon.custom_minimum_size = Vector2(82, 82)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.setup(game_id, color)
	stack.add_child(icon)
	var title := _card_label(title_text.to_upper(), 20, StorybookUI.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(title)
	stack.add_child(_card_label(status, 19, color, HORIZONTAL_ALIGNMENT_CENTER))
	return button


func _hide_native_button_text(button: Button) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_outline_color"]:
		button.add_theme_color_override(state, Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)


func _card_label(value: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(StorybookUI.PLUM, 0.72) if color.get_luminance() > 0.55 else Color(StorybookUI.CREAM, 0.46))
	label.add_theme_constant_override("outline_size", 2)
	return label


func _category_color(category: String) -> Color:
	return {
		"Number": CYAN,
		"Word": PINK,
		"Mystery": Color("9b8cff"),
		"Arcade": Color("62e6a7"),
	}.get(category, YELLOW)


func _make_art_button(accessible_text: String, texture: Texture2D, height: float) -> Button:
	var button := Button.new()
	button.text = accessible_text
	# The hidden native text supplies the accessible name. Mobile tooltips can
	# otherwise linger as an unrelated little label over the meadow.
	button.tooltip_text = ""
	button.custom_minimum_size = Vector2(0, height)
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StorybookUI.button_style(Color.TRANSPARENT, StorybookUI.CYAN, 4, 18, 0))
	var art := TextureRect.new()
	art.name = "StreetSignArt"
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.mouse_entered.connect(func() -> void: art.modulate = Color("fff8ee"))
	button.mouse_exited.connect(func() -> void: art.modulate = Color.WHITE)
	button.button_down.connect(func() -> void: art.modulate = Color("e8d9ef"))
	button.button_up.connect(func() -> void: art.modulate = Color.WHITE)
	return button


func _build_sparkle_preview() -> SubViewportContainer:
	return _build_companion_preview(AppState.equipped_companion(), "hero", 300.0)


func _build_companion_preview(companion_id: String, presentation: String, minimum_height: float) -> SubViewportContainer:
	var container := RoomItemPreviewScene.new()
	container.custom_minimum_size = Vector2(0, minimum_height)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.setup({"id": "companion_%s" % companion_id, "category": "companions", "presentation": presentation})
	return container


func _build_meadow_companions(layer: Control) -> void:
	var equipped_id := AppState.equipped_companion()
	var slots := [
		{"x": 0.14, "y": 0.67, "w": 156.0, "h": 112.0},
		{"x": 0.84, "y": 0.72, "w": 164.0, "h": 118.0},
		{"x": 0.31, "y": 0.57, "w": 148.0, "h": 106.0},
		{"x": 0.69, "y": 0.61, "w": 152.0, "h": 110.0},
		{"x": 0.50, "y": 0.76, "w": 160.0, "h": 116.0},
	]
	var slot_index := 0
	for owned_id in AppState.owned_companions():
		var companion_id := str(owned_id)
		if companion_id == equipped_id or slot_index >= slots.size():
			continue
		var slot: Dictionary = slots[slot_index]
		var preview := _build_companion_preview(companion_id, "meadow_background", float(slot["h"]))
		preview.name = "MeadowCompanion_%s" % companion_id.capitalize()
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(preview)
		preview.anchor_left = float(slot["x"])
		preview.anchor_right = float(slot["x"])
		preview.anchor_top = float(slot["y"])
		preview.anchor_bottom = float(slot["y"])
		preview.offset_left = -float(slot["w"]) * 0.5
		preview.offset_right = float(slot["w"]) * 0.5
		preview.offset_top = -float(slot["h"]) * 0.5
		preview.offset_bottom = float(slot["h"]) * 0.5
		slot_index += 1
