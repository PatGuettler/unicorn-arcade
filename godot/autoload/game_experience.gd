extends Node

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const TutorialCatalog = preload("res://scripts/tutorial_catalog.gd")
const CompanionAssets = preload("res://scripts/meta/companion_asset_catalog.gd")
const ProgressRingScene = preload("res://scripts/ui/progress_ring.gd")
const PENNY_TEXTURE_PATH := "res://assets/games/currency/penny.png"
const MEADOW_BACKGROUND_PATH := "res://assets/meta/environments/magical_meadow_v1.png"

var attached_scene: Node
var attached_controller: ArcadeGameController
var attached_game_id := ""
var objective_primary: Label
var objective_detail: Label
var coin_button: Button
var ability_button: Button
var hint_button: Button
var inactivity_seconds := 0.0
var last_level := -1
var update_accumulator := 0.0
var was_active := false
var outcome_overlay: Control
var sparkle_retry_overlay: Control
var persistence_warning_layer: CanvasLayer
var persistence_warning_banner: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AppState.coins_changed.connect(_update_coin_button)
	AppState.save_failed.connect(_show_persistence_warning)
	AppState.save_recovered.connect(_clear_persistence_warning)
	if AppState.has_unsaved_changes():
		_show_persistence_warning("Latest progress is kept in memory. Saving will retry automatically.")


func _show_persistence_warning(message: String) -> void:
	if not is_instance_valid(persistence_warning_layer):
		persistence_warning_layer = CanvasLayer.new()
		persistence_warning_layer.name = "PersistenceWarningLayer"
		persistence_warning_layer.layer = 120
		add_child(persistence_warning_layer)
		persistence_warning_banner = PanelContainer.new()
		persistence_warning_banner.name = "PersistenceWarningBanner"
		persistence_warning_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		persistence_warning_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		persistence_warning_banner.offset_left = 14
		persistence_warning_banner.offset_right = -14
		persistence_warning_banner.offset_top = 10
		persistence_warning_banner.offset_bottom = 82
		persistence_warning_banner.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("5b2438f2"), Color("ffd166"), 16))
		persistence_warning_layer.add_child(persistence_warning_banner)
		var label := Label.new()
		label.name = "PersistenceWarningText"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color("fff3d6"))
		persistence_warning_banner.add_child(label)
	var warning_text := persistence_warning_banner.get_node_or_null("PersistenceWarningText") as Label
	if is_instance_valid(warning_text):
		warning_text.text = "SAVE PAUSED — %s\nWe'll retry automatically; avoid closing the app until saving recovers." % message


func _clear_persistence_warning() -> void:
	if is_instance_valid(persistence_warning_layer):
		persistence_warning_layer.queue_free()
	persistence_warning_layer = null
	persistence_warning_banner = null


func _input(_event: InputEvent) -> void:
	inactivity_seconds = 0.0


