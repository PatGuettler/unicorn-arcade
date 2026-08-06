extends Node

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const TutorialCatalog = preload("res://scripts/tutorial_catalog.gd")
const RoomItemPreviewScene = preload("res://scripts/meta/room_item_preview_3d.gd")
const ProgressRingScene = preload("res://scripts/ui/progress_ring.gd")
const PENNY_TEXTURE_PATH := "res://assets/games/currency/penny.png"
const MEADOW_BACKGROUND_PATH := "res://assets/meta/environments/magical_meadow_v1.png"

var attached_scene: Node
var attached_game_id := ""
var objective_primary: Label
var objective_detail: Label
var coin_button: Button
var ability_button: Button
var inactivity_seconds := 0.0
var last_level := -1
var update_accumulator := 0.0
var was_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AppState.coins_changed.connect(_update_coin_button)


func _input(_event: InputEvent) -> void:
	inactivity_seconds = 0.0


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != attached_scene:
		attached_scene = scene
		attached_game_id = ""
		objective_primary = null
		objective_detail = null
		coin_button = null
		ability_button = null
		last_level = -1
		was_active = false
		inactivity_seconds = 0.0
		if _is_game_scene(scene):
			_attach_scene.call_deferred(scene)
		return
	if attached_game_id.is_empty() or not is_instance_valid(scene):
		return
	inactivity_seconds += delta
	update_accumulator += delta
	if update_accumulator >= 0.15:
		update_accumulator = 0.0
		_update_runtime_ui()
	var scene_active := bool(attached_scene.get("active")) if _has_property(attached_scene, "active") else true
	if was_active and not scene_active and _is_retry_failure() and CompanionAbilityService.consume_checkpoint_retry():
		_restart_after_sparkle.call_deferred()
	was_active = scene_active
	var current_level := _scene_int(scene, "level", 1)
	if current_level != last_level:
		last_level = current_level
		CompanionAbilityService.begin_level(attached_game_id, current_level)
		_update_ability_button()
		_maybe_show_tutorial.call_deferred(false)
	if inactivity_seconds >= 8.0 and CompanionAbilityService.consume_dream_nudge():
		inactivity_seconds = 0.0
		_show_assist(false)


func _is_game_scene(scene: Node) -> bool:
	return is_instance_valid(scene) and str(scene.scene_file_path).begins_with("res://scenes/games/")


func _attach_scene(scene: Node) -> void:
	if scene != get_tree().current_scene or not is_instance_valid(scene):
		return
	attached_game_id = AppState.selected_game_id
	if attached_game_id.is_empty():
		attached_game_id = _fallback_game_id(str(scene.scene_file_path))
	var game := GameRegistry.get_game(attached_game_id)
	if game.is_empty():
		return
	var layout := _find_primary_layout(scene)
	if layout == null:
		layout = VBoxContainer.new()
		layout.name = "GameExperienceOverlayLayout"
		layout.set_anchors_preset(Control.PRESET_TOP_WIDE)
		layout.offset_left = 14
		layout.offset_right = -14
		layout.offset_top = 14
		layout.z_index = 900
		scene.add_child(layout)
	layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	_apply_storybook_atmosphere(scene)
	_hide_legacy_chrome(layout, str(game["title"]))
	var header := _build_header(str(game["title"]))
	layout.add_child(header)
	layout.move_child(header, 0)
	var plaque := _build_objective_plaque()
	layout.add_child(plaque)
	layout.move_child(plaque, 1)
	_restyle_controls(scene)
	_polish_game_labels(scene)
	last_level = _scene_int(scene, "level", 1)
	CompanionAbilityService.begin_level(attached_game_id, last_level)
	was_active = bool(scene.get("active")) if _has_property(scene, "active") else true
	_update_runtime_ui()
	_update_ability_button()
	_maybe_show_tutorial.call_deferred(false)


func _fallback_game_id(path: String) -> String:
	var filename := path.get_file().get_basename()
	if filename == "word_game":
		return "unicorn_blast"
	return filename


func _find_primary_layout(node: Node) -> VBoxContainer:
	for child in node.get_children():
		if child is VBoxContainer:
			return child
		var found := _find_primary_layout(child)
		if found != null:
			return found
	return null


