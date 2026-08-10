extends Node

const COIN_SCENE = preload("res://scenes/games/coin_count.tscn")
const RHYME_SCENE = preload("res://scenes/games/rhyme_rally.tscn")
const WORD_SCENE = preload("res://scenes/games/word_game.tscn")
const COMET_SCENE = preload("res://scenes/games/comet_math_rescue.tscn")
const MATHTRIS_SCENE = preload("res://scenes/games/mathtris.tscn")
const JUMP_SCENE = preload("res://scenes/games/unicorn_jump.tscn")
const RoundCatalog = preload("res://scripts/games/word_round_catalog.gd")
const WordRules = preload("res://scripts/games/word_game_rules.gd")


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
	var prior_dirty := AppState._has_unsaved_changes
	var prior_ability := {"game_id": CompanionAbilityService.game_id, "level": CompanionAbilityService.level, "used": CompanionAbilityService.used, "assist_hint_armed": CompanionAbilityService.assist_hint_armed}
	var issues: Array[String] = []
	if not SaveService.begin_test_session():
		issues.append("editor test session")
	else:
		AppState.data = SaveService.create_profile("Gameplay Correctness")
		AppState._has_unsaved_changes = false
		await _test_coin_and_rhyme(issues)
		await _test_word_hints_and_empty_sources(issues)
		await _test_comet_timeout(issues)
		await _test_mathtris_fallback(issues)
		await _test_jump_copy(issues)
		await _test_stale_id_pruning(issues)
	SaveService.end_test_session()
	AppState.data = prior_data
	AppState.selected_game_id = prior_game_id
	AppState._has_unsaved_changes = prior_dirty
	CompanionAbilityService.game_id = prior_ability["game_id"]
	CompanionAbilityService.level = prior_ability["level"]
	CompanionAbilityService.used = prior_ability["used"]
	CompanionAbilityService.assist_hint_armed = prior_ability["assist_hint_armed"]
	if issues.is_empty():
		print("RUNTIME_GAMEPLAY_CORRECTNESS_INTEGRATION_OK")
		get_tree().quit(0)
	else:
		push_error("Gameplay correctness assertions failed: %s" % "; ".join(issues))
		get_tree().quit(1)


func _test_coin_and_rhyme(issues: Array[String]) -> void:
	var coin: Node = await _mount(COIN_SCENE)
	coin.target = 1
	coin.total = 0
	coin.active = true
	coin.failed = false
	var coins_before: int = AppState.coins()
	var coin_runs_before := (AppState.progress_for_game("coin_count").get("completed", []) as Array).size()
	var coin_reward: int = RewardService.level_reward(coin.level)
	coin.call("_add_coin", 1)
	coin.call("_add_coin", 1)
	if coin.total != 1 or coin.active or AppState.coins() != coins_before + coin_reward or (AppState.progress_for_game("coin_count").get("completed", []) as Array).size() != coin_runs_before + 1:
		issues.append("Coin Count completion input is idempotent")
	_unmount(coin)
	var rhyme: Node = await _mount(RHYME_SCENE)
	rhyme.target_rounds = 1
	rhyme.round_index = 0
	rhyme.challenge = {"answer": "hat", "prompt": "cat", "options": ["hat"]}
	rhyme.active = true
	coins_before = AppState.coins()
	var rhyme_runs_before := (AppState.progress_for_game("rhyme_rally").get("completed", []) as Array).size()
	var rhyme_reward: int = RewardService.level_reward(rhyme.level)
	rhyme.call("_pick", "hat")
	rhyme.call("_pick", "hat")
	if rhyme.round_index != 1 or rhyme.active or AppState.coins() != coins_before + rhyme_reward or (AppState.progress_for_game("rhyme_rally").get("completed", []) as Array).size() != rhyme_runs_before + 1:
		issues.append("Rhyme Rally completion input is idempotent")
	_unmount(rhyme)


