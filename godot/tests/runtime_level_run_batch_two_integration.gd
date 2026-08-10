extends Node

const LevelRunController = preload("res://scripts/games/level_run_controller.gd")
const SLIDING_SCENE = preload("res://scenes/games/sliding_window.tscn")
const JUMP_SCENE = preload("res://scenes/games/unicorn_jump.tscn")
const COMET_SCENE = preload("res://scenes/games/comet_math_rescue.tscn")
const GALAXY_SCENE = preload("res://scenes/games/galaxy_unicorn.tscn")
const Rules = preload("res://scripts/games/gameplay_rules.gd")


func _ready() -> void:
	_run.call_deferred()


func _mount(scene: PackedScene) -> Node:
	var instance := scene.instantiate()
	add_child(instance)
	await get_tree().process_frame
	return instance


func _unmount(instance: Node) -> void:
	remove_child(instance)
	instance.free()


func _run() -> void:
	var prior_data := AppState.data.duplicate(true)
	var prior_game_id := AppState.selected_game_id
	var prior_category := AppState.selected_category
	var prior_shell := AppState.shell_view
	var prior_dirty := AppState._has_unsaved_changes
	var prior_ability := {"game_id": CompanionAbilityService.game_id, "level": CompanionAbilityService.level, "used": CompanionAbilityService.used, "assist_hint_armed": CompanionAbilityService.assist_hint_armed}
	var issues: Array[String] = []
	if SaveService.begin_test_session():
		AppState.data = SaveService.create_profile("Level Run Batch Two")
		AppState.data["player"]["equipped_companion"] = "sparkle"
		AppState.data["settings"]["reduced_motion"] = true
		AppState._has_unsaved_changes = false
		await _test_sliding(issues)
		await _test_jump(issues)
		await _test_comet(issues)
		await _test_galaxy(issues)
		SaveService.end_test_session()
	else:
		issues.append("test session starts")
	AppState.data = prior_data
	AppState.selected_game_id = prior_game_id
	AppState.selected_category = prior_category
	AppState.shell_view = prior_shell
	AppState._has_unsaved_changes = prior_dirty
	CompanionAbilityService.game_id = prior_ability["game_id"]
	CompanionAbilityService.level = prior_ability["level"]
	CompanionAbilityService.used = prior_ability["used"]
	CompanionAbilityService.assist_hint_armed = prior_ability["assist_hint_armed"]
	if issues.is_empty():
		print("RUNTIME_LEVEL_RUN_BATCH_TWO_INTEGRATION_OK")
		get_tree().quit(0)
	else:
		push_error("Level run batch two assertions failed: %s" % "; ".join(issues))
		get_tree().quit(1)


func _records(game_id: String) -> int:
	return (AppState.progress_for_game(game_id).get("completed", []) as Array).size()


func _factory_check(game: Node, dimensions: Dictionary, issues: Array[String], label: String) -> void:
	var seen := {}
	for button in game.find_children("*", "Button", true, false):
		if button.has_meta("storybook_action"):
			var action := str(button.get_meta("storybook_action"))
			seen[action] = button
	for action in dimensions:
		var button := seen.get(action) as Button
		if not is_instance_valid(button) or not button.has_meta("storybook_game_action") or button.custom_minimum_size.x < float(dimensions[action]) or button.get_theme_stylebox("normal") == null:
			issues.append("%s uses %s Storybook action factory" % [label, action])