func _process(delta: float) -> void:
	var scene := AdBarService.content_scene()
	if not is_instance_valid(scene):
		scene = get_tree().current_scene
	if scene != attached_scene:
		attached_scene = scene
		attached_controller = null
		attached_game_id = ""
		objective_primary = null
		objective_detail = null
		coin_button = null
		ability_button = null
		hint_button = null
		last_level = -1
		was_active = false
		outcome_overlay = null
		sparkle_retry_overlay = null
		inactivity_seconds = 0.0
		# Keep AdMob banner attached when leaving main.tscn for a game scene.
		AdBarService.sync_for_player(AppState.player_name())
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
	if not is_instance_valid(attached_controller):
		_poll_legacy_run_activity(scene)
	var current_level := int(attached_controller.runtime_snapshot().get("level", 1)) if is_instance_valid(attached_controller) else _scene_int(scene, "level", 1)
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
	if scene != AdBarService.content_scene() or not is_instance_valid(scene):
		return
	attached_game_id = AppState.selected_game_id
	attached_controller = scene as ArcadeGameController
	if is_instance_valid(attached_controller):
		if not attached_controller.runtime_state_changed.is_connected(_on_runtime_state_changed):
			attached_controller.runtime_state_changed.connect(_on_runtime_state_changed)
		if not attached_controller.run_activity_changed.is_connected(_on_run_activity_changed):
			attached_controller.run_activity_changed.connect(_on_run_activity_changed)
	if attached_game_id.is_empty():
		attached_game_id = _fallback_game_id(str(scene.scene_file_path))
	var game := GameRegistry.get_game(attached_game_id)
	if game.is_empty():
		return
	var layout: VBoxContainer = null
	if attached_game_id == "galaxy_unicorn":
		layout = VBoxContainer.new()
		layout.name = "GalaxyStandardGameHeaderOverlay"
		layout.set_anchors_preset(Control.PRESET_TOP_WIDE)
		layout.offset_left = 14
		layout.offset_right = -14
		layout.offset_top = 14
		layout.z_index = 900
		scene.add_child(layout)
	else:
		layout = _find_primary_layout(scene)
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
	_hide_embedded_hint_controls(scene)
	_configure_comet_chrome(scene)
	var header := _build_header(str(game["title"]))
	layout.add_child(header)
	layout.move_child(header, 0)
	var plaque := _build_objective_plaque()
	layout.add_child(plaque)
	layout.move_child(plaque, 1)
	_restyle_controls(scene)
	_polish_game_labels(scene)
	_hide_game_scrollbars(scene)
	last_level = int(attached_controller.runtime_snapshot().get("level", 1)) if is_instance_valid(attached_controller) else _scene_int(scene, "level", 1)
	CompanionAbilityService.begin_level(attached_game_id, last_level)
	was_active = bool(attached_controller.runtime_snapshot().get("active", true)) if is_instance_valid(attached_controller) else true
	_update_runtime_ui()
	_update_ability_button()
	_maybe_show_tutorial.call_deferred(false)


func _on_runtime_state_changed(snapshot: Dictionary) -> void:
	if is_instance_valid(objective_primary):
		objective_primary.text = str(snapshot.get("objective_primary", "YOUR MISSION"))
	if is_instance_valid(objective_detail):
		objective_detail.text = str(snapshot.get("objective_detail", "Complete the enchanted challenge."))
	if is_instance_valid(hint_button):
		hint_button.disabled = not bool(snapshot.get("hint_available", false))


func _on_run_activity_changed(active: bool) -> void:
	_handle_run_activity_transition(active)


func _poll_legacy_run_activity(scene: Node) -> void:
	if not _has_property(scene, "active"):
		return
	_handle_run_activity_transition(bool(scene.get("active")))


func _handle_run_activity_transition(active: bool) -> void:
	if was_active and not active:
		var snapshot := attached_controller.runtime_snapshot() if is_instance_valid(attached_controller) else {}
		var retry_available := bool(snapshot.get("retry_available", false)) if is_instance_valid(attached_controller) else _is_retry_failure()
		var outcome_message := str(snapshot.get("outcome_message", "")) if is_instance_valid(attached_controller) else _outcome_message()
		if retry_available and CompanionAbilityService.consume_checkpoint_retry():
			_show_sparkle_retry_notice.call_deferred(outcome_message)
		else:
			_show_game_outcome.call_deferred()
	was_active = active


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
	var home := _header_button("", "Home")
	home.name = "GameHeaderHome"
	StorybookUI.apply_home_button(home)
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


func _companion_thumbnail(companion_id: String, minimum_size: Vector2) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.name = "EquippedCompanionMascot"
	portrait.texture = load(CompanionAssets.thumbnail_path(companion_id)) as Texture2D
	portrait.custom_minimum_size = minimum_size
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return portrait


