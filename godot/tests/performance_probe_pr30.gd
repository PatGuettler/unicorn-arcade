extends Node

const MainScene = preload("res://scenes/main.tscn")
const MarketplaceScene = preload("res://scenes/meta/marketplace.tscn")
const ProfileView = preload("res://scripts/ui/profile_view.gd")
const GalaxyScene = preload("res://scenes/games/galaxy_unicorn.tscn")
const MathtrisScene = preload("res://scenes/games/mathtris.tscn")
const CometScene = preload("res://scenes/games/comet_math_rescue.tscn")
const WordScene = preload("res://scenes/games/word_game.tscn")

var _sample_count := 15
var _warmup_count := 5
var _output_path := ""
var _filter_index := 0
var _profile: ProfileView
var _marketplace: Control
var _galaxy: Control
var _galaxy_bullet_template: Array[Dictionary] = []
var _galaxy_enemy_template: Array[Dictionary] = []
var _galaxy_pickup_template: Array[Dictionary] = []
var _mathtris: Control
var _comet: Control
var _word: Control
var _access_root: Control


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_output_path = argument.trim_prefix("--output=")
		elif argument.begins_with("--samples="):
			_sample_count = maxi(5, int(argument.trim_prefix("--samples=")))
		elif argument.begins_with("--warmups="):
			_warmup_count = maxi(1, int(argument.trim_prefix("--warmups=")))
	if _output_path.is_empty():
		push_error("performance_probe_pr30 requires --output=<absolute JSON path>")
		get_tree().quit(2)
		return
	var saved_profile := AppState.data.duplicate(true)
	var saved_game_id := AppState.selected_game_id
	AppState.data = SaveService.default_profile("PR30 Benchmark")
	AppState.data["player"]["coins"] = 4321
	var scenarios := {}
	scenarios["startup_scene_construction"] = _measure(Callable(self, "_construct_main"), 12)
	await _setup_profile()
	scenarios["profile_filter_scroll"] = _measure(Callable(self, "_exercise_profile"), 12)
	await _setup_marketplace()
	scenarios["marketplace_refresh_scroll"] = _measure(Callable(self, "_exercise_marketplace"), 20)
	await _setup_galaxy()
	scenarios["galaxy_simulation_collision"] = _measure(Callable(self, "_exercise_galaxy"), 80)
	await _setup_mathtris()
	scenarios["mathtris_refresh"] = _measure(Callable(self, "_exercise_mathtris"), 15)
	await _setup_comet()
	scenarios["comet_layout"] = _measure(Callable(self, "_exercise_comet"), 400)
	await _setup_word()
	scenarios["word_timer_update"] = _measure(Callable(self, "_exercise_word"), 800)
	scenarios["inactive_game_experience"] = _measure(Callable(self, "_exercise_inactive_game_experience"), 1200)
	_setup_accessibility_root()
	scenarios["accessibility_safe_area_transition"] = _measure(Callable(self, "_exercise_accessibility_safe_area"), 80)
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for _cycle in 80:
		var main := MainScene.instantiate()
		var market := MarketplaceScene.instantiate()
		main.free()
		market.free()
	var memory_after := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var result := {
		"schema": 1,
		"timestamp_utc": Time.get_datetime_string_from_system(true, true),
		"machine": {
			"os": OS.get_name(),
			"os_version": OS.get_version(),
			"distribution": OS.get_distribution_name(),
			"cpu": OS.get_processor_name(),
			"logical_cpu_count": OS.get_processor_count(),
			"gpu": RenderingServer.get_video_adapter_name(),
			"godot": Engine.get_version_info(),
		},
		"warmups": _warmup_count,
		"sample_count": _sample_count,
		"scenarios": scenarios,
		"repeated_navigation_memory": {
			"cycles": 80,
			"static_before_bytes": memory_before,
			"static_after_bytes": memory_after,
			"static_delta_bytes": memory_after - memory_before,
		},
	}
	DirAccess.make_dir_recursive_absolute(_output_path.get_base_dir())
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write PR30 performance result: %s" % _output_path)
		get_tree().quit(3)
		return
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	AppState.data = saved_profile
	AppState.selected_game_id = saved_game_id
	print("PR30_PERFORMANCE_PROBE_OK: %s" % _output_path)
	get_tree().quit(0)


func _measure(operation: Callable, iterations: int) -> Dictionary:
	for _warmup in _warmup_count:
		for _iteration in iterations:
			operation.call()
	var samples: Array[float] = []
	for _sample in _sample_count:
		var started := Time.get_ticks_usec()
		for _iteration in iterations:
			operation.call()
		var elapsed := Time.get_ticks_usec() - started
		samples.append(float(elapsed) / float(iterations))
	var ordered := samples.duplicate()
	ordered.sort()
	var median_index := ordered.size() / 2
	var p95_index := mini(ordered.size() - 1, int(ceil(ordered.size() * 0.95)) - 1)
	return {
		"iterations_per_sample": iterations,
		"samples_us": samples,
		"median_us": ordered[median_index],
		"p95_us": ordered[p95_index],
	}