func _apply_storybook_atmosphere(scene: Node) -> void:
	if not is_instance_valid(scene) or scene.has_node("StorybookAtmosphere"):
		return
	var atmosphere := Control.new()
	atmosphere.name = "StorybookAtmosphere"
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.z_index = -20
	var wash := ColorRect.new()
	wash.color = Color("120d2e")
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.add_child(wash)
	var meadow := TextureRect.new()
	meadow.texture = load(MEADOW_BACKGROUND_PATH) as Texture2D
	meadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	meadow.modulate = Color(1, 1, 1, 0.34)
	meadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.add_child(meadow)
	var veil := ColorRect.new()
	veil.color = Color(0.08, 0.05, 0.22, 0.42)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.add_child(veil)
	scene.add_child(atmosphere)
	scene.move_child(atmosphere, 0)
	for child in scene.get_children():
		if child is ColorRect and child != wash and child != veil:
			var rect := child as ColorRect
			if is_equal_approx(rect.anchor_right, 1.0) and is_equal_approx(rect.anchor_bottom, 1.0):
				rect.color = Color(rect.color, 0.12)
				break


func _hide_legacy_chrome(layout: VBoxContainer, title: String) -> void:
	for child in layout.get_children().slice(0, mini(4, layout.get_child_count())):
		if child is HBoxContainer and _contains_navigation(child):
			child.hide()
		elif child is Label:
			var copy := str((child as Label).text).strip_edges().to_upper()
			if copy == title.to_upper() or copy.begins_with("★") or copy.contains("UNICORN JUMP") or copy.contains("MATHTRIS") or copy.contains("COIN COUNT") or copy.contains("CASH COUNTER") or copy.contains("SLIDING WINDOW") or copy.contains("MATH SWIPE") or copy.contains("GALAXY UNICORN") or copy.contains("RHYME RALLY") or copy.contains("RACE THE UNICORN"):
				child.hide()


func _contains_navigation(node: Node) -> bool:
	for child in node.get_children():
		if child is Button:
			var text := str((child as Button).text).to_upper()
			if "BACK" in text or "GAMES" in text or text == "ARCADE":
				return true
		elif child is Label and str((child as Label).text).begins_with("★"):
			return true
		if _contains_navigation(child):
			return true
	return false


func _build_header(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "StandardGameHeader"
	panel.custom_minimum_size.y = 62
	panel.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("17254d"), StorybookUI.GOLD, 18))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var back := _header_button("‹", "Back to game category")
	back.name = "GameHeaderBack"
	back.pressed.connect(_request_leave.bind(false))
	row.add_child(back)
	var home := _header_button("⌂", "Home")
	home.name = "GameHeaderHome"
	home.pressed.connect(_request_leave.bind(true))
	row.add_child(home)
	var title_label := Label.new()
	title_label.text = title.to_upper()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", StorybookUI.CREAM)
	title_label.add_theme_color_override("font_outline_color", StorybookUI.PLUM)
	title_label.add_theme_constant_override("outline_size", 3)
	row.add_child(title_label)
	var profile := _header_button("👤", "Open profile without leaving this game")
	profile.name = "GameHeaderProfile"
	profile.pressed.connect(_show_profile_overlay)
	row.add_child(profile)
	coin_button = _header_button("", "Current coin balance")
	coin_button.name = "GameHeaderCoins"
	coin_button.custom_minimum_size = Vector2(96, 48)
	coin_button.disabled = true
	coin_button.icon = load(PENNY_TEXTURE_PATH) as Texture2D
	coin_button.expand_icon = true
	coin_button.add_theme_constant_override("icon_max_width", 28)
	coin_button.add_theme_color_override("font_disabled_color", StorybookUI.GOLD_BRIGHT)
	row.add_child(coin_button)
	_update_coin_button(AppState.coins())
	return panel


