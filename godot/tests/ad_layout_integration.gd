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

const TEST_RESERVE := 91.25
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
	for path in CONTROL_ROOT_SCENES:
		var packed := load(path) as PackedScene
		var root := packed.instantiate()
		_check(root is Control, "%s has a Control scene root" % path)
		if root is Control:
			var control := root as Control
			var original := control.offset_bottom
			AdBarService.apply_reservation_to_root(control, TEST_RESERVE)
			_check(is_equal_approx(control.offset_bottom, original - TEST_RESERVE), "%s reserves the banner, disclosure, and safe inset" % path)
			AdBarService.apply_reservation_to_root(control, TEST_RESERVE)
			_check(is_equal_approx(control.offset_bottom, original - TEST_RESERVE), "%s does not accumulate shared ad reservation" % path)
			AdBarService.restore_reservation_for_root(control)
			_check(is_equal_approx(control.offset_bottom, original), "%s restores its original bottom offset" % path)
		root.free()
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
	for root in roots:
		if bool(root.get_meta("hero", false)):
			hero_root = root
		elif root.get_child_count() > 0:
			background_scale = maxf(background_scale, (root.get_child(0) as Node3D).scale.x)
	_check(is_instance_valid(meadow) and is_instance_valid(display) and roots.size() == 6 and models.size() == 6 and is_instance_valid(hero_root) and hero_root.position.z > 1.0 and hero_root.get_child(0).scale.x > background_scale, "home shared meadow keeps the equipped hero front and larger than every background companion")
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
