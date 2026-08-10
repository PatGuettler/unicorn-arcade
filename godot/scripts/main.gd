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
const RoomItemPreviewScene = preload("res://scripts/meta/room_item_preview_3d.gd")
const MeadowCompanionStageScene = preload("res://scripts/meta/meadow_companion_stage_3d.gd")
const ArcadePictogramScene = preload("res://scripts/ui/arcade_pictogram.gd")
const UnicornHeader = preload("res://scripts/ui/unicorn_header.gd")
const ProfileView = preload("res://scripts/ui/profile_view.gd")

var page: VBoxContainer
var status_label: Label
var coin_label: Label
var profile_category_filter := "All"
signal profile_build_complete
signal page_build_complete
signal scene_change_ready
var _page_generation := 0
var _meadow_stage: MeadowCompanionStage3D
var _meadow_display: TextureRect


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
		"dashboard": await _show_dashboard()
		"category": await _show_category(AppState.selected_category)
		"profile": await _show_profile()
		_: await _show_home()
	_sync_ad_bar()


func _reset_page(use_meadow: bool = false) -> VBoxContainer:
	if not use_meadow and is_instance_valid(_meadow_stage):
		_meadow_stage.set_active(false)
	if not use_meadow and is_instance_valid(_meadow_display):
		_meadow_display.visible = false
		_meadow_display.texture = null
	_page_generation += 1
	var generation := _page_generation
	var outgoing: Array[Node] = []
	for child in get_children():
		if child == _meadow_stage:
			continue
		outgoing.append(child)
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		for viewport_node in child.find_children("*", "SubViewport", true, false):
			(viewport_node as SubViewport).render_target_update_mode = SubViewport.UPDATE_DISABLED
	await _await_page_retire_frames()
	if generation != _page_generation:
		return null
	if not use_meadow and is_instance_valid(_meadow_stage):
		_meadow_stage.queue_free()
		_meadow_stage = null
	for child in outgoing:
		if is_instance_valid(child) and child.get_parent() == self:
			child.queue_free()
	if not use_meadow:
		_meadow_display = null
	await _await_page_retire_frames()
	if generation != _page_generation:
		return null
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
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	return page


func _await_page_retire_frames() -> void:
	for _frame in 2:
		await get_tree().process_frame


func _attach_meadow_stage(host: Control) -> void:
	if not is_instance_valid(_meadow_stage):
		_meadow_stage = MeadowCompanionStageScene.new()
		_meadow_stage.name = "MeadowCompanionStage3D"
		_meadow_stage.setup(AppState.equipped_companion(), AppState.owned_companions())
		add_child(_meadow_stage)
	_meadow_display = _meadow_stage.create_display()
	host.add_child(_meadow_display)
	_meadow_stage.set_active(true)


func prepare_for_scene_change() -> Signal:
	_page_generation += 1
	_finish_scene_change_cleanup.call_deferred()
	return scene_change_ready


func _finish_scene_change_cleanup() -> void:
	if is_instance_valid(_meadow_stage):
		_meadow_stage.set_active(false)
	if is_instance_valid(_meadow_display):
		_meadow_display.visible = false
		_meadow_display.texture = null
	await _await_page_retire_frames()
	scene_change_ready.emit()


func _change_scene_safely(path: String) -> void:
	await prepare_for_scene_change()
	get_tree().change_scene_to_file(path)


func _show_login() -> void:
	if await _reset_page(true) == null:
		return
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
	var profiles := AppState.profile_names()
	if not profiles.is_empty():
		var choose_label := Label.new()
		choose_label.text = "OR PICK A SAVED PROFILE"
		choose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choose_label.add_theme_font_size_override("font_size", 15)
		page.add_child(choose_label)
		var choices := HBoxContainer.new()
		choices.alignment = BoxContainer.ALIGNMENT_CENTER
		choices.add_theme_constant_override("separation", 8)
		page.add_child(choices)
		for profile_name in profiles:
			var profile_button := _make_button(profile_name.to_upper(), StorybookUI.NAVY, 52)
			profile_button.pressed.connect(func() -> void:
				if AppState.select_profile(profile_name): _show_view("home")
			)
			choices.add_child(profile_button)
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
	page_build_complete.emit()


func _show_home() -> void:
	if await _reset_page(true) == null:
		return
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
	companion.add_theme_constant_override("outline_size", 2)
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
	_attach_meadow_stage(hero)
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
	shop.pressed.connect(func() -> void: _change_scene_safely.call_deferred("res://scenes/meta/marketplace.tscn"))
	row.add_child(shop)
	var alley := _make_art_button("UNICORN ALLEY", ALLEY_STREET_SIGN, 150)
	alley.name = "UnicornAlleyStreetSignButton"
	alley.add_theme_font_size_override("font_size", 19)
	alley.pressed.connect(func() -> void: _change_scene_safely.call_deferred("res://scenes/meta/unicorn_alley.tscn"))
	page.add_child(alley)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 44)
	status_label.add_theme_color_override("font_color", YELLOW)
	page.add_child(status_label)
	page_build_complete.emit()


func _show_home_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message


func _show_dashboard() -> void:
	AppState.shell_view = "dashboard"
	if await _reset_page() == null:
		return
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
	page_build_complete.emit()


func _show_category(category: String) -> void:
	AppState.set_shell_destination("category", category)
	if await _reset_page() == null:
		return
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
	page_build_complete.emit()


func _open_game(game: Dictionary) -> void:
	if str(game["scene"]).is_empty():
		status_label.text = "%s is registered for exact parity but is not ported yet." % game["title"]
		return
	AppState.select_game(game["id"], game["category"])
	await _change_scene_safely(str(game["scene"]))


func _show_profile() -> void:
	AppState.shell_view = "profile"
	if await _reset_page() == null:
		return
	var generation := _page_generation
	_add_header("PROFILE", true, true, func() -> void: _show_home())
	var profile_view := ProfileView.new()
	profile_view.configure(profile_category_filter, func() -> bool: return generation == _page_generation and AppState.shell_view == "profile", Callable(self, "_open_unicorn_alley"), Callable(self, "_show_login"), page)
	page.add_child(profile_view)
	await profile_view.build()
	if generation == _page_generation and is_instance_valid(profile_view) and profile_view.is_inside_tree() and AppState.shell_view == "profile":
		profile_category_filter = profile_view.category_filter
		profile_build_complete.emit()
		page_build_complete.emit()


func _open_unicorn_alley() -> void:
	_change_scene_safely.call_deferred("res://scenes/meta/unicorn_alley.tscn")


func _apply_profile_category_filter(category: String) -> void:
	var profile_view := page.find_child("ProfileContentScroll", true, false) as ProfileView
	if is_instance_valid(profile_view):
		profile_view.apply_category_filter(category)
		profile_category_filter = profile_view.category_filter


func _make_vertical_scroll(content_name: String, separation: int = 14) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "%sScroll" % content_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = false
	scroll.scroll_deadzone = 8
	scroll.clip_contents = true
	page.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = content_name
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", separation)
	scroll.add_child(content)
	return content


func _add_header(title: String, show_back: bool, show_home: bool, back_action: Callable = Callable()) -> void:
	# Dashboard/category/profile share the exact shell header used by Alley/Room.
	# Home keeps its illustrated sign as its intentional identity treatment.
	if not title.is_empty():
		var action := back_action if show_back and back_action.is_valid() else Callable(self, "_show_home")
		var shared := UnicornHeader.build(title, "BACK" if show_back else "HOME", action, _show_home)
		page.add_child(shared)
		coin_label = shared.find_child("SharedCoinBalance", true, false) as Label
		return
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