func _header_button(text: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(48, 48)
	button.add_theme_font_size_override("font_size", 18)
	StorybookUI.apply_button(button, Color("22345f"), false, 14)
	button.set_meta("standard_game_chrome", true)
	return button


func _build_objective_plaque() -> PanelContainer:
	var plaque := PanelContainer.new()
	plaque.name = "GameObjectivePlaque"
	plaque.custom_minimum_size.y = 92
	plaque.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("fff3d6"), Color("e1ae4f"), 18))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	plaque.add_child(row)
	var mascot := RoomItemPreviewScene.new()
	mascot.name = "EquippedCompanionMascot"
	mascot.custom_minimum_size = Vector2(72, 68)
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascot.setup({"id": "companion_%s" % AppState.equipped_companion(), "category": "companions", "animate": false, "presentation": "marketplace"})
	row.add_child(mascot)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.custom_minimum_size.x = 0
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(copy)
	objective_primary = Label.new()
	objective_primary.name = "ObjectivePrimary"
	objective_primary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_primary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_primary.add_theme_font_size_override("font_size", 28)
	objective_primary.add_theme_color_override("font_color", StorybookUI.INK)
	copy.add_child(objective_primary)
	objective_detail = Label.new()
	objective_detail.name = "ObjectiveDetail"
	objective_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_detail.add_theme_font_size_override("font_size", 16)
	objective_detail.add_theme_color_override("font_color", Color("59375c"))
	copy.add_child(objective_detail)
	ability_button = Button.new()
	ability_button.name = "CompanionAbility"
	ability_button.custom_minimum_size = Vector2(102, 54)
	ability_button.add_theme_font_size_override("font_size", 14)
	ability_button.pressed.connect(_ability_pressed)
	StorybookUI.apply_button(ability_button, Color("c45186"), false, 14)
	ability_button.set_meta("standard_game_chrome", true)
	row.add_child(ability_button)
	var help := _header_button("?", "Replay the tutorial")
	help.name = "ObjectiveTutorialHelp"
	help.pressed.connect(_maybe_show_tutorial.bind(true))
	row.add_child(help)
	return plaque


func _update_runtime_ui() -> void:
	if not is_instance_valid(attached_scene) or not is_instance_valid(objective_primary):
		return
	var objective := _objective_for_scene()
	objective_primary.text = str(objective.get("primary", "YOUR MISSION"))
	objective_detail.text = str(objective.get("detail", "Follow the enchanted objective."))
	_update_coin_button(AppState.coins())


func _objective_for_scene() -> Dictionary:
	match attached_game_id:
		"unicorn_jump":
			var data = attached_scene.get("level_data")
			var index := _scene_int(attached_scene, "current_index", 0)
			if data is Array and index < data.size():
				var value := int(data[index])
				return {"primary": "%s  %d" % ["JUMP FORWARD" if value >= 0 else "JUMP BACK", absi(value)], "detail": "COUNT EXACTLY %d STONES • TAP THE LANDING" % absi(value)}
			return {"primary": "TRAIL COMPLETE!", "detail": "You reached the rainbow finish."}
		"coin_count":
			return {"primary": "MAKE %s" % _format_cents(_scene_int(attached_scene, "target", 0)), "detail": "BUILD THE EXACT TOTAL WITH REAL US COINS"}
		"cash_counter":
			return {"primary": "MAKE $%d" % _scene_int(attached_scene, "target", 0), "detail": "BUILD THE EXACT TOTAL WITH REAL US BILLS"}
		"mathtris":
			return {"primary": "MAKE A TRUE EQUATION", "detail": "FIVE TILES ACROSS OR DOWN • SWIPE NEIGHBORS"}
		"galaxy_unicorn":
			return {"primary": "RAINBOW DEFENSE", "detail": "LEVEL %d • LIVES %d • %d/%d ENEMIES • SCORE %d" % [_scene_int(attached_scene, "level", 1), _scene_int(attached_scene, "lives", 3), _scene_int(attached_scene, "kills", 0), _scene_int(attached_scene, "target_kills", 0), _scene_int(attached_scene, "score", 0)]}
	var game := GameRegistry.get_game(attached_game_id)
	var title := str(game.get("title", "Mission")).to_upper()
	var lesson: Array[String] = TutorialCatalog.lessons(attached_game_id, _scene_int(attached_scene, "level", 1))
	return {"primary": title, "detail": lesson[0] if not lesson.is_empty() else "Complete the enchanted challenge."}


func _scene_int(scene: Node, property: String, fallback: int) -> int:
	if not _has_property(scene, property):
		return fallback
	return int(scene.get(property))


func _has_property(object: Object, property: String) -> bool:
	for definition in object.get_property_list():
		if str(definition.get("name", "")) == property:
			return true
	return false


func _format_cents(cents: int) -> String:
	return "$%d.%02d" % [cents / 100, cents % 100]


func _update_coin_button(coins: int) -> void:
	if is_instance_valid(coin_button):
		coin_button.text = " %d" % coins


func _update_ability_button() -> void:
	if not is_instance_valid(ability_button):
		return
	var definition := CompanionAbilityService.definition()
	ability_button.text = "%s\n%s" % [str(definition.get("name", "Companion")), "READY" if CompanionAbilityService.is_available() else "USED"]
	ability_button.tooltip_text = str(definition.get("description", ""))
	ability_button.disabled = not CompanionAbilityService.is_available() and bool(definition.get("active", false))