func _test_word_hints_and_empty_sources(issues: Array[String]) -> void:
	AppState.selected_game_id = "missing_magic"
	var word: Node = await _mount(WORD_SCENE)
	AppState.data["player"]["coins"] = 12
	word.level = 1
	word.active = true
	word.hint_visible = false
	word.call("_request_hint")
	var free_hint_ok: bool = word.hint_visible and AppState.coins() == 12
	word.level = 2
	word.hint_visible = false
	AppState.data["player"]["coins"] = 4
	word.call("_request_hint")
	var insufficient_ok: bool = not word.hint_visible and AppState.coins() == 4 and word.message_label.text.contains("coins")
	AppState.data["player"]["coins"] = 10
	word.call("_request_hint")
	var paid_hint_ok: bool = word.hint_visible and AppState.coins() == 5
	var source_cache := WordRules._cache.duplicate(true)
	WordRules._cache = {"falling_words": {"easy": []}}
	word.game_id = "unicorn_blast"
	word.level = 1
	word.active = true
	word.blast_source_exhausted = false
	word.call("_clear_blast_words")
	var no_spawn: bool = not word.call("_spawn_blast_word") and word.blast_words.is_empty() and word.blast_source_exhausted
	word.call("_update_blast", 30.0)
	WordRules._cache = source_cache
	var catalog_empty_ok := RoundCatalog.word_for_round([], 1, 0).is_empty() and RoundCatalog.vowel_for_round([], 1, 0).is_empty() and RoundCatalog.vowel_round({}, [], 1, 0, RandomNumberGenerator.new()).is_empty() and (RoundCatalog.sequence_round({}, "missing").get("sequence", []) as Array).is_empty()
	if not free_hint_ok or not insufficient_ok or not paid_hint_ok:
		issues.append("Word Game free, insufficient, and paid hint contracts")
	if not no_spawn or not catalog_empty_ok:
		issues.append("Word Game empty sources are controlled")
	_unmount(word)


func _test_comet_timeout(issues: Array[String]) -> void:
	var comet: Node = await _mount(COMET_SCENE)
	comet.selected_lane = comet.correct_lane
	var lives_before: int = comet.lives
	var rescues_before: int = comet.rescues
	var timeout_result: bool = comet.call("_resolve_timeout")
	var first_timeout_ok: bool = not timeout_result and comet.lives == lives_before - 1 and comet.rescues == rescues_before and comet.bolt_lane == -1 and comet.status_label.text.contains("Time ran out")
	comet.call("_resolve_timeout")
	if not first_timeout_ok or comet.lives != lives_before - 1 or comet.rescues != rescues_before:
		issues.append("Comet timeout is a distinct idempotent miss")
	_unmount(comet)


func _test_mathtris_fallback(issues: Array[String]) -> void:
	var mathtris: Node = await _mount(MATHTRIS_SCENE)
	var initial_clear := (mathtris.call("_find_matches") as Array).is_empty()
	mathtris._test_force_seed_failure = true
	mathtris.call("_seed_bottom_pile")
	mathtris._test_force_seed_failure = false
	var fallback_clear := (mathtris.call("_find_matches") as Array).is_empty()
	if not initial_clear or not fallback_clear:
		issues.append("Mathtris seed and deterministic fallback are match-free")
	_unmount(mathtris)


func _test_jump_copy(issues: Array[String]) -> void:
	var jump: Node = await _mount(JUMP_SCENE)
	var prior_companion := AppState.equipped_companion()
	AppState.data["player"]["equipped_companion"] = "rainbow"
	jump.current_index = 0
	var test_steps: Array[int] = [1, 1, 1]
	jump.level_data = test_steps
	jump.active = true
	jump.call("_choose_node", 2)
	if not jump.status_label.text.contains("stone 2"):
		issues.append("Unicorn Jump wrong-landing copy is one-based")
	AppState.data["player"]["equipped_companion"] = prior_companion
	_unmount(jump)


func _test_stale_id_pruning(issues: Array[String]) -> void:
	var accessible_stale := Label.new()
	var safe_area_stale := Control.new()
	add_child(accessible_stale)
	add_child(safe_area_stale)
	var accessible_id := accessible_stale.get_instance_id()
	var safe_area_id := safe_area_stale.get_instance_id()
	AccessibleUI.applied[accessible_id] = true
	SafeArea.applied_roots[safe_area_id] = Vector4.ZERO
	accessible_stale.queue_free()
	safe_area_stale.queue_free()
	await get_tree().process_frame
	AccessibleUI.call("_on_scene_changed")
	SafeArea.call("_on_scene_changed")
	if AccessibleUI.applied.has(accessible_id) or SafeArea.applied_roots.has(safe_area_id):
		issues.append("Accessibility and safe-area stale IDs are pruned")