func _test_sliding(issues: Array[String]) -> void:
	AppState.selected_game_id = "sliding_window"
	var game: Node = await _mount(SLIDING_SCENE)
	var original_level: int = game.level
	if not game.active or game.level_run.outcome != LevelRunController.Outcome.RUNNING or game.started_ms != game.level_run.started_ms or CompanionAbilityService.game_id != "sliding_window" or CompanionAbilityService.level != original_level or game.runtime_snapshot()["objective_primary"] != "SLIDING WINDOW" or game.action_button.visible:
		issues.append("Sliding starts a synchronized live race with hidden progression")
	_factory_check(game, {"hint_highlight": 120.0, "progression": 160.0, "category_back": 170.0}, issues, "Sliding")
	game.level_data.clear()
	game.level_data.append_array([1, 9, 3])
	game.opponent_data.clear()
	game.opponent_data.append_array([1, 2, 3])
	game.window_size = 3
	game.window_pos = 0
	var coins_before := AppState.coins()
	var records_before := _records("sliding_window")
	game._choose(1)
	game._choose(1)
	if game.active or game.level != original_level or game.level_run.outcome != LevelRunController.Outcome.SUCCESS or AppState.coins() != coins_before + RewardService.level_reward(original_level) or _records("sliding_window") != records_before + 1 or not game.action_button.visible or game.action_button.text != "Next Level":
		issues.append("Sliding completion is frozen, delayed, and idempotent")
	game._advance_level()
	if not game.active or game.level != original_level + 1 or game.level_run.level != game.level:
		issues.append("Sliding typed next action advances once")
	game.opponent_data.clear()
	game.opponent_data.append_array([1, 2, 3])
	game.window_size = 3
	game.opponent_pos = 0
	game.rival_elapsed = Rules.rival_move_ms(game.level)
	game._process(0.0)
	if game.level_run.outcome != LevelRunController.Outcome.FAILURE or not game.can_retry_failure() or game.action_button.text != "Retry" or not game.action_button.visible:
		issues.append("Sliding rival race failure uses lifecycle retry")
	game.retry_failure()
	if not game.active or game.level != original_level + 1 or CompanionAbilityService.game_id != "sliding_window" or CompanionAbilityService.level != game.level:
		issues.append("Sliding failure retry preserves level and companion")
	_unmount(game)


func _test_jump(issues: Array[String]) -> void:
	AppState.selected_game_id = "unicorn_jump"
	var game: Node = await _mount(JUMP_SCENE)
	var original_level: int = game.level
	if not game.active or game.started_ms != game.level_run.started_ms or CompanionAbilityService.game_id != "unicorn_jump" or game.runtime_snapshot()["objective_primary"].begins_with("JUMP FORWARD") == false or game.action_button.visible:
		issues.append("Jump starts a synchronized one-based trail")
	_factory_check(game, {"progression": 112.0, "category_back": 112.0, "hint_highlight": 112.0}, issues, "Jump")
	for button in game.find_children("*", "Button", true, false):
		if button.has_meta("storybook_action") and button.custom_minimum_size.y < 60.0:
			issues.append("Jump preserves 60px action height")
	game.level_data.clear()
	game.level_data.append_array([2, 1])
	game._rebuild_path()
	game._choose_node(1)
	if not game.active or not CompanionAbilityService.used:
		issues.append("Jump Sparkle checkpoint declines first wrong landing")
	game._choose_node(1)
	if game.level_run.outcome != LevelRunController.Outcome.FAILURE or not game.can_retry_failure() or game.action_button.text != "Retry":
		issues.append("Jump fails only after Sparkle checkpoint rescue declines")
	game.retry_failure()
	game.level_data.clear()
	game.level_data.append(1)
	game.current_index = 0
	var reset_visited: Array[int] = [0]
	game.visited = reset_visited
	game._rebuild_path()
	var coins_before := AppState.coins()
	var records_before := _records("unicorn_jump")
	game._choose_node(1)
	await get_tree().create_timer(0.22).timeout
	game._choose_node(1)
	if game.active or game.level != original_level or game.level_run.outcome != LevelRunController.Outcome.SUCCESS or AppState.coins() != coins_before + RewardService.level_reward(original_level) or _records("unicorn_jump") != records_before + 1 or game.action_button.text != "Next Level":
		issues.append("Jump awaited completion is delayed and idempotent")
	game._advance_level()
	if not game.active or game.level != original_level + 1 or CompanionAbilityService.level != game.level:
		issues.append("Jump typed next starts the next companion level")
	_unmount(game)