func _construct_main() -> void:
	var scene := MainScene.instantiate()
	scene.free()


func _always_true() -> bool:
	return true


func _noop() -> void:
	pass


func _setup_profile() -> void:
	_profile = ProfileView.new()
	_profile.size = Vector2(704, 1100)
	_profile.configure("All", Callable(self, "_always_true"), Callable(self, "_noop"), Callable(self, "_noop"), self)
	add_child(_profile)
	_profile.build()
	await _profile.build_complete


func _exercise_profile() -> void:
	var filters := ["All", "Number", "Word", "Mystery", "Arcade"]
	_filter_index = (_filter_index + 1) % filters.size()
	_profile.scroll_vertical = (_filter_index * 137) % 480
	_profile.apply_category_filter(filters[_filter_index])


func _setup_marketplace() -> void:
	_marketplace = MarketplaceScene.instantiate()
	_marketplace.size = Vector2(704, 1200)
	add_child(_marketplace)
	await get_tree().process_frame
	await get_tree().process_frame
	_marketplace.set_process(false)
	_marketplace.call("_show_decor")


func _exercise_marketplace() -> void:
	_marketplace.call("_refresh_decor_cards")
	var scroll := _marketplace.get("catalog_scroll") as ScrollContainer
	if is_instance_valid(scroll):
		scroll.scroll_vertical = (scroll.scroll_vertical + 71) % 900


func _setup_galaxy() -> void:
	AppState.selected_game_id = "galaxy_unicorn"
	_galaxy = GalaxyScene.instantiate()
	_galaxy.size = Vector2(704, 1200)
	add_child(_galaxy)
	await get_tree().process_frame
	_galaxy.set_process(false)
	_galaxy.active = false
	for index in 12:
		var position := Vector2(56 + index * 48, 300 + (index % 2) * 80)
		_galaxy_enemy_template.append({"position": position, "hp": 1, "radius": 14.0, "score": 10})
		_galaxy_bullet_template.append({"position": position, "previous_position": position + Vector2(0, 18), "speed": -0.5})
	for index in 12:
		_galaxy_enemy_template.append({"position": Vector2(40 + index * 51, 1280), "hp": 2, "radius": 14.0, "score": 10})
		_galaxy_bullet_template.append({"position": Vector2(30 + index * 52, 90), "previous_position": Vector2(30 + index * 52, 108), "speed": -0.5})
	var player := Vector2(_galaxy.player_x * _galaxy.size.x, _galaxy.call("_player_y"))
	for index in 8:
		_galaxy_pickup_template.append({"position": player + Vector2(index % 2, 0), "kind": "rapid", "radius": 14.0})
	for index in 8:
		_galaxy_pickup_template.append({"position": Vector2(40 + index * 60, 1240), "kind": "heal", "radius": 14.0})
	for index in 8:
		_galaxy_pickup_template.append({"position": Vector2(40 + index * 60, 520), "kind": "rapid", "radius": 14.0})


func _exercise_galaxy() -> void:
	_galaxy.set_random_seed(3001)
	_galaxy.bullets = _galaxy_bullet_template.duplicate(true)
	_galaxy.enemies = _galaxy_enemy_template.duplicate(true)
	_galaxy.pickups = _galaxy_pickup_template.duplicate(true)
	_galaxy.call("_resolve_collisions")


func _setup_mathtris() -> void:
	AppState.selected_game_id = "mathtris"
	_mathtris = MathtrisScene.instantiate()
	add_child(_mathtris)
	await get_tree().process_frame
	_mathtris.set_process(false)
	_mathtris.active = false


func _exercise_mathtris() -> void:
	_mathtris.call("_refresh")


func _setup_comet() -> void:
	AppState.selected_game_id = "comet_math_rescue"
	_comet = CometScene.instantiate()
	_comet.size = Vector2(704, 1200)
	add_child(_comet)
	await get_tree().process_frame
	_comet.set_process(false)
	_comet.active = false


func _exercise_comet() -> void:
	_comet.wave_elapsed_ms = fmod(_comet.wave_elapsed_ms + 13.0, maxf(1.0, _comet.decision_ms))
	_comet.call("_update_comet_positions")


func _setup_word() -> void:
	AppState.selected_game_id = "opposite_orbit"
	_word = WordScene.instantiate()
	add_child(_word)
	await get_tree().process_frame
	_word.set_process(false)
	_word.active = true
	_word.started_ms = Time.get_ticks_msec() - 1234


func _exercise_word() -> void:
	_word.call("_process", 0.0)


func _exercise_inactive_game_experience() -> void:
	GameExperience.call("_process", 0.0)


func _setup_accessibility_root() -> void:
	_access_root = Control.new()
	_access_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_access_root)
	for index in 60:
		var label := Label.new()
		label.text = "Benchmark label %d" % index
		_access_root.add_child(label)


func _exercise_accessibility_safe_area() -> void:
	AccessibleUI.call("_prune_applied")
	AccessibleUI.call("_apply_tree", _access_root)
	SafeArea.call("_prune_applied_roots")
	SafeArea.call("_apply_to_root", _access_root)