func _build_objective_plaque() -> PanelContainer:
	var plaque := PanelContainer.new()
	plaque.name = "GameObjectivePlaque"
	plaque.custom_minimum_size.y = 92
	plaque.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("fff3d6"), Color("e1ae4f"), 18))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	plaque.add_child(row)
	var mascot := _companion_thumbnail(AppState.equipped_companion(), Vector2(96, 74))
	mascot.name = "EquippedCompanionMascot"
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
	hint_button = _header_button("HINT", "Show one ordinary hint (free on level 1; 5 coins later)")
	hint_button.name = "OrdinaryHint"
	hint_button.pressed.connect(_ordinary_hint_pressed)
	row.add_child(hint_button)
	var help := _header_button("?", "Replay the tutorial")
	help.name = "ObjectiveTutorialHelp"
	help.pressed.connect(_maybe_show_tutorial.bind(true))
	row.add_child(help)
	return plaque


func _update_runtime_ui() -> void:
	if not is_instance_valid(attached_scene) or not is_instance_valid(objective_primary):
		return
	if is_instance_valid(attached_controller):
		_on_runtime_state_changed(attached_controller.runtime_snapshot())
		_update_coin_button(AppState.coins())
		return
	var objective := _objective_for_scene()
	objective_primary.text = str(objective.get("primary", "YOUR MISSION"))
	objective_detail.text = str(objective.get("detail", "Follow the enchanted objective."))
	_update_coin_button(AppState.coins())


func _objective_for_scene() -> Dictionary:
	if attached_game_id == "comet_math_rescue":
		var problem: Dictionary = attached_scene.get("current_problem") if _has_property(attached_scene, "current_problem") else {}
		var operation := str(problem.get("operation", "+"))
		var visible_operation := "×" if operation == "x" else ("÷" if operation == "/" else operation)
		return {"primary": "%d %s %d = ?" % [int(problem.get("left", 0)), visible_operation, int(problem.get("right", 0))], "detail": "SHIELDS %d - RESCUE %d/%d - SCORE %d" % [_scene_int(attached_scene, "lives", 3), _scene_int(attached_scene, "rescues", 0), _scene_int(attached_scene, "target_rescues", 0), _scene_int(attached_scene, "score", 0)]}
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
	if is_instance_valid(attached_controller) and CompanionAbilityService.is_available():
		if attached_controller.request_companion_action(CompanionAbilityService.companion_id()):
			CompanionAbilityService.consume_active_power()
			_update_ability_button()
			return
		if attached_game_id == "mathtris":
			_show_notice("Power charging", "Clear 3 true equations to charge your unicorn power.")
			return
	if CompanionAbilityService.companion_id() == "mystic" and CompanionAbilityService.is_available():
		_show_assist(true)
	else:
		_show_notice(str(definition.get("name", "Companion Power")), str(definition.get("description", "This power works automatically.")))


func _ordinary_hint_pressed() -> void:
	if not is_instance_valid(attached_controller):
		_show_notice("Hint", "Keep trying — look for the next safe choice.")
		return
	if not attached_controller.can_show_hint():
		_show_notice("Hint", "A hint is not available right now.")
		return
	var level := int(attached_controller.runtime_snapshot().get("level", 1))
	if not AppState.spend_hint(level):
		_show_notice("Hint", "You need 5 coins for another hint.")
		return
	attached_controller.request_hint()


func _hide_embedded_hint_controls(node: Node) -> void:
	for child in node.get_children():
		if child is Button and not child.has_meta("standard_game_chrome"):
			var label := str((child as Button).text).to_upper()
			if label.contains("HINT"):
				child.hide()
		_hide_embedded_hint_controls(child)


func _configure_comet_chrome(scene: Node) -> void:
	if attached_game_id != "comet_math_rescue":
		return
	for node_name in ["CometEquationBanner", "CometRescueMeter"]:
		var duplicate_label := scene.get_node_or_null(node_name)
		if duplicate_label is CanvasItem:
			(duplicate_label as CanvasItem).hide()


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
		"comet_math_rescue":
			if attached_scene.has_method("_mystic_rescue"):
				attached_scene.call("_mystic_rescue")
		_:
			CompanionAbilityService.arm_assist_hint()
			if attached_scene.has_method("_show_hint"):
				attached_scene.call("_show_hint")
	_update_ability_button()