func _ability_pressed() -> void:
	var definition := CompanionAbilityService.definition()
	if CompanionAbilityService.companion_id() == "mystic" and CompanionAbilityService.is_available():
		_show_assist(true)
	else:
		_show_notice(str(definition.get("name", "Companion Power")), str(definition.get("description", "This power works automatically.")))


func _show_assist(mystic: bool) -> void:
	if not is_instance_valid(attached_scene):
		return
	if mystic and not _can_apply_mystic():
		_show_notice("Mystic Move", "No safe move is ready yet.")
		return
	if mystic and not CompanionAbilityService.consume_mystic_move():
		return
	match attached_game_id:
		"unicorn_jump":
			var data: Array = attached_scene.get("level_data")
			var index := _scene_int(attached_scene, "current_index", 0)
			if index < data.size():
				var expected := index + int(data[index])
				if mystic:
					attached_scene.call("_choose_node", expected)
				else:
					_highlight_jump_stone(expected)
		"mathtris":
			if attached_scene.has_method("_activate_mystic_ability"):
				attached_scene.call("_activate_mystic_ability")
		"cash_counter":
			var remaining := _scene_int(attached_scene, "target", 0) - _scene_int(attached_scene, "total", 0)
			for bill in [100, 50, 20, 10, 5, 1]:
				if bill <= remaining:
					attached_scene.call("_add_bill", bill)
					break
		"coin_count":
			var remaining := _scene_int(attached_scene, "target", 0) - _scene_int(attached_scene, "total", 0)
			for coin in [25, 10, 5, 1]:
				if coin <= remaining:
					attached_scene.call("_add_coin", coin)
					break
		"galaxy_unicorn":
			if attached_scene.has_method("_mystic_blast"):
				attached_scene.call("_mystic_blast")
		_:
			CompanionAbilityService.arm_assist_hint()
			if attached_scene.has_method("_show_hint"):
				attached_scene.call("_show_hint")
	_update_ability_button()


func _can_apply_mystic() -> bool:
	return attached_game_id in ["unicorn_jump", "mathtris", "cash_counter", "coin_count", "galaxy_unicorn"] or attached_scene.has_method("_show_hint")


func _is_retry_failure() -> bool:
	if not is_instance_valid(attached_scene) or attached_game_id == "unicorn_jump":
		return false
	if _has_property(attached_scene, "action_button"):
		var action = attached_scene.get("action_button")
		if action is Button:
			var copy := str((action as Button).text).to_upper()
			return "RETRY" in copy or "PLAY AGAIN" in copy
	if _has_property(attached_scene, "retry_button"):
		var retry = attached_scene.get("retry_button")
		if retry is Button:
			return "RETRY" in str((retry as Button).text).to_upper()
	return false


func _restart_after_sparkle() -> void:
	if not is_instance_valid(attached_scene):
		return
	match attached_game_id:
		"cash_counter", "coin_count": attached_scene.call("_start_round")
		"mathtris": attached_scene.call("_start_game")
		"rhyme_rally": attached_scene.call("_start_level")
		"galaxy_unicorn", "math_swipe", "sliding_window": attached_scene.call("_start_level", _scene_int(attached_scene, "level", 1))
		_:
			if attached_scene.has_method("_start_level"):
				attached_scene.call("_start_level")
	if _has_property(attached_scene, "message_label"):
		var message = attached_scene.get("message_label")
		if message is Label:
			(message as Label).text = "Second Sparkle restored this level — your retry was free!"
	was_active = true
	_update_ability_button()


func _highlight_jump_stone(index: int) -> void:
	var buttons = attached_scene.get("node_buttons")
	if buttons is Array and index >= 0 and index < buttons.size():
		var button: CanvasItem = buttons[index]
		var tween := button.create_tween()
		tween.set_loops(3)
		tween.tween_property(button, "modulate", Color("fff176"), 0.28)
		tween.tween_property(button, "modulate", Color.WHITE, 0.28)


func _request_leave(home: bool) -> void:
	if not is_instance_valid(attached_scene):
		return
	if _has_property(attached_scene, "active") and bool(attached_scene.get("active")):
		var dialog := ConfirmationDialog.new()
		dialog.title = "Leave this run?"
		dialog.dialog_text = "Your current level will be abandoned."
		dialog.ok_button_text = "LEAVE RUN"
		dialog.cancel_button_text = "KEEP PLAYING"
		attached_scene.add_child(dialog)
		dialog.confirmed.connect(_leave_game.bind(home))
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered(Vector2i(520, 260))
	else:
		_leave_game(home)


