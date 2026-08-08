extends Node

const MAIN_SCENE = preload("res://scenes/main.tscn")

var failures: Array[String] = []
var check_count := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var pre_test_data := AppState.data.duplicate(true)
	var original_game := AppState.selected_game_id
	var original_category := AppState.selected_category
	var test_session_started := SaveService.begin_test_session()
	var test_profile := SaveService.create_profile("Main Shell Integration")
	if not test_session_started or test_profile.is_empty() or not SaveService.has_active_profile():
		push_error("main shell integration could not create its isolated active save profile")
		SaveService.end_test_session()
		get_tree().quit(1)
		return
	AppState.data = test_profile
	AppState.data["owned_companions"] = ["sparkle", "rainbow", "star", "cloud", "dream", "mystic"]
	AppState.data["player"]["equipped_companion"] = "mystic"
	AppState.shell_view = "home"
	var shell := MAIN_SCENE.instantiate()
	add_child(shell)
	await shell.page_build_complete
	await get_tree().process_frame
	_check(shell.get_child_count() >= 2, "navigation shell builds its full-screen page")
	_check(_ui_is_accessible(shell), "navigation shell meets readable text, contrast, and touch-target minimums")
	var meadow_stage := shell.find_child("MeadowCompanionStage3D", true, false)
	var meadow_stage_id := meadow_stage.get_instance_id() if is_instance_valid(meadow_stage) else 0
	var shared_viewports := []
	var shared_cameras := []
	var shared_lights := []
	var travel_roots := []
	var live_models := []
	var animators := []
	if is_instance_valid(meadow_stage):
		shared_viewports = meadow_stage.find_children("*", "SubViewport", true, false)
		shared_cameras = meadow_stage.find_children("*", "Camera3D", true, false)
		shared_lights = meadow_stage.find_children("*", "Light3D", true, false)
		travel_roots = meadow_stage.find_children("MeadowTravelRoot_*", "Node3D", true, false)
		live_models = meadow_stage.find_children("LiveUnicornModel_*", "Node3D", true, false)
		animators = meadow_stage.find_children("*", "UnicornIdleAnimator", true, false)
	var meadow_ids: Dictionary = {}
	var hero_root: Node3D = null
	for root in travel_roots:
		meadow_ids[str(root.get_meta("source_model_id", ""))] = true
		if bool(root.get_meta("hero", false)):
			hero_root = root
	_check(is_instance_valid(meadow_stage) and shared_viewports.size() == 1 and shared_cameras.size() == 1 and shared_lights.size() >= 2, "home meadow uses one shared SubViewport with one camera and shared lights")
	_check(travel_roots.size() == 6 and live_models.size() == 6 and animators.size() == 6 and meadow_ids.size() == 6, "home meadow keeps six distinct live GLBs with travel roots and Walk animators")
	var mid_count := 0
	var rear_count := 0
	var background_z: Array[float] = []
	for root in travel_roots:
		if str(root.get_meta("formation_row", "")) == "mid": mid_count += 1
		if str(root.get_meta("formation_row", "")) == "rear": rear_count += 1
		if not bool(root.get_meta("hero", false)): background_z.append(root.position.z)
	background_z.sort()
	var lateral_safe := background_z.size() == 5
	for index in range(1, background_z.size()): lateral_safe = lateral_safe and background_z[index] - background_z[index - 1] >= 2.4
	_check(is_instance_valid(hero_root) and is_equal_approx(hero_root.position.x, -5.8) and is_zero_approx(hero_root.position.y) and is_equal_approx(hero_root.position.z, 0.95) and is_equal_approx(hero_root.get_child(0).scale.x, 4.256) and mid_count == 2 and rear_count == 3 and lateral_safe, "equipped hero occupies the lower, enlarged camera-front placement while the two-mid/three-rear meadow formation stays separated")
	var centered_slot := shell.find_child("TrueCenterHeaderSlot", true, false) as Control
	var home_sign := shell.find_child("HomeTitleSign", true, false) as TextureRect
	var alley_sign_button := shell.find_child("UnicornAlleyStreetSignButton", true, false) as Button
	var welcome_text := shell.find_child("HomeWelcomeText", true, false) as Label
	var companion_summary := shell.find_child("HomeCompanionSummary", true, false) as Label
	var coin_balance := shell.find_child("CoinBalanceLabel", true, false) as Label
	var expected_center: float = shell.global_position.x + shell.size.x * 0.5
	var actual_center: float = centered_slot.global_position.x + centered_slot.size.x * 0.5 if is_instance_valid(centered_slot) else -1.0
	_check(is_instance_valid(centered_slot) and absf(actual_center - expected_center) <= 1.0, "navigation headers center titles on the physical screen independently of side controls")
	_check(is_instance_valid(home_sign) and home_sign.texture.resource_path.ends_with("title_sign_option3_compact_v1.png"), "home meadow uses the approved illustrated Unicorn Arcade sign")
	_check(is_instance_valid(alley_sign_button) and alley_sign_button.has_node("StreetSignArt") and alley_sign_button.text == "UNICORN ALLEY" and alley_sign_button.tooltip_text.is_empty(), "home uses an accessible illustrated Unicorn Alley street-sign action without a stray mobile tooltip")
	_check(is_instance_valid(welcome_text) and welcome_text.get_theme_font_size("font_size") >= 22 and welcome_text.get_theme_color("font_color") == StorybookUI.INK, "home welcome text is larger and dark enough to read against the meadow sky")
	_check(is_instance_valid(companion_summary) and companion_summary.get_theme_font_size("font_size") >= 21 and companion_summary.get_theme_color("font_color").get_luminance() < 0.30, "home companion summary is larger and uses high-contrast dark teal text")
	_check(is_instance_valid(coin_balance) and coin_balance.get_theme_font_size("font_size") >= 24 and coin_balance.get_theme_constant("outline_size") >= 3, "top star balance uses a larger outlined symbol and number")
	var profile_button := shell.find_child("ProfileButton", true, false) as Button
	var profile_button_found := is_instance_valid(profile_button)
	if profile_button_found:
		profile_button.emit_signal("pressed")
	await shell.profile_build_complete
	await get_tree().process_frame
	var profile_content := shell.find_child("ProfileContent", true, false)
	var profile_grid := shell.find_child("ProfileGameGrid", true, false)
	_check(profile_button_found and is_instance_valid(profile_content) and is_instance_valid(profile_grid) and profile_grid.get_child_count() == GameRegistry.all_games().size(), "profile button opens responsively and finishes its complete game history grid")
	_check(shell.find_child("ProfileLoading", true, false) == null, "profile loading state clears after incremental construction")
	_check(shell.find_child("MeadowCompanionStage3D", true, false) == null and shell.find_child("MeadowCompanionDisplay", true, false) == null, "profile retires the Home meadow renderer and display")
	shell.call("_show_dashboard")
	await shell.page_build_complete
	await get_tree().process_frame
	_check(shell.find_children("CategoryIcon", "ArcadePictogram", true, false).size() == 4, "all four game-category cards restore polished pictogram icons")
	_check(_ui_is_accessible(shell), "icon category dashboard meets readable text, contrast, and touch-target minimums")
	shell.call("_show_category", "Word")
	await shell.page_build_complete
	await get_tree().process_frame
	var word_icons := shell.find_children("GameIcon", "ArcadePictogram", true, false)
	var word_icon_ids: Dictionary = {}
	for word_icon in word_icons:
		word_icon_ids[word_icon.icon_id] = true
	_check(word_icons.size() == 10 and word_icon_ids.size() == 10, "every Word game card has its own distinct pictogram")
	_check(_ui_is_accessible(shell), "icon game grid meets readable text, contrast, and touch-target minimums")
	shell.call("_show_home")
	await shell.page_build_complete
	await get_tree().process_frame
	var returned_meadow := shell.find_child("MeadowCompanionStage3D", true, false) as MeadowCompanionStage3D
	_check(is_instance_valid(returned_meadow) and returned_meadow.get_instance_id() != meadow_stage_id and returned_meadow.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS and shell.find_child("MeadowCompanionDisplay", true, false) != null and returned_meadow.find_children("LiveUnicornModel_*", "Node3D", true, false).size() == 6 and returned_meadow.find_children("*", "UnicornIdleAnimator", true, false).size() == 6 and returned_meadow.find_children("*", "SubViewport", true, false).size() == 1, "returning home builds a fresh active six-unicorn renderer and display")
	await _release_shell(shell)
	AppState.data["player"]["name"] = ""
	var login_shell := MAIN_SCENE.instantiate()
	add_child(login_shell)
	await login_shell.page_build_complete
	await get_tree().process_frame
	var login_prompt := login_shell.find_child("PlayerNamePrompt", true, false) as Label
	var login_input := login_shell.find_child("PlayerNameInput", true, false) as LineEdit
	_check(is_instance_valid(login_prompt) and is_instance_valid(login_input) and not login_input.has_focus(), "first launch clearly asks for a name without opening the Android keyboard")
	_check(is_instance_valid(login_prompt) and is_instance_valid(login_input) and login_prompt.get_index() < login_input.get_index(), "the player-name instruction remains directly above its text field")
	await _release_shell(login_shell)
	AppState.data = pre_test_data
	AppState.selected_game_id = original_game
	AppState.selected_category = original_category
	SaveService.end_test_session()
	if failures.is_empty():
		print("GODOT_RUNTIME_MAIN_SHELL_INTEGRATION_OK: %d checks passed" % check_count)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _release_shell(shell: Node) -> void:
	if not is_instance_valid(shell):
		return
	var ready: Variant = shell.call("prepare_for_scene_change")
	if ready is Signal:
		await ready
	shell.queue_free()
	for _frame in 3:
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	check_count += 1
	if not condition:
		failures.append(message)


func _ui_is_accessible(root: Node) -> bool:
	var issues: Array[String] = []
	_collect_ui_issues(root, issues)
	if not issues.is_empty():
		push_warning("UI accessibility issues: %s" % "; ".join(issues.slice(0, 8)))
	return issues.is_empty()


func _collect_ui_issues(node: Node, issues: Array[String]) -> void:
	if node is Control and (node as Control).is_visible_in_tree():
		var control := node as Control
		if control is Label and not (control as Label).text.strip_edges().is_empty():
			if control.get_theme_font_size("font_size") < 19:
				issues.append("small label %s" % control.name)
			if control.get_theme_constant("outline_size") < 2:
				issues.append("low-contrast label %s" % control.name)
		if control is BaseButton:
			if control.custom_minimum_size.y < 56.0:
				issues.append("short touch target %s" % control.name)
			if control.get_theme_font_size("font_size") < 18:
				issues.append("small button text %s" % control.name)
		if control is LineEdit or control is TextEdit:
			if control.custom_minimum_size.y < 56.0 or control.get_theme_font_size("font_size") < 19:
				issues.append("small text input %s" % control.name)
	for child in node.get_children():
		_collect_ui_issues(child, issues)