func _can_apply_mystic() -> bool:
	return attached_game_id in ["unicorn_jump", "mathtris", "cash_counter", "coin_count", "galaxy_unicorn", "comet_math_rescue"] or attached_scene.has_method("_show_hint")


func _is_retry_failure() -> bool:
	if not is_instance_valid(attached_scene):
		return false
	if attached_scene.has_method("can_retry_failure"):
		return bool(attached_scene.call("can_retry_failure"))
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


func _outcome_action_button() -> Button:
	if not is_instance_valid(attached_scene):
		return null
	for property in ["action_button", "retry_button"]:
		if _has_property(attached_scene, property):
			var candidate = attached_scene.get(property)
			if candidate is Button and is_instance_valid(candidate):
				return candidate
	for button in attached_scene.find_children("*", "Button", true, false):
		var copy := str((button as Button).text).to_upper()
		if "RETRY" in copy or "NEXT" in copy or "PLAY AGAIN" in copy:
			return button as Button
	return null


func _outcome_message() -> String:
	for property in ["message_label", "status_label"]:
		if _has_property(attached_scene, property):
			var label = attached_scene.get(property)
			if label is Label and not str((label as Label).text).is_empty():
				return (label as Label).text
	return "Your next adventure is ready."


func _show_game_outcome() -> void:
	if not is_instance_valid(attached_scene) or is_instance_valid(outcome_overlay) or is_instance_valid(sparkle_retry_overlay) or _scene_has_dialog("GameOutcomeOverlay") or _scene_has_dialog("SecondSparkleRetryOverlay"):
		return
	var legacy := _outcome_action_button()
	var retry := _is_retry_failure()
	if is_instance_valid(legacy):
		legacy.hide()
	var overlay := _modal_backdrop("GameOutcomeOverlay")
	overlay.z_index = 1500
	attached_scene.add_child(overlay)
	outcome_overlay = overlay
	var card := _modal_card(overlay, 0.08, 0.92, 0.23, 0.77)
	card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("3b1638") if retry else Color("123c4b"), Color("ff6f9b") if retry else Color("62e6b5"), 28))
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 16)
	card.add_child(stack)
	var icon := Label.new()
	icon.text = "💔" if retry else "✨🦄✨"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 46)
	stack.add_child(icon)
	var title := _modal_title("TRY AGAIN" if retry else "LEVEL COMPLETE!")
	title.add_theme_color_override("font_color", Color("ffb2cf") if retry else Color("bffff1"))
	title.add_theme_font_size_override("font_size", 34)
	stack.add_child(title)
	var message := Label.new()
	message.name = "GameOutcomeMessage"
	message.text = _outcome_message()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 21)
	message.add_theme_color_override("font_color", Color("fff3d6"))
	stack.add_child(message)
	var primary := Button.new()
	primary.name = "GameOutcomePrimaryAction"
	primary.text = "TRY AGAIN" if retry else "KEEP GOING"
	StorybookUI.apply_game_action(primary, 260)
	primary.pressed.connect(func() -> void:
		if is_instance_valid(legacy):
			legacy.pressed.emit()
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	stack.add_child(primary)
	var category := Button.new()
	category.name = "GameOutcomeReturnToCategory"
	category.text = "RETURN TO CATEGORY"
	StorybookUI.apply_game_action(category, 260)
	category.pressed.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
		_leave_game(false)
	)
	stack.add_child(category)
	overlay.tree_exited.connect(func() -> void:
		if outcome_overlay == overlay:
			outcome_overlay = null
	)