func _leave_game(home: bool) -> void:
	AppState.set_shell_destination("home" if home else "category", "" if home else AppState.selected_category)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _show_profile_overlay() -> void:
	if not is_instance_valid(attached_scene) or attached_scene.has_node("InGameProfileOverlay"):
		return
	var overlay := _modal_backdrop("InGameProfileOverlay")
	attached_scene.add_child(overlay)
	var card := _modal_card(overlay, 0.06, 0.94, 0.06, 0.94)
	var scroll := ScrollContainer.new()
	card.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 12)
	scroll.add_child(stack)
	stack.add_child(_modal_title("PLAYER PROFILE"))
	var companion := MetaCatalog.companion(AppState.equipped_companion())
	var preview := RoomItemPreviewScene.new()
	preview.custom_minimum_size = Vector2(160, 140)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.setup({"id": "companion_%s" % AppState.equipped_companion(), "category": "companions", "animate": false, "presentation": "marketplace"})
	stack.add_child(preview)
	var hero := Label.new()
	hero.text = "%s\n%s  •  %d COINS  •  %d RUNS" % [AppState.player_name().to_upper(), str(companion.get("name", "Sparkle")).to_upper(), AppState.coins(), AppState.completed_run_count()]
	hero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero.add_theme_font_size_override("font_size", 20)
	hero.add_theme_color_override("font_color", StorybookUI.INK)
	stack.add_child(hero)
	var ability := CompanionAbilityService.definition()
	var ability_card := Label.new()
	ability_card.text = "✦ %s — %s" % [ability.get("name", "Companion Power"), ability.get("description", "")]
	ability_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_card.add_theme_font_size_override("font_size", 18)
	ability_card.add_theme_color_override("font_color", Color("59375c"))
	stack.add_child(ability_card)
	var rings := HBoxContainer.new()
	rings.alignment = BoxContainer.ALIGNMENT_CENTER
	rings.add_theme_constant_override("separation", 6)
	stack.add_child(rings)
	for category in ["Number", "Word", "Mystery", "Arcade"]:
		var completed := 0
		var level_sum := 0.0
		var games := GameRegistry.games_in_category(category)
		for game in games:
			completed += AppState.progress_for_game(game["id"]).get("completed", []).size()
			level_sum += clampf(float(AppState.current_level(game["id"]) - 1) / 20.0, 0.0, 1.0)
		var ratio := 0.0 if games.is_empty() else level_sum / float(games.size())
		var ring := ProgressRingScene.new()
		ring.setup(ratio, category.to_upper(), "%d RUNS" % completed, Color("58d6e8") if category == "Number" else (Color("f26fa7") if category == "Word" else (Color("9b7bff") if category == "Mystery" else Color("ffd166"))))
		rings.add_child(ring)
	var tutorial_toggle := CheckButton.new()
	tutorial_toggle.text = "GUIDED FIRST THREE LEVELS"
	tutorial_toggle.button_pressed = bool(AppState.setting("tutorials_enabled", true))
	tutorial_toggle.custom_minimum_size.y = 56
	tutorial_toggle.add_theme_font_size_override("font_size", 19)
	tutorial_toggle.toggled.connect(func(value: bool) -> void: AppState.set_setting("tutorials_enabled", value))
	stack.add_child(tutorial_toggle)
	var close := Button.new()
	close.text = "RESUME GAME"
	StorybookUI.apply_game_action(close, 220)
	close.pressed.connect(overlay.queue_free)
	stack.add_child(close)


