extends Node

const MAIN_SCENE = preload("res://scenes/main.tscn")
const ArcadePictogramScene = preload("res://scripts/ui/arcade_pictogram.gd")
const ProfileView = preload("res://scripts/ui/profile_view.gd")

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveService.begin_test_session()
	var profile := SaveService.create_profile("Profile Integration")
	AppState.data = profile
	AppState.shell_view = "profile"
	var shell := MAIN_SCENE.instantiate()
	var profile_build_signals: Array[bool] = []
	var page_build_signals: Array[bool] = []
	shell.profile_build_complete.connect(func() -> void: profile_build_signals.append(true))
	shell.page_build_complete.connect(func() -> void: page_build_signals.append(true))
	# Begin on a narrower filter to ensure the profile reserves its maximum grid
	# height before a later in-place switch back to All games.
	shell.profile_category_filter = "Word"
	add_child(shell)
	await shell.page_build_complete
	for _frame in 30:
		var candidate := shell.find_child("ProfileGameGrid", true, false)
		if is_instance_valid(candidate) and candidate.get_child_count() == GameRegistry.games_in_category("Word").size() and shell.find_child("ProfileLoading", true, false) == null:
			break
		await get_tree().process_frame
	var grid := shell.find_child("ProfileGameGrid", true, false)
	var settings := shell.find_child("ProfileSettings", true, false)
	var meadow := shell.find_child("MeadowCompanionStage3D", true, false)
	var alley := shell.find_child("ProfileAlleyButton", true, false) as Button
	var content := shell.find_child("ProfileContent", true, false) as VBoxContainer
	var scroll := content.get_parent() as ScrollContainer if is_instance_valid(content) else null
	var chips := shell.find_child("ProfileCategoryChips", true, false) as HFlowContainer
	var reset := settings.find_child("ProfileResetTutorialsButton", true, false) as Button if is_instance_valid(settings) else null
	var logout := shell.find_child("ProfileLogoutButton", true, false) as Button
	var stable_content_height := content.custom_minimum_size.y if is_instance_valid(content) else 0.0
	var stable_grid_height: float = grid.custom_minimum_size.y if is_instance_valid(grid) else 0.0
	var page_id: int = shell.page.get_instance_id() if is_instance_valid(shell.page) else 0
	var content_id := content.get_instance_id() if is_instance_valid(content) else 0
	var grid_id := grid.get_instance_id() if is_instance_valid(grid) else 0
	var scroll_id := scroll.get_instance_id() if is_instance_valid(scroll) else 0
	await get_tree().process_frame
	var no_loading_growth := shell.find_child("ProfileLoading", true, false) == null and is_equal_approx(content.custom_minimum_size.y, stable_content_height) and is_equal_approx(grid.custom_minimum_size.y, stable_grid_height)
	var preserved_scroll := mini(120, int(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page)) if is_instance_valid(scroll) else 0
	if is_instance_valid(scroll):
		scroll.scroll_vertical = preserved_scroll
	shell.call("_apply_profile_category_filter", "All")
	await get_tree().process_frame
	var filtered_first_tile := grid.get_child(0) as Control if is_instance_valid(grid) and grid.get_child_count() > 0 else null
	var pictogram := ArcadePictogramScene.new()
	var initial_style := pictogram.call("_style_for", 58.0) as StyleBoxFlat
	var initial_style_rebuilds: int = pictogram.style_rebuild_count
	var unchanged_style := pictogram.call("_style_for", 58.0) as StyleBoxFlat
	var unchanged_style_rebuilds: int = pictogram.style_rebuild_count
	pictogram.accent = Color("f26fa7")
	var recolored_style := pictogram.call("_style_for", 58.0) as StyleBoxFlat
	var recolored_style_rebuilds: int = pictogram.style_rebuild_count
	var resized_style := pictogram.call("_style_for", 72.0) as StyleBoxFlat
	var resized_style_rebuilds: int = pictogram.style_rebuild_count
	var pictogram_style_cache_ok := initial_style != null and initial_style == unchanged_style and unchanged_style_rebuilds == initial_style_rebuilds and recolored_style == initial_style and recolored_style_rebuilds == initial_style_rebuilds + 1 and resized_style == initial_style and resized_style_rebuilds == initial_style_rebuilds + 2
	pictogram.free()
	initial_style = null
	unchanged_style = null
	recolored_style = null
	resized_style = null
	var chips_pass := is_instance_valid(chips) and chips.get_children().all(func(child: Node) -> bool: return child is Button and (child as Button).mouse_filter == Control.MOUSE_FILTER_PASS)
	var settings_controls_pass := is_instance_valid(settings) and settings.find_children("*", "BaseButton", true, false).all(func(child: Node) -> bool: return (child as Control).mouse_filter == Control.MOUSE_FILTER_PASS)
	var filter_kept_identity: bool = is_instance_valid(shell.page) and shell.page.get_instance_id() == page_id and is_instance_valid(content) and content.get_instance_id() == content_id and is_instance_valid(grid) and grid.get_instance_id() == grid_id and is_instance_valid(scroll) and scroll.get_instance_id() == scroll_id and scroll.scroll_vertical == preserved_scroll and grid.get_child_count() == GameRegistry.all_games().size()
	var stale_build_frame := Engine.get_process_frames()
	var stale_build_signal_count := 0
	var stale_view := ProfileView.new()
	stale_view.configure("All", func() -> bool: return Engine.get_process_frames() == stale_build_frame, Callable(), Callable(), self)
	stale_view.build_complete.connect(func() -> void: stale_build_signal_count += 1)
	add_child(stale_view)
	await stale_view.build()
	var stale_build_cancelled := not stale_view.visible and stale_build_signal_count == 0 and is_instance_valid(stale_view.content)
	stale_view.queue_free()
	var issues: Array[String] = []
	if not is_instance_valid(grid) or grid.get_child_count() != GameRegistry.all_games().size(): issues.append("All filter updates the existing grid")
	if not is_instance_valid(settings) or meadow != null: issues.append("profile sections exclude the meadow")
	if not is_instance_valid(alley) or not alley.pressed.is_connected(Callable(shell, "_open_unicorn_alley")): issues.append("ProfileAlleyButton route")
	if not is_instance_valid(scroll) or scroll.follow_focus or scroll.scroll_deadzone != 8: issues.append("profile scroll settings")
	if not scroll is ProfileView or not is_instance_valid(scroll.content) or scroll.content != content or shell.profile_category_filter != "All" or not shell.has_method("_apply_profile_category_filter"): issues.append("ProfileView owns profile content and shell filter stays compatible")
	if not scroll.visible or profile_build_signals.size() != 1 or page_build_signals.size() != 1: issues.append("current ProfileView reveals atomically and forwards both shell build signals exactly once")
	if not stale_build_cancelled: issues.append("stale ProfileView build stays hidden and does not emit completion")
	if not no_loading_growth or stable_content_height <= 0.0 or stable_grid_height <= 0.0: issues.append("hidden atomic profile height")
	if not chips_pass or not settings_controls_pass: issues.append("profile drag-pass controls")
	if not is_instance_valid(filtered_first_tile) or filtered_first_tile.mouse_filter != Control.MOUSE_FILTER_PASS: issues.append("profile game tile pass filter")
	if not is_instance_valid(reset) or reset.mouse_filter != Control.MOUSE_FILTER_PASS or not is_instance_valid(logout) or logout.mouse_filter != Control.MOUSE_FILTER_PASS or alley.mouse_filter != Control.MOUSE_FILTER_PASS: issues.append("profile action pass filters")
	if not pictogram_style_cache_ok: issues.append("ArcadePictogram style cache")
	if not filter_kept_identity: issues.append("in-place filter identity and scroll retention")
	if not issues.is_empty():
		push_error("Profile-only integration assertions failed: %s" % "; ".join(issues))
		get_tree().quit(1)
		return
	shell.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	SaveService.end_test_session()
	print("GODOT_RUNTIME_PROFILE_INTEGRATION_OK")
	get_tree().quit(0)
