extends Node

const CONTROL_ROOT_SCENES := [
	"res://scenes/main.tscn",
	"res://scenes/startup.tscn",
	"res://scenes/games/cash_counter.tscn",
	"res://scenes/games/coin_count.tscn",
	"res://scenes/games/comet_math_rescue.tscn",
	"res://scenes/games/galaxy_unicorn.tscn",
	"res://scenes/games/mathtris.tscn",
	"res://scenes/games/math_swipe.tscn",
	"res://scenes/games/rhyme_rally.tscn",
	"res://scenes/games/sliding_window.tscn",
	"res://scenes/games/unicorn_jump.tscn",
	"res://scenes/games/word_game.tscn",
	"res://scenes/meta/marketplace.tscn",
	"res://scenes/meta/room_editor.tscn",
	"res://scenes/meta/unicorn_alley.tscn",
]

var failures: Array[String] = []
var checks := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _run() -> void:
	# The runner must stay outside the app wrapper so it can verify a real scene
	# hosted by AppContentViewport without being retired during wrapper changes.
	var tree := get_tree()
	if get_parent() != tree.root:
		reparent(tree.root)
	# SceneTree.scene_changed emits no parameters; call the handler directly so a
	# future signature drift fails this focused runner before device testing.
	AdBarService.call("_on_scene_changed")
	_check(true, "AdBarService accepts the zero-argument scene_changed callback")
	await get_tree().process_frame
	await get_tree().process_frame
	var app_layout := get_tree().root.find_child("AppViewportLayout", true, false) as VBoxContainer
	var render_area := get_tree().root.find_child("GameRenderArea", true, false) as SubViewportContainer
	var content_viewport := get_tree().root.find_child("AppContentViewport", true, false) as SubViewport
	var ad_bar_area := get_tree().root.find_child("AdBarArea", true, false) as Control
	_check(is_instance_valid(app_layout) and is_instance_valid(render_area) and is_instance_valid(content_viewport) and is_instance_valid(ad_bar_area), "AdBarService owns a persistent content viewport and a separate ad-slot sibling")
	_check(AdBarService.call("_can_manage_app_layout") and AdBarService.call("_app_layout_is_live") and app_layout.get_parent() == tree.root and render_area.get_parent() == app_layout and content_viewport.get_parent() == render_area and ad_bar_area.get_parent() == app_layout, "AdBarService reuses its wrapper only while its service and every layout child remain live in the expected root ancestry")
	if OS.is_debug_build() and not FileAccess.file_exists("res://config/admob.json"):
		_check(AdBarService.ads_enabled() and AdBarService.call("_banner_unit_id") == "ca-app-pub-3940256099942544/6300978111" and not AdBarService.should_show_for_player_logged_in(""), "debug builds without the gitignored AdMob config use the official test banner while keeping login ad-free")
	for path in CONTROL_ROOT_SCENES:
		var packed := load(path) as PackedScene
		var root := packed.instantiate()
		_check(root is Control, "%s has a Control scene root" % path)
		if root is Control:
			var control := root as Control
			_check(is_equal_approx(control.anchor_left, 0.0) and is_equal_approx(control.anchor_top, 0.0) and is_equal_approx(control.anchor_right, 1.0) and is_equal_approx(control.anchor_bottom, 1.0), "%s remains full-rect inside the app content viewport" % path)
		root.free()
	var original_data := AppState.data.duplicate(true)
	AppState.data = SaveService.default_profile("Ad Layout Hero")
	AppState.data["owned_companions"] = ["sparkle", "rainbow", "star", "cloud", "dream", "mystic"]
	AppState.data["player"]["equipped_companion"] = "mystic"
	AppState.shell_view = "home"
	var home := preload("res://scenes/main.tscn").instantiate()
	tree.root.add_child(home)
	tree.current_scene = home
	AdBarService.call("_host_current_scene")
	await home.page_build_complete
	for _frame in 3:
		await get_tree().process_frame
	AdBarService.call("_set_reservation_active", true)
	home.call("_show_dashboard")
	await home.page_build_complete
	AdBarService.call("_set_reservation_active", true)
	for _frame in 3:
		await get_tree().process_frame
	var window_size := tree.root.get_visible_rect().size
	var slot_height := ad_bar_area.size.y if is_instance_valid(ad_bar_area) else 0.0
	var gutter_height := ad_bar_area.position.y - render_area.position.y - render_area.size.y
	var content_scene := AdBarService.content_scene()
	_check(slot_height > 0.0 and is_equal_approx(app_layout.size.y, window_size.y) and is_equal_approx(render_area.size.y, window_size.y - slot_height - 24.0) and content_viewport.get_visible_rect().size.is_equal_approx(render_area.size), "active banner keeps the app layout root-sized while the render viewport is exactly the window minus its separate slot and 24-pixel gutter")
	_check(is_equal_approx(gutter_height, 24.0) and is_equal_approx(float(app_layout.get_theme_constant("separation")), gutter_height) and is_equal_approx(content_viewport.get_visible_rect().size.y, render_area.size.y), "the active 24-pixel gutter is a VBox gap outside AppContentViewport, between game content and the native banner slot")
	_check(ad_bar_area.get_parent() == app_layout and is_equal_approx(ad_bar_area.size.x, app_layout.size.x) and is_equal_approx(render_area.size.x, app_layout.size.x), "the native ad slot remains a full-width sibling of the game render area")
	_check(is_equal_approx(slot_height, float(AdBarService.call("_reservation_height"))) and is_equal_approx(float(AdBarService.call("_reservation_height")), float(AdBarService.get("_banner_logical_height"))), "the ad slot reserves the actual native banner height without double-counting Android's bottom safe inset")
	_check(tree.current_scene == app_layout and content_scene == home and content_scene.get_parent() == content_viewport and content_scene.get_viewport() == content_viewport, "persistent app wrapper stays current while the actual Main scene is hosted in the content viewport")
	_check(home.find_children("CategoryIcon", "ArcadePictogram", true, false).size() == 4 and home.is_visible_in_tree() and get_tree().root.find_child("AdDisclosure", true, false) == null, "dashboard remains visibly built inside the reduced content viewport without a duplicate Godot disclosure")
	AdBarService.call("_set_reservation_active", false)
	for _frame in 2:
		await get_tree().process_frame
	gutter_height = ad_bar_area.position.y - render_area.position.y - render_area.size.y
	_check(is_zero_approx(ad_bar_area.size.y) and is_zero_approx(gutter_height) and is_zero_approx(float(app_layout.get_theme_constant("separation"))) and is_equal_approx(app_layout.size.y, window_size.y) and is_equal_approx(render_area.size.y, window_size.y) and content_viewport.get_visible_rect().size.is_equal_approx(window_size), "disabling ads collapses both the ad slot and gutter, restoring full-height content without shrinking the app layout")
	home.call("_show_home")
	await home.page_build_complete
	AdBarService.call("_set_reservation_active", true)
	for _frame in 2:
		await get_tree().process_frame
	var meadow := home.find_child("MeadowCompanionStage3D", true, false)
	var display := home.find_child("MeadowCompanionDisplay", true, false)
	var roots := []
	var models := []
	if is_instance_valid(meadow):
		roots = meadow.find_children("MeadowTravelRoot_*", "Node3D", true, false)
		models = meadow.find_children("LiveUnicornModel_*", "Node3D", true, false)
	var hero_root: Node3D = null
	var background_scale := 0.0
	var mid_count := 0
	var rear_count := 0
	var background_z: Array[float] = []
	for root in roots:
		if bool(root.get_meta("hero", false)):
			hero_root = root
		elif root.get_child_count() > 0:
			background_scale = maxf(background_scale, (root.get_child(0) as Node3D).scale.x)
			background_z.append(root.position.z)
			if str(root.get_meta("formation_row", "")) == "mid":
				mid_count += 1
			elif str(root.get_meta("formation_row", "")) == "rear":
				rear_count += 1
	background_z.sort()
	var laterally_spread := true
	for index in range(1, background_z.size()):
		laterally_spread = laterally_spread and background_z[index] - background_z[index - 1] >= 2.4
	_check(is_instance_valid(meadow) and is_instance_valid(display) and roots.size() == 6 and models.size() == 6 and is_instance_valid(hero_root) and is_equal_approx(hero_root.position.x, -5.8) and is_equal_approx(hero_root.position.y, -2.6) and hero_root.get_child(0).scale.x > background_scale and mid_count == 2 and rear_count == 3 and laterally_spread, "home shared meadow keeps the equipped hero lower and camera-near, with a staggered two-mid/three-rear companion formation")
	var ready: Variant = home.call("prepare_for_scene_change")
	if ready is Signal:
		await ready
	home.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	AppState.data = original_data
	if failures.is_empty():
		print("AD_LAYOUT_INTEGRATION_OK: %d checks" % checks)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