func _test_comet(issues: Array[String]) -> void:
	AppState.selected_game_id = "comet_math_rescue"
	var game: Node = await _mount(COMET_SCENE)
	var original_level: int = game.level
	if not game.active or game.started_ms != game.level_run.started_ms or CompanionAbilityService.game_id != "comet_math_rescue" or not game.runtime_snapshot()["objective_primary"].ends_with("= ?") or game.action_button.visible:
		issues.append("Comet starts a synchronized live rescue")
	_factory_check(game, {"progression": 170.0, "category_back": 150.0}, issues, "Comet")
	if game.fire_button.text != "FIRE RAINBOW" or game.fire_button.get_meta("storybook_action", "") != "":
		issues.append("Comet keeps FIRE RAINBOW as its dedicated action")
	var coins_before := AppState.coins()
	game.lives = 1
	game._resolve_timeout()
	game._resolve_timeout()
	if game.level_run.outcome != LevelRunController.Outcome.FAILURE or AppState.coins() != coins_before or not game.can_retry_failure() or game.action_button.text != "Retry" or not game.status_label.text.begins_with("Time ran out."):
		issues.append("Comet timeout is a bolt-free lifecycle miss")
	game.retry_failure()
	game.target_rescues = 1
	var records_before := _records("comet_math_rescue")
	game._resolve_wave(true)
	game._finish_wave()
	if game.active or game.level != original_level or game.level_run.outcome != LevelRunController.Outcome.SUCCESS or AppState.coins() != coins_before + RewardService.level_reward(original_level) or _records("comet_math_rescue") != records_before + 1 or game.action_button.text != "Next Mission":
		issues.append("Comet success is delayed and idempotent")
	game._advance_level()
	if not game.active or game.level != original_level + 1 or CompanionAbilityService.level != game.level:
		issues.append("Comet typed next starts the next mission")
	_unmount(game)


func _test_galaxy(issues: Array[String]) -> void:
	AppState.selected_game_id = "galaxy_unicorn"
	var game: Node = await _mount(GALAXY_SCENE)
	game.set_process(false)
	game.size = Vector2(720.0, 1280.0)
	game._start_level(1)
	if not game.active or game.started_ms != game.level_run.started_ms or CompanionAbilityService.game_id != "galaxy_unicorn" or game.runtime_snapshot()["objective_primary"] != "RAINBOW DEFENSE" or not is_equal_approx(game.opening_timer, 1500.0) or game.opening_left != 4:
		issues.append("Galaxy starts synchronized with the 1500ms opening")
	_factory_check(game, {"progression": 160.0, "category_back": 150.0}, issues, "Galaxy")
	var player_before: float = game.player_x
	game.set_gameplay_paused(true)
	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(650, 900)
	game._input(drag)
	game._process(1.0)
	if game.player_x != player_before or not is_equal_approx(game.opening_timer, 1500.0) or not game.enemies.is_empty():
		issues.append("Galaxy pause guard freezes input and opening")
	game.set_gameplay_paused(false)
	game._process(1.5)
	if game.enemies.size() != 1 or game.opening_left != 3:
		issues.append("Galaxy opens after exactly 1500ms")
	var coins_before := AppState.coins()
	game.lives = 1
	game._lose_life(0.0)
	game._lose_life(0.0)
	if game.level_run.outcome != LevelRunController.Outcome.FAILURE or AppState.coins() != coins_before or not game.can_retry_failure() or game.action_button.text != "Retry":
		issues.append("Galaxy life-zero failure has no payout and retries")
	game.retry_failure()
	var records_before := _records("galaxy_unicorn")
	game.kills = game.target_kills
	game._resolve_collisions()
	game._resolve_collisions()
	if game.active or game.level != 1 or game.level_run.outcome != LevelRunController.Outcome.SUCCESS or AppState.coins() != coins_before + RewardService.level_reward(1) or _records("galaxy_unicorn") != records_before + 1 or game.action_button.text != "Next Sector":
		issues.append("Galaxy success is delayed and idempotent")
	game._advance_level()
	if not game.active or game.level != 2 or CompanionAbilityService.level != 2:
		issues.append("Galaxy typed next starts the next sector")
	_unmount(game)