func _show_sparkle_retry_notice(failure_reason: String) -> void:
	if not is_instance_valid(attached_scene) or is_instance_valid(sparkle_retry_overlay) or is_instance_valid(outcome_overlay) or _scene_has_dialog("SecondSparkleRetryOverlay"):
		return
	var legacy := _outcome_action_button()
	if is_instance_valid(legacy):
		legacy.hide()
	var overlay := _modal_backdrop("SecondSparkleRetryOverlay")
	overlay.z_index = 1550
	attached_scene.add_child(overlay)
	sparkle_retry_overlay = overlay
	var card := _modal_card(overlay, 0.08, 0.92, 0.22, 0.78)
	card.name = "SecondSparkleRetryCard"
	card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("32194a"), Color("f4d37f"), 28))
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 14)
	card.add_child(stack)
	var icon := Label.new()
	icon.text = "✨  🦄  ✨"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 44)
	stack.add_child(icon)
	var title := _modal_title("SECOND SPARKLE!")
	title.add_theme_color_override("font_color", Color("ffe7a6"))
	title.add_theme_font_size_override("font_size", 32)
	stack.add_child(title)
	var reason := Label.new()
	reason.name = "SecondSparkleFailureReason"
	reason.text = failure_reason if not failure_reason.strip_edges().is_empty() else "This try came to an end."
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason.add_theme_font_size_override("font_size", 20)
	reason.add_theme_color_override("font_color", Color("ffd1e5"))
	stack.add_child(reason)
	var explanation := Label.new()
	explanation.name = "SecondSparkleExplanation"
	explanation.text = "Sparkle saved one FREE RETRY for you. Tap CONTINUE to restart this same level. This one-time retry is now used."
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 21)
	explanation.add_theme_color_override("font_color", Color("fff3d6"))
	stack.add_child(explanation)
	var continue_button := Button.new()
	continue_button.name = "SecondSparkleContinue"
	continue_button.text = "CONTINUE"
	StorybookUI.apply_game_action(continue_button, 260)
	continue_button.pressed.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
		_restart_after_sparkle()
	)
	stack.add_child(continue_button)
	overlay.tree_exited.connect(func() -> void:
		if sparkle_retry_overlay == overlay:
			sparkle_retry_overlay = null
	)


func _restart_after_sparkle() -> void:
	if not is_instance_valid(attached_scene):
		return
	if attached_scene.has_method("retry_failure"):
		attached_scene.call("retry_failure")
	else:
		match attached_game_id:
			"cash_counter", "coin_count": attached_scene.call("_start_round")
			"mathtris": attached_scene.call("_start_game")
			"rhyme_rally": attached_scene.call("_start_level")
			"galaxy_unicorn", "comet_math_rescue", "math_swipe", "sliding_window": attached_scene.call("_start_level", _scene_int(attached_scene, "level", 1))
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
		_show_leave_run_modal(home)
	else:
		_leave_game(home)


