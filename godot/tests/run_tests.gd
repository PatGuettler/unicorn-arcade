extends SceneTree

const RewardServiceScript = preload("res://autoload/reward_service.gd")
const GameRegistryScript = preload("res://autoload/game_registry.gd")
const SaveServiceScript = preload("res://autoload/save_service.gd")
const WordRules = preload("res://scripts/games/word_game_rules.gd")
const GameplayRules = preload("res://scripts/games/gameplay_rules.gd")

var failures: Array[String] = []
var check_count := 0


func _init() -> void:
	var rewards = RewardServiceScript.new()
	var registry = GameRegistryScript.new()
	var saves = SaveServiceScript.new()
	_check(rewards.level_reward(1) == 15, "level 1 reward is 15")
	_check(rewards.level_reward(10) == 60, "level 10 reward is 60")
	_check(rewards.hint_cost(1) == 0, "level 1 hints are free")
	_check(rewards.hint_cost(2) == 5, "paid hint cost is 5")
	_check(registry.all_games().size() == 22, "registry contains 22 games")
	_check(registry.games_in_category("Number").size() == 6, "number category contains 6 games")
	_check(registry.games_in_category("Word").size() == 10, "word category contains 10 games")
	_check(registry.games_in_category("Mystery").size() == 5, "mystery category contains 5 games")
	_check(registry.games_in_category("Arcade").size() == 1, "arcade category contains 1 game")
	_check(registry.playable_games().size() == 22, "all 22 games are playable")
	_check(registry.playable_count("Number") == 6, "all six number games are playable")
	_check(registry.playable_count("Word") == 10, "all ten word games are playable")
	_check(registry.playable_count("Mystery") == 5, "all five mystery games are playable")
	_check(registry.playable_count("Arcade") == 1, "the arcade game is playable")
	_check(GameplayRules.math_swipe_target(1) == 3 and GameplayRules.math_swipe_target(10) == 8, "Math Swipe target formula matches React")
	_check(GameplayRules.jump_path_length(3) == 20, "Unicorn Jump path length matches React")
	_check(GameplayRules.jump_max(2) == 3 and GameplayRules.jump_max(3) == 4 and GameplayRules.jump_max(6) == 6, "Unicorn Jump bands match React")
	_check(GameplayRules.jump_negative_max(14) == 0 and GameplayRules.jump_negative_max(15) == 2 and GameplayRules.jump_negative_max(25) == 5, "Unicorn Jump trick bands match React")
	_check(GameplayRules.sliding_length(5) == 15 and GameplayRules.sliding_length(6) == 20, "Sliding Window track length matches React")
	_check(GameplayRules.sliding_bounds(6) == Vector2i(-100, 100), "Sliding Window late number range matches React")
	_check(GameplayRules.sliding_window(1) == 3 and GameplayRules.sliding_window(6) == 5, "Sliding Window size formula matches React")
	_check(GameplayRules.rival_move_ms(1) == 2500 and GameplayRules.rival_move_ms(20) == 1000, "Sliding Window rival speed floor matches React")
	_check(GameplayRules.galaxy_target(1) == 10 and GameplayRules.galaxy_target(5) == 20, "Galaxy target formula matches React")
	_check(GameplayRules.galaxy_fire_ms(20) == 120 and GameplayRules.galaxy_spawn_ms(20) == 600, "Galaxy timing floors match React")
	_check(GameplayRules.mathtris_drop_ms(1) == 950 and GameplayRules.mathtris_drop_ms(50, 99, 99) == 90, "Mathtris drop curve and floor match React")
	_check(GameplayRules.mathtris_concurrent(0, 1) == 1 and GameplayRules.mathtris_concurrent(70, 1) == 3 and GameplayRules.mathtris_concurrent(150, 12) == 5, "Mathtris concurrency curve matches React")
	_check(GameplayRules.mathtris_allowed(10) == ["1", "2", "+", "="], "Mathtris basics token set matches React")
	_check("3" in GameplayRules.mathtris_allowed(11) and "4" in GameplayRules.mathtris_allowed(13) and "5" in GameplayRules.mathtris_allowed(16), "Mathtris digit unlocks match React")
	_check("-" not in GameplayRules.mathtris_allowed(23) and "-" in GameplayRules.mathtris_allowed(24), "Mathtris subtraction unlock matches React")
	_check(GameplayRules.equation_valid(["1", "+", "1", "=", "2"]), "Mathtris accepts forward equations")
	_check(GameplayRules.equation_valid(["2", "=", "1", "+", "1"]), "Mathtris accepts reverse equations")
	_check(not GameplayRules.equation_valid(["2", "+", "2", "=", "5"]), "Mathtris rejects invalid equations")
	var defaults: Dictionary = saves.default_state()
	_check(defaults["player"]["coins"] == 1000, "new players start with 1000 coins")
	_check(defaults["owned_companions"] == ["sparkle"], "new players own Sparkle")
	_check(defaults["settings"]["reduced_motion"] == false, "reduced motion defaults off")
	_check(_validate_sparkle_import(), "Sparkle GLB exposes required runtime pivots and meshes")
	_check(WordRules.target_for_level(1) == 4, "word target formula starts at four rounds")
	_check(WordRules.target_for_level(5) == 9, "word target formula scales at level five")
	_check(WordRules.target_for_level(20) == 12, "word target formula caps at twelve")
	_check(WordRules.caption_target(20) == 4, "Caption Quest caps at four scenes")
	_check(WordRules.odd_one_out_target(3) == 6, "Odd One Out caps at six cases")
	_check(WordRules.selection_window(20, 1) == Vector2i(0, 4), "difficulty window begins with four easy records")
	_check(WordRules.selection_window(20, 10) == Vector2i(6, 15), "difficulty window slides with level and round")
	_check(WordRules.words_for_level(3).size() == 30, "easy word pool is active through level three")
	_check(WordRules.words_for_level(4).size() == 32, "medium word pool begins at level four")
	_check(WordRules.words_for_level(9).size() == 27, "hard word pool begins at level nine")
	_check(WordRules.words_for_level(15).size() == 21, "expert word pool begins at level fifteen")
	_check(WordRules.sight_flash_ms(1) == 2120, "Sight Spark level-one flash duration matches React")
	_check(WordRules.sight_flash_ms(18) == 800, "Sight Spark flash duration floors at 800 ms")
	_check(is_equal_approx(WordRules.blast_speed(1), 0.135), "Unicorn Blast speed formula matches level one")
	_check(WordRules.blast_spawn_ms(1) == 2680, "Unicorn Blast spawn formula matches level one")
	_check(WordRules.blast_spawn_ms(20) == 1400, "Unicorn Blast spawn interval floors at 1400 ms")
	_check(WordRules.is_chain_link("cat", "top"), "Chain Link accepts the last-to-first letter rule")
	_check(not WordRules.is_chain_link("cat", "dog"), "Chain Link rejects a mismatched first letter")
	var word_data := WordRules.data()
	_check(word_data.get("sentence_build", []).size() == 20, "all Sentence Sprout records were extracted")
	_check(word_data.get("missing_word", []).size() == 18, "all Missing Magic records were extracted")
	_check(word_data.get("prefix_mix", []).size() == 18, "all Prefix Potion records were extracted")
	_check(word_data.get("caption_scenes", []).size() == 14, "all Caption Quest records were extracted")
	_check(word_data.get("opposite_challenges", []).size() == 22, "all Opposite Orbit records were extracted")
	_check(word_data.get("scramble_puzzles", []).size() == 27, "all Scramble Spell records were extracted")
	_check(word_data.get("odd_one_out", []).size() == 14, "all Odd One Out records were extracted")
	_check(word_data.get("size_lineups", []).size() == 16, "all Size Line-Up records were extracted")
	_check(word_data.get("chain_links", []).size() == 17, "all Chain Link records were extracted")
	_check(WordRules.cash_target_bounds(1) == Vector2i(1, 20), "Cash Counter early target band matches React")
	_check(WordRules.cash_target_bounds(4) == Vector2i(20, 99), "Cash Counter middle target band matches React")
	_check(WordRules.cash_target_bounds(9) == Vector2i(100, 999), "Cash Counter late target band matches React")
	rewards.free()
	registry.free()
	saves.free()
	if failures.is_empty():
		print("GODOT_PARITY_TESTS_OK: %d checks passed" % check_count)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	check_count += 1
	if not condition:
		failures.append(message)


func _validate_sparkle_import() -> bool:
	var scene = load("res://assets/characters/sparkle/sparkle_v1.glb")
	if scene == null or not scene is PackedScene:
		return false
	var instance: Node = scene.instantiate()
	var required := ["SparkleRoot", "Pivot_Body", "Pivot_Head", "Pivot_Horn", "Pivot_Tail", "Pivot_FrontLeg_L", "Pivot_FrontLeg_R", "Pivot_HindLeg_L", "Pivot_HindLeg_R"]
	for node_name in required:
		if instance.find_child(node_name, true, false) == null:
			instance.free()
			return false
	var mesh_count := _count_meshes(instance)
	instance.free()
	return mesh_count >= 20


func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count
