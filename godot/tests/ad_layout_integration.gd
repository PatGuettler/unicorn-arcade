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
	var hosted_scene := Control.new()
	hosted_scene.name = "AdLayoutHostedScene"
	hosted_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(hosted_scene)
	get_tree().current_scene = hosted_scene
	AdBarService.call("_host_current_scene")
	await get_tree().process_frame
	for path in CONTROL_ROOT_SCENES:
		var packed := load(path) as PackedScene
		var root := packed.instantiate()
		_check(root is Control, "%s has a Control scene root" % path)
		if root is Control:
			var control := root as Control
			_check(is_equal_approx(control.anchor_left, 0.0) and is_equal_approx(control.anchor_top, 0.0) and is_equal_approx(control.anchor_right, 1.0) and is_equal_approx(control.anchor_bottom, 1.0), "%s remains full-rect inside the app content viewport" % path)
		root.free()
	AdBarService.call("_set_reservation_active", true)
	await get_tree().process_frame
	await get_tree().process_frame
	var window_size := get_tree().root.get_visible_rect().size
	var slot_height := ad_bar_area.size.y if is_instance_valid(ad_bar_area) else 0.0
	var scene := get_tree().current_scene
	var content_scene := AdBarService.content_scene()
	_check(slot_height > 0.0 and is_equal_approx(app_layout.size.y - render_area.size.y, slot_height) and is_equal_approx(content_viewport.get_visible_rect().size.y, render_area.size.y), "active banner reserves a separate bottom slot and makes the game viewport exactly the remaining render area")
	_check(scene == app_layout and content_scene == hosted_scene and content_scene.get_parent() == content_viewport and is_equal_approx(render_area.size.x, window_size.x) and is_equal_approx(app_layout.size.y, window_size.y), "persistent app wrapper stays current while content_scene is hosted inside the content viewport")
	_check(is_instance_valid(content_scene) and content_scene.get_viewport() == content_viewport and get_tree().root.find_child("AdDisclosure", true, false) == null, "games see only the content viewport and native banners add no duplicate Godot disclosure")
	AdBarService.call("_set_reservation_active", false)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(is_zero_approx(ad_bar_area.size.y) and is_equal_approx(render_area.size.y, app_layout.size.y) and is_equal_approx(content_viewport.get_visible_rect().size.y, window_size.y), "disabling ads collapses the ad slot and restores full-height game content")
	var original_data := AppState.data.duplicate(true)
	AppState.data = SaveService.default_profile("Ad Layout Hero")
	AppState.data["owned_companions"] = ["sparkle", "rainbow", "star", "cloud", "dream", "mystic"]
	AppState.data["player"]["equipped_companion"] = "mystic"
	var home := preload("res://scenes/main.tscn").instantiate()
	add_child(home)
	await home.page_build_complete
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
	_check(is_instance_valid(meadow) and is_instance_valid(display) and roots.size() == 6 and models.size() == 6 and is_instance_valid(hero_root) and hero_root.position.x < 0.0 and hero_root.get_child(0).scale.x > background_scale and mid_count == 2 and rear_count == 3 and laterally_spread, "home shared meadow keeps the equipped hero camera-near, with a staggered two-mid/three-rear companion formation")
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
