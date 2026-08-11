extends Node

const MAIN_SCENE = preload("res://scenes/main.tscn")
const WORD_SCENE = preload("res://scenes/games/word_game.tscn")
const CASH_SCENE = preload("res://scenes/games/cash_counter.tscn")
const COIN_SCENE = preload("res://scenes/games/coin_count.tscn")
const RoomItemPreview3D = preload("res://scripts/meta/room_item_preview_3d.gd")


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var mode := "home"
	var game_id := ""
	var companion_id := "sparkle"
	var decor_category := "all"
	var output := ""
	var camera_position := Vector3.ZERO
	var camera_target := Vector3.ZERO
	var camera_override := false
	var ortho_size := 0.0
	var animation_name := ""
	var animation_progress := 0.5
	var owned_all := false
	var background_walk := false
	var skip_tutorial := false
	var capture_seed := -1
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--game-id="):
			game_id = argument.trim_prefix("--game-id=")
		elif argument.begins_with("--companion-id="):
			companion_id = argument.trim_prefix("--companion-id=")
		elif argument.begins_with("--category="):
			decor_category = argument.trim_prefix("--category=")
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		elif argument.begins_with("--camera="):
			camera_position = _parse_vector3(argument.trim_prefix("--camera="))
			camera_override = true
		elif argument.begins_with("--target="):
			camera_target = _parse_vector3(argument.trim_prefix("--target="))
		elif argument.begins_with("--ortho="):
			ortho_size = float(argument.trim_prefix("--ortho="))
		elif argument.begins_with("--animation="):
			animation_name = argument.trim_prefix("--animation=")
		elif argument.begins_with("--animation-progress="):
			animation_progress = clampf(float(argument.trim_prefix("--animation-progress=")), 0.0, 1.0)
		elif argument == "--owned-all":
			owned_all = true
		elif argument == "--background-walk":
			background_walk = true
		elif argument == "--skip-tutorial":
			skip_tutorial = true
		elif argument.begins_with("--seed="):
			capture_seed = int(argument.trim_prefix("--seed="))
	if output.is_empty():
		push_error("capture_alpha requires --output=<absolute png path>")
		get_tree().quit(2)
		return
	if mode == "profile":
		AppState.data = SaveService.default_profile("Profile Capture")
		AppState.data["player"]["coins"] = 4321
		AppState.data["progress"] = {
			"unicorn_jump": {"max_level": 3, "completed": [1, 2]},
			"sentence_sprout": {"max_level": 2, "completed": [1]},
			"opposite_orbit": {"max_level": 4, "completed": [1, 2, 3]},
		}
	AppState.data["player"]["name"] = "" if mode == "login" else "Playtester"
	AppState.data["player"]["equipped_companion"] = companion_id
	if owned_all:
		AppState.data["owned_companions"] = ["sparkle", "rainbow", "star", "cloud", "dream", "mystic"]
	if companion_id not in AppState.data["owned_companions"]:
		AppState.data["owned_companions"].append(companion_id)
	AppState.data["inventory"]["companion_%s" % companion_id] = maxi(1, int(AppState.data["inventory"].get("companion_%s" % companion_id, 0)))
	var captured: Node
	var capture_viewport: SubViewport
	if mode == "game":
		AppState.selected_game_id = game_id
		if skip_tutorial:
			AppState.data["tutorials"][game_id] = [1, 2, 3]
		var record := GameRegistry.get_game(game_id)
		var scene_path := str(record.get("scene", ""))
		if scene_path.is_empty():
			push_error("Unknown or unavailable game for capture: %s" % game_id)
			get_tree().quit(2)
			return
		captured = load(scene_path).instantiate()
	elif mode == "word_choice_fixture":
		AppState.selected_game_id = game_id
		captured = WORD_SCENE.instantiate()
	elif mode == "money_counter_fixture":
		AppState.selected_game_id = game_id
		captured = (COIN_SCENE if game_id == "coin_count" else CASH_SCENE).instantiate()
	elif mode == "game_chrome_fixture":
		captured = Control.new()
		captured.name = "GameChromeFixture"
		(captured as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif mode == "game_tutorial_fixture":
		captured = Control.new()
		captured.name = "GameTutorialFixture"
		(captured as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif mode in ["game_outcome_fixture", "game_sparkle_retry_fixture"]:
		captured = Control.new()
		captured.name = "GameOutcomeFixture"
		(captured as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif mode == "procedural_preview":
		# A catalog-miss forces RoomItemPreview3D through the procedural fallback.
		captured = RoomItemPreview3D.new()
		captured.setup({"id": "capture_unknown_rug", "category": "rugs", "animate": false, "presentation": "marketplace"})
		captured.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif mode == "companion_preview_static":
		captured = RoomItemPreview3D.new()
		captured.setup({"id": "companion_sparkle", "category": "companions", "animate": false, "presentation": "game_hud"})
		captured.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif mode in ["marketplace", "marketplace_decor", "alley", "room", "room_selected", "room_bag", "room_bag_empty"]:
		var meta_paths := {
			"marketplace": "res://scenes/meta/marketplace.tscn",
			"marketplace_decor": "res://scenes/meta/marketplace.tscn",
			"alley": "res://scenes/meta/unicorn_alley.tscn",
			"room": "res://scenes/meta/room_editor.tscn",
			"room_selected": "res://scenes/meta/room_editor.tscn",
			"room_bag": "res://scenes/meta/room_editor.tscn",
			"room_bag_empty": "res://scenes/meta/room_editor.tscn",
		}
		AppState.active_room_companion = companion_id
		if mode in ["room", "room_selected", "room_bag", "room_bag_empty"]:
			var inventory_count := 1 if mode == "room_bag_empty" else 2
			AppState.data["inventory"]["lamp"] = inventory_count
			AppState.data["inventory"]["rug"] = inventory_count
			AppState.data["inventory"]["plant"] = inventory_count
			AppState.data["rooms"][companion_id] = [
				{"instance_id": "preview_lamp", "item_id": "lamp", "x": 24.0, "y": 32.0, "rotation": 0, "scale": 1.0, "z_index": 1},
				{"instance_id": "preview_rug", "item_id": "rug", "x": 50.0, "y": 76.0, "rotation": 0, "scale": 1.4, "z_index": 2},
				{"instance_id": "preview_plant", "item_id": "plant", "x": 76.0, "y": 58.0, "rotation": -45, "scale": 1.1, "z_index": 3},
			]
		captured = load(meta_paths[mode]).instantiate()
	else:
		AppState.shell_view = mode
		if mode == "category":
			AppState.selected_category = "Word"
		captured = MAIN_SCENE.instantiate()
	if mode == "game":
		capture_viewport = SubViewport.new()
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(capture_viewport)
		capture_viewport.size = DisplayServer.window_get_size()
		capture_viewport.add_child(captured)
		if captured is Control:
			(captured as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		add_child(captured)
	# Game captures render inside a deterministic viewport so game roots receive
	# the requested phone dimensions even while this capture scene remains active.
	if mode == "game":
		if capture_seed >= 0:
			seed(capture_seed)
			var capture_rng := captured.get("rng") as RandomNumberGenerator
			if is_instance_valid(capture_rng):
				capture_rng.seed = capture_seed
			if captured.has_method("set_random_seed"):
				captured.call("set_random_seed", capture_seed)
			match game_id:
				"mathtris": captured.call("_start_game")
				"galaxy_unicorn", "comet_math_rescue": captured.call("_start_level", int(captured.get("level")))
				_: captured.call("_start_level")
		# Freeze time-driven gameplay after deterministic setup so pixel evidence
		# compares rendering and layout, not scheduler-dependent animation frames.
		captured.process_mode = Node.PROCESS_MODE_DISABLED
		if game_id == "opposite_orbit" and is_instance_valid(captured.get("timer_label")):
			(captured.get("timer_label") as Label).text = "0.0s"
	elif mode == "word_choice_fixture":
		seed(1337)
		var word_rng := captured.get("rng") as RandomNumberGenerator
		word_rng.seed = 1337
		captured.call("_start_level")
		if game_id == "sight_spark":
			var sight_flash := captured.get("flash_timer") as Timer
			if is_instance_valid(sight_flash):
				sight_flash.stop()
		captured.set("active", false)
		captured.set("started_ms", Time.get_ticks_msec())
		var word_timer := captured.get("timer_label") as Label
		if is_instance_valid(word_timer):
			word_timer.text = "0.0s"
	elif mode == "money_counter_fixture":
		captured.set_process(false)
		captured.set("target", 75)
		captured.set("total", 0)
		captured.set("active", false)
		if game_id == "coin_count":
			captured.get("target_label").text = "Make $0.75"
			captured.get("total_label").text = "$0.00"
		else:
			captured.get("target_label").text = "TARGET  $75"
			captured.get("total_label").text = "$0"
	elif mode == "game_chrome_fixture":
		_build_game_chrome_fixture(captured as Control, game_id)
	elif mode == "game_tutorial_fixture":
		_build_game_tutorial_fixture(captured as Control, game_id)
	elif mode == "game_outcome_fixture":
		_build_game_outcome_fixture(captured as Control)
	elif mode == "game_sparkle_retry_fixture":
		_build_game_sparkle_retry_fixture(captured as Control)
	elif captured.has_signal("page_build_complete"):
		await captured.page_build_complete
	if mode == "companion_preview_static":
		for frame in 120:
			if captured.find_child("LiveUnicornModel", true, false) != null and not RuntimeAssetLoader.is_processing():
				break
			await get_tree().process_frame
	if background_walk:
		var background_preview := captured.find_child("MeadowCompanion_*", true, false)
		if is_instance_valid(background_preview):
			var background_animator = background_preview.find_child("IdleAnimator", true, false)
			if is_instance_valid(background_animator) and background_animator.play_animation_now("Walk"):
				var background_clip: Animation = background_animator.animation_player.get_animation(background_animator.active_action)
				background_animator.animation_player.seek(background_clip.length * animation_progress, true)
				if background_animator.walk_tween != null:
					background_animator.walk_tween.custom_step(1.32)
	if not animation_name.is_empty():
		var animator = captured.find_child("IdleAnimator", true, false)
		if is_instance_valid(animator) and animator.play_animation_now(animation_name):
			var clip: Animation = animator.animation_player.get_animation(animator.active_action)
			animator.animation_player.seek(clip.length * animation_progress, true)
	if camera_override:
		var camera := _find_camera(captured)
		if camera != null:
			camera.look_at_from_position(camera_position, camera_target, Vector3.UP)
			if ortho_size > 0.0:
				camera.size = ortho_size
	if mode == "marketplace_decor":
		captured.category = decor_category
		captured.call("_show_decor")
	elif mode == "room_selected":
		captured.selected_id = "preview_rug"
		captured.call("_mark_selected")
	elif mode in ["room_bag", "room_bag_empty"]:
		captured.call("_show_bag")
	if is_instance_valid(capture_viewport):
		capture_viewport.size = DisplayServer.window_get_size()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var capture_texture := capture_viewport.get_texture() if is_instance_valid(capture_viewport) else get_viewport().get_texture()
	var error := capture_texture.get_image().save_png(output)
	if error == OK:
		print("ALPHA_CAPTURE_OK: %s" % output)
		get_tree().quit(0)
	else:
		push_error("Unable to save capture %s: %s" % [output, error_string(error)])
		get_tree().quit(1)


func _parse_vector3(raw: String) -> Vector3:
	var parts := raw.split(",")
	if parts.size() != 3:
		return Vector3.ZERO
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var found := _find_camera(child)
		if found != null:
			return found
	return null


func _build_game_chrome_fixture(fixture: Control, game_id: String) -> void:
	var title := "GALAXY UNICORN" if game_id == "galaxy_unicorn" else "COIN COUNT"
	var primary := "RAINBOW DEFENSE" if game_id == "galaxy_unicorn" else "MAKE 75 cents"
	var detail := "LEVEL 2 - LIVES 3 - 4/12 ENEMIES" if game_id == "galaxy_unicorn" else "BUILD THE EXACT TOTAL WITH REAL US COINS"
	GameExperience._apply_storybook_atmosphere(fixture)
	var margin := MarginContainer.new()
	margin.name = "GameChromeFixtureMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	fixture.add_child(margin)
	var layout := VBoxContainer.new()
	layout.name = "GameChromeFixtureLayout"
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var header := GameExperience._build_header(title)
	layout.add_child(header)
	var objective := GameExperience._build_objective_plaque()
	layout.add_child(objective)
	GameExperience.objective_primary.text = primary
	GameExperience.objective_detail.text = detail
	GameExperience._update_coin_button(275 if game_id == "galaxy_unicorn" else 75)
	GameExperience._update_ability_button()
	var sample := PanelContainer.new()
	sample.name = "FixtureGameplaySample"
	sample.custom_minimum_size.y = 300
	layout.add_child(sample)
	var sample_stack := VBoxContainer.new()
	sample_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	sample_stack.add_theme_constant_override("separation", 10)
	sample.add_child(sample_stack)
	var label := Label.new()
	label.name = "FixtureGameplayLabel"
	label.text = "A LITTLE PRACTICE ADVENTURE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	sample_stack.add_child(label)
	var action := Button.new()
	action.name = "FixtureGameplayAction"
	action.text = "CAST A RAINBOW"
	action.custom_minimum_size = Vector2(220, 60)
	sample_stack.add_child(action)
	var scroll := ScrollContainer.new()
	scroll.name = "FixtureGameplayScroll"
	scroll.custom_minimum_size = Vector2(0, 150)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sample_stack.add_child(scroll)
	var tips := VBoxContainer.new()
	tips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(tips)
	for copy in ["CHOOSE A KIND PATH", "WATCH THE OBJECTIVE", "YOUR COMPANION IS READY", "KEEP EXPLORING"]:
		var tip := Label.new()
		tip.text = copy
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip.add_theme_font_size_override("font_size", 18)
		tips.add_child(tip)
	GameExperience._restyle_controls(fixture)
	GameExperience._polish_game_labels(fixture)
	GameExperience._hide_game_scrollbars(fixture)


func _build_game_tutorial_fixture(fixture: Control, game_id: String) -> void:
	GameExperience._apply_storybook_atmosphere(fixture)
	GameExperience.attached_controller = null
	GameExperience.attached_scene = fixture
	GameExperience.attached_game_id = game_id
	GameExperience._maybe_show_tutorial(true)


func _build_game_outcome_fixture(fixture: Control) -> void:
	GameExperience._apply_storybook_atmosphere(fixture)
	GameExperience.attached_scene = fixture
	GameExperience.attached_controller = null
	GameExperience.attached_game_id = "coin_count"
	GameExperience.outcome_overlay = null
	GameExperience.sparkle_retry_overlay = null
	GameExperience._show_game_outcome()


func _build_game_sparkle_retry_fixture(fixture: Control) -> void:
	GameExperience._apply_storybook_atmosphere(fixture)
	GameExperience.attached_scene = fixture
	GameExperience.attached_controller = null
	GameExperience.attached_game_id = "coin_count"
	GameExperience.outcome_overlay = null
	GameExperience.sparkle_retry_overlay = null
	GameExperience._show_sparkle_retry_notice("A comet reached the meadow.")