func _maybe_show_tutorial(force_replay: bool) -> void:
	if attached_game_id.is_empty() or not is_instance_valid(attached_scene) or attached_scene.has_node("GuidedTutorialOverlay"):
		return
	var raw_level := _scene_int(attached_scene, "level", 1)
	var tutorial_level := clampi(raw_level, 1, 3)
	if not force_replay:
		if not bool(AppState.setting("tutorials_enabled", true)) or raw_level > 3 or AppState.tutorial_complete(attached_game_id, tutorial_level):
			return
	var lessons: Array[String] = TutorialCatalog.lessons(attached_game_id, tutorial_level)
	var overlay := _modal_backdrop("GuidedTutorialOverlay")
	overlay.set_meta("lessons", lessons)
	overlay.set_meta("step", 0)
	overlay.set_meta("game_id", attached_game_id)
	overlay.set_meta("tutorial_level", tutorial_level)
	attached_scene.add_child(overlay)
	var card := _modal_card(overlay, 0.07, 0.93, 0.20, 0.80)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	card.add_child(stack)
	var heading := _modal_title("GUIDED LEVEL %d  •  STEP 1 OF 3" % tutorial_level)
	heading.name = "TutorialHeading"
	stack.add_child(heading)
	var sparkle := Label.new()
	sparkle.text = "✦  🦄  ✦"
	sparkle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sparkle.add_theme_font_size_override("font_size", 42)
	stack.add_child(sparkle)
	var lesson := Label.new()
	lesson.name = "TutorialLesson"
	lesson.text = lessons[0]
	lesson.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lesson.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson.custom_minimum_size.y = 150
	lesson.add_theme_font_size_override("font_size", 25)
	lesson.add_theme_color_override("font_color", StorybookUI.INK)
	stack.add_child(lesson)
	var next := Button.new()
	next.name = "TutorialNext"
	next.text = "SHOW ME THE NEXT STEP"
	StorybookUI.apply_game_action(next, 280)
	next.pressed.connect(_advance_tutorial.bind(overlay))
	stack.add_child(next)


func _advance_tutorial(overlay: Control) -> void:
	if not is_instance_valid(overlay):
		return
	var lessons: Array = overlay.get_meta("lessons")
	var step := int(overlay.get_meta("step")) + 1
	if step >= lessons.size():
		AppState.mark_tutorial_complete(str(overlay.get_meta("game_id")), int(overlay.get_meta("tutorial_level")))
		overlay.queue_free()
		return
	overlay.set_meta("step", step)
	var heading := overlay.find_child("TutorialHeading", true, false) as Label
	var lesson := overlay.find_child("TutorialLesson", true, false) as Label
	var next := overlay.find_child("TutorialNext", true, false) as Button
	heading.text = "GUIDED LEVEL %d  •  STEP %d OF %d" % [int(overlay.get_meta("tutorial_level")), step + 1, lessons.size()]
	lesson.text = str(lessons[step])
	next.text = "LET ME PLAY" if step == lessons.size() - 1 else "SHOW ME THE NEXT STEP"


func _show_notice(title: String, copy: String) -> void:
	if not is_instance_valid(attached_scene):
		return
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = copy
	attached_scene.add_child(dialog)
	dialog.popup_centered(Vector2i(520, 240))
	dialog.confirmed.connect(dialog.queue_free)


func _modal_backdrop(node_name: String) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.name = node_name
	overlay.color = Color(0.02, 0.03, 0.10, 0.82)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 1000
	return overlay


func _modal_card(parent: Control, left: float, right: float, top: float, bottom: float) -> PanelContainer:
	var card := PanelContainer.new()
	card.anchor_left = left
	card.anchor_right = right
	card.anchor_top = top
	card.anchor_bottom = bottom
	card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("fff3d6"), StorybookUI.GOLD, 24))
	parent.add_child(card)
	return card


func _modal_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 27)
	label.add_theme_color_override("font_color", Color("9c356d"))
	return label


func _restyle_controls(node: Node) -> void:
	if node is Button:
		var button := node as Button
		if not button.has_meta("standard_game_chrome") and not button.has_meta("currency_art") and not button.has_meta("mathtris_tile"):
			StorybookUI.apply_game_action(button, maxf(96.0, button.custom_minimum_size.x))
			button.custom_minimum_size.y = maxf(56.0, button.custom_minimum_size.y)
			var copy := button.text.to_upper()
			if copy == "ARCADE" or "BACK" in copy or ("GAMES" in copy and ("NUMBER" in copy or "WORD" in copy or "MYSTERY" in copy or "ARCADE" in copy)):
				button.hide()
	elif node is Label:
		var label := node as Label
		var copy := label.text.strip_edges().to_upper()
		if copy.begins_with("★") and not label.has_meta("keep_visible"):
			label.hide()
	for child in node.get_children():
		_restyle_controls(child)


func _polish_game_labels(node: Node) -> void:
	if node is Label and not (node as Label).has_meta("standard_game_chrome"):
		var label := node as Label
		if label.visible and label.get_theme_font_size("font_size") >= 18:
			if not label.has_theme_color_override("font_outline_color"):
				label.add_theme_color_override("font_outline_color", Color("120d32"))
				label.add_theme_constant_override("outline_size", maxi(2, label.get_theme_constant("outline_size")))
	for child in node.get_children():
		_polish_game_labels(child)