func _show_leave_run_modal(home: bool) -> void:
	if not is_instance_valid(attached_scene) or _scene_has_dialog("LeaveRunOverlay"):
		return
	var overlay := _modal_backdrop("LeaveRunOverlay")
	attached_scene.add_child(overlay)
	var card := _modal_card(overlay, 0.10, 0.90, 0.30, 0.70)
	card.name = "LeaveRunCard"
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 16)
	card.add_child(stack)
	var badge := Label.new()
	badge.text = "STORYBOOK PAUSE"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(badge, Color("c45186"), 18, false)
	stack.add_child(badge)
	stack.add_child(_modal_title("LEAVE THIS RUN?"))
	var copy := Label.new()
	copy.name = "LeaveRunCopy"
	copy.text = "Your current level will be abandoned. You can begin a fresh run anytime."
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.custom_minimum_size.y = 86
	StorybookUI.apply_story_label(copy, StorybookUI.INK, 23, false)
	stack.add_child(copy)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	stack.add_child(actions)
	var leave := Button.new()
	leave.name = "LeaveRunConfirm"
	leave.text = "LEAVE RUN"
	StorybookUI.apply_game_action(leave, 180)
	leave.pressed.connect(_leave_game.bind(home))
	actions.add_child(leave)
	var keep_playing := Button.new()
	keep_playing.name = "LeaveRunCancel"
	keep_playing.text = "KEEP PLAYING"
	StorybookUI.apply_game_action(keep_playing, 190)
	keep_playing.pressed.connect(overlay.queue_free)
	actions.add_child(keep_playing)


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
	var preview := _companion_thumbnail(AppState.equipped_companion(), Vector2(160, 140))
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
	tutorial_toggle.text = "GUIDED FIRST LEVEL"
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
	if attached_game_id.is_empty() or not is_instance_valid(attached_scene) or _scene_has_dialog("GuidedTutorialOverlay"):
		return
	var raw_level := _scene_int(attached_scene, "level", 1)
	var tutorial_level := clampi(raw_level, 1, 3)
	if not force_replay:
		if not bool(AppState.setting("tutorials_enabled", true)) or raw_level != 1 or AppState.tutorial_complete(attached_game_id, tutorial_level):
			return
	var lessons: Array[String] = TutorialCatalog.lessons(attached_game_id, tutorial_level)
	var dialog := _create_game_dialog("GuidedTutorialOverlay", 0.07, 0.93, 0.20, 0.80)
	var overlay := dialog["owner"] as Control
	var card := dialog["card"] as PanelContainer
	if attached_game_id == "galaxy_unicorn" and attached_scene.has_method("set_gameplay_paused"):
		var tutorial_scene := attached_scene
		tutorial_scene.call("set_gameplay_paused", true)
		overlay.tree_exited.connect(func() -> void:
			if is_instance_valid(tutorial_scene) and tutorial_scene.has_method("set_gameplay_paused"):
				tutorial_scene.call("set_gameplay_paused", false)
		)
	overlay.set_meta("lessons", lessons)
	overlay.set_meta("step", 0)
	overlay.set_meta("game_id", attached_game_id)
	overlay.set_meta("tutorial_level", tutorial_level)
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
	if not is_instance_valid(attached_scene) or _scene_has_dialog("CompanionAbilityNotice"):
		return
	var dialog := _create_game_dialog("CompanionAbilityNotice", 0.10, 0.90, 0.30, 0.70)
	var overlay := dialog["owner"] as Control
	var card := dialog["card"] as PanelContainer
	card.name = "AbilityNoticeCard"
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 20)
	card.add_child(stack)
	var badge := Label.new()
	badge.text = "UNICORN MAGIC"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(badge, Color("c45186"), 18, false)
	stack.add_child(badge)
	stack.add_child(_modal_title(title.to_upper()))
	var message := Label.new()
	message.name = "AbilityNoticeCopy"
	message.text = copy
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message.custom_minimum_size.y = 100
	StorybookUI.apply_story_label(message, StorybookUI.INK, 25, false)
	stack.add_child(message)
	var close := Button.new()
	close.name = "AbilityNoticeClose"
	close.text = "GOT IT!"
	StorybookUI.apply_game_action(close, 220)
	close.pressed.connect(overlay.queue_free)
	stack.add_child(close)


func _scene_has_dialog(node_name: String) -> bool:
	return is_instance_valid(attached_scene) and attached_scene.find_child(node_name, true, false) != null


func _create_game_dialog(node_name: String, left: float, right: float, top: float, bottom: float) -> Dictionary:
	if attached_scene.has_method("_insert_non_obstructing_dialog"):
		var owner := MarginContainer.new()
		owner.name = node_name
		owner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner.add_theme_constant_override("margin_left", 4)
		owner.add_theme_constant_override("margin_right", 4)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("fff3d6"), StorybookUI.GOLD, 24))
		owner.add_child(card)
		attached_scene.call("_insert_non_obstructing_dialog", owner)
		return {"owner": owner, "card": card}
	var overlay := _modal_backdrop(node_name)
	attached_scene.add_child(overlay)
	return {"owner": overlay, "card": _modal_card(overlay, left, right, top, bottom)}


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
		if not button.has_meta("standard_game_chrome") and not button.has_meta("currency_art") and not button.has_meta("mathtris_tile") and not button.has_meta("sliding_window_node"):
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


func _hide_game_scrollbars(node: Node) -> void:
	if node is ScrollContainer:
		var scroll := node as ScrollContainer
		if scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		if scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	for child in node.get_children():
		_hide_game_scrollbars(child)
