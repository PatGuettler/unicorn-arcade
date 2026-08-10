extends Node

const LevelRunController = preload("res://scripts/games/level_run_controller.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const COIN_SCENE = preload("res://scenes/games/coin_count.tscn")
const CASH_SCENE = preload("res://scenes/games/cash_counter.tscn")
const RHYME_SCENE = preload("res://scenes/games/rhyme_rally.tscn")
const MATH_SCENE = preload("res://scenes/games/math_swipe.tscn")


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
		AppState.data = SaveService.create_profile("Level Run Integration")
		AppState.data["player"]["equipped_companion"] = "sparkle"
		AppState._has_unsaved_changes = false
		_test_controller(issues)
		await _test_games(issues)
		_test_factories(issues)
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
		print("RUNTIME_LEVEL_RUN_INTEGRATION_OK")
		get_tree().quit(0)
	else:
		push_error("Level run integration assertions failed: %s" % "; ".join(issues))
		get_tree().quit(1)


func _test_controller(issues: Array[String]) -> void:
	var run := LevelRunController.new()
	if run.active or run.outcome != LevelRunController.Outcome.IDLE:
		issues.append("controller starts idle")
	run.begin("coin_count", 2)
	if not run.active or run.outcome != LevelRunController.Outcome.RUNNING or run.elapsed_ms() < 0 or CompanionAbilityService.game_id != "coin_count" or CompanionAbilityService.level != 2:
		issues.append("controller begins active companion run")
	run.fail("miss")
	var failed_reward := run.complete()
	if run.active or run.outcome != LevelRunController.Outcome.FAILURE or failed_reward != 0 or run.retry() != 2:
		issues.append("failure has no payout and retries same level")
	var coins_before := AppState.coins()
	var records_before := (AppState.progress_for_game("coin_count").get("completed", []) as Array).size()
	var expected := RewardService.level_reward(2)
	var reward := run.complete()
	var repeat_reward := run.complete()
	var records_after := (AppState.progress_for_game("coin_count").get("completed", []) as Array).size()
	if reward != expected or repeat_reward != expected or AppState.coins() != coins_before + expected or records_after != records_before + 1 or run.retry() != 3:
		issues.append("completion freezes one payout and advances next level")
	if run.select_category() != "Number":
		issues.append("registry category selection")


func _test_games(issues: Array[String]) -> void:
	await _test_coin(issues)
	await _test_cash(issues)
	await _test_rhyme(issues)
	await _test_math(issues)


func _test_coin(issues: Array[String]) -> void:
	var game: Node = await _mount(COIN_SCENE)
	var original_level: int = int(game.level)
	var category: String = str(game.prepare_category_return())
	if category != "Number" or AppState.shell_view != "category" or AppState.selected_category != "Number":
		issues.append("Coin Count prepares registry category return without navigation")
	game.call("_advance_round")
	if not game.active or game.level != original_level or game.level_run.outcome != LevelRunController.Outcome.RUNNING:
		issues.append("Coin Count running Retry / Next restarts same level")
	game.target = 1
	game.total = 0
	var objective: String = str(game.runtime_snapshot().get("objective_primary"))
	var coins_before := AppState.coins()
	var records_before := (AppState.progress_for_game("coin_count").get("completed", []) as Array).size()
	game.call("_add_coin", 1)
	game.call("_add_coin", 1)
	if game.level_run.outcome != LevelRunController.Outcome.SUCCESS or game.active != game.level_run.active or game.level != original_level + 1 or game.started_ms != game.level_run.started_ms or game.runtime_snapshot().get("objective_primary") != objective or AppState.coins() != coins_before + RewardService.level_reward(original_level) or (AppState.progress_for_game("coin_count").get("completed", []) as Array).size() != records_before + 1:
		issues.append("Coin Count lifecycle sync and idempotent completion")
	game.call("_add_coin", 1)
	game.call("_advance_round")
	if not game.active or game.active != game.level_run.active or game.level != original_level + 1 or game.level_run.level != original_level + 1 or CompanionAbilityService.game_id != "coin_count" or CompanionAbilityService.level != game.level:
		issues.append("Coin Count next lifecycle")
	game.target = 1
	game.total = 0
	game.call("_add_coin", 2)
	game.call("retry_failure")
	if not game.active or game.level != original_level + 1:
		issues.append("Coin Count failure retry")
	_unmount(game)


func _test_cash(issues: Array[String]) -> void:
	var game: Node = await _mount(CASH_SCENE)
	var original_level: int = int(game.level)
	if game.retry_button.visible:
		issues.append("Cash Counter keeps progression action hidden initially")
	game.target = 1
	game.total = 0
	var objective: String = str(game.runtime_snapshot().get("objective_primary"))
	var coins_before := AppState.coins()
	var records_before := (AppState.progress_for_game("cash_counter").get("completed", []) as Array).size()
	game.call("_add_bill", 1)
	game.call("_add_bill", 1)
	if game.level_run.outcome != LevelRunController.Outcome.SUCCESS or game.active != game.level_run.active or game.level != original_level + 1 or game.runtime_snapshot().get("objective_primary") != objective or AppState.coins() != coins_before + RewardService.level_reward(original_level) or (AppState.progress_for_game("cash_counter").get("completed", []) as Array).size() != records_before + 1 or not game.retry_button.visible or game.retry_button.text != "NEXT LEVEL":
		issues.append("Cash Counter immediate level progression")
	game.call("_advance_round")
	game.target = 1
	game.total = 0
	game.call("_add_bill", 5)
	if not game.can_retry_failure():
		issues.append("Cash Counter exposes failure retry")
	game.call("retry_failure")
	if not game.active or game.active != game.level_run.active or game.level != original_level + 1 or CompanionAbilityService.game_id != "cash_counter" or CompanionAbilityService.level != game.level:
		issues.append("Cash Counter lifecycle retry")
	_unmount(game)


func _test_rhyme(issues: Array[String]) -> void:
	var game: Node = await _mount(RHYME_SCENE)
	var original_level: int = int(game.level)
	game.call("_advance_level")
	if not game.active or game.level != original_level or game.level_run.outcome != LevelRunController.Outcome.RUNNING:
		issues.append("Rhyme Rally running Retry / Next restarts same level")
	game.target_rounds = 1
	game.round_index = 0
	game.challenge = {"answer": "hat", "prompt": "cat", "options": ["hat"]}
	var objective: String = str(game.runtime_snapshot().get("objective_primary"))
	var coins_before := AppState.coins()
	var records_before := (AppState.progress_for_game("rhyme_rally").get("completed", []) as Array).size()
	game.call("_pick", "hat")
	game.call("_pick", "hat")
	if game.level_run.outcome != LevelRunController.Outcome.SUCCESS or game.active != game.level_run.active or game.level != original_level + 1 or game.runtime_snapshot().get("objective_primary") != objective or AppState.coins() != coins_before + RewardService.level_reward(original_level) or (AppState.progress_for_game("rhyme_rally").get("completed", []) as Array).size() != records_before + 1:
		issues.append("Rhyme Rally lifecycle completion")
	game.call("_advance_level")
	game.challenge = {"answer": "hat", "prompt": "cat", "options": ["hat"]}
	game.call("_pick", "dog")
	game.call("retry_failure")
	if not game.active or game.active != game.level_run.active or game.level != original_level + 1 or CompanionAbilityService.game_id != "rhyme_rally" or CompanionAbilityService.level != game.level:
		issues.append("Rhyme Rally failure retry")
	_unmount(game)


func _test_math(issues: Array[String]) -> void:
	var game: Node = await _mount(MATH_SCENE)
	var original_level: int = int(game.level)
	if game.action_button.visible:
		issues.append("Math Swipe progression action stays hidden initially")
	game.target = 1
	var correct: Button = game.cards.filter(func(card: Button) -> bool: return bool(card.get_meta("correct", false)))[0]
	var objective: String = str(game.runtime_snapshot().get("objective_primary"))
	var coins_before := AppState.coins()
	var records_before := (AppState.progress_for_game("math_swipe").get("completed", []) as Array).size()
	game.call("_submit", correct)
	game.call("_submit", correct)
	if game.level_run.outcome != LevelRunController.Outcome.SUCCESS or game.active != game.level_run.active or game.level != original_level or game.runtime_snapshot().get("objective_primary") != objective or AppState.coins() != coins_before + RewardService.level_reward(original_level) or (AppState.progress_for_game("math_swipe").get("completed", []) as Array).size() != records_before + 1 or not game.action_button.visible or game.action_button.text != "Next Level":
		issues.append("Math Swipe defers public level progression")
	game.call("_advance_level")
	if not game.active or game.active != game.level_run.active or game.level != original_level + 1 or CompanionAbilityService.game_id != "math_swipe" or CompanionAbilityService.level != game.level:
		issues.append("Math Swipe typed next-level action")
	var wrong: Button = game.cards.filter(func(card: Button) -> bool: return not bool(card.get_meta("correct", false)))[0]
	game.call("_submit", wrong)
	game.call("retry_failure")
	if not game.active or game.level != original_level + 1:
		issues.append("Math Swipe failure retry")
	_unmount(game)


func _test_factories(issues: Array[String]) -> void:
	var calls := [0]
	var callback := func() -> void: calls[0] += 1
	var factories := [
		[StorybookUI.category_back_button("Number Games", 210, callback), "category_back", "Number Games", 210.0],
		[StorybookUI.progression_action_button("Retry / Next", 170, callback), "progression", "Retry / Next", 170.0],
		[StorybookUI.hint_highlight_button("Hint", 120, callback), "hint_highlight", "Hint", 120.0],
	]
	for item in factories:
		var button: Button = item[0]
		button.pressed.emit()
		if button.text != item[2] or button.custom_minimum_size.x < float(item[3]) or str(button.get_meta("storybook_action")) != item[1] or not button.has_meta("storybook_game_action") or button.get_theme_stylebox("normal") == null:
			issues.append("Storybook action factories preserve action styling")
	if calls[0] != factories.size():
		issues.append("Storybook action factory callbacks")
