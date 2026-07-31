extends Node

const Rules = preload("res://scripts/games/word_game_rules.gd")
const WORD_SCENE = preload("res://scenes/games/word_game.tscn")
const CASH_SCENE = preload("res://scenes/games/cash_counter.tscn")
const MAIN_SCENE = preload("res://scenes/main.tscn")
const MATH_SWIPE_SCENE = preload("res://scenes/games/math_swipe.tscn")
const JUMP_SCENE = preload("res://scenes/games/unicorn_jump.tscn")
const SLIDING_SCENE = preload("res://scenes/games/sliding_window.tscn")
const MATHTRIS_SCENE = preload("res://scenes/games/mathtris.tscn")
const GALAXY_SCENE = preload("res://scenes/games/galaxy_unicorn.tscn")

const WORD_GAME_IDS := [
	"unicorn_blast", "sentence_sprout", "missing_magic", "sight_spark",
	"prefix_potion", "vowel_vines", "letter_lift", "syllable_stamp",
	"caption_quest", "opposite_orbit", "scramble_spell", "odd_one_out",
	"size_line_up", "chain_link",
]

var failures: Array[String] = []
var check_count := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var original_game := AppState.selected_game_id
	var original_category := AppState.selected_category
	for game_id in WORD_GAME_IDS:
		AppState.selected_game_id = game_id
		var game = WORD_SCENE.instantiate()
		add_child(game)
		await get_tree().process_frame
		_check(game.game_id == game_id, "%s selects the requested shared-game mode" % game_id)
		_check(game.active, "%s begins in an active play state" % game_id)
		_check(game.target_rounds > 0, "%s has a positive round target" % game_id)
		_exercise_first_move(game_id, game)
		remove_child(game)
		game.free()
	var cash = CASH_SCENE.instantiate()
	add_child(cash)
	await get_tree().process_frame
	_check(cash.active, "Cash Counter begins in an active play state")
	cash.target = 20
	cash.total = 0
	cash.call("_add_bill", 5)
	_check(cash.total == 5 and cash.active, "Cash Counter accepts a non-overshooting bill")
	remove_child(cash)
	cash.free()
	var math_swipe = MATH_SWIPE_SCENE.instantiate()
	add_child(math_swipe)
	await get_tree().process_frame
	_check(math_swipe.active and math_swipe.cards.size() == 2, "Math Swipe launches with two answer cards")
	var correct_card: Button
	for card in math_swipe.cards:
		if bool(card.get_meta("correct")):
			correct_card = card
			break
	math_swipe.call("_submit", correct_card)
	_check(math_swipe.completed == 1, "Math Swipe accepts the correct card")
	remove_child(math_swipe)
	math_swipe.free()
	var jump = JUMP_SCENE.instantiate()
	add_child(jump)
	await get_tree().process_frame
	_check(jump.active and jump.level_data.size() == 10, "Unicorn Jump launches its level-one ten-node trail")
	var landing: int = jump.level_data[0]
	jump.call("_choose_node", landing)
	_check(jump.current_index == landing and jump.active, "Unicorn Jump accepts the exact indexed landing")
	remove_child(jump)
	jump.free()
	var sliding = SLIDING_SCENE.instantiate()
	add_child(sliding)
	await get_tree().process_frame
	_check(sliding.active and sliding.window_size == 3, "Sliding Window launches its level-one race")
	var max_index := 0
	for index in sliding.window_size:
		if sliding.level_data[index] > sliding.level_data[max_index]:
			max_index = index
	sliding.call("_choose", max_index)
	_check(sliding.window_pos == 1 and sliding.active, "Sliding Window advances after selecting the maximum")
	remove_child(sliding)
	sliding.free()
	var mathtris = MATHTRIS_SCENE.instantiate()
	add_child(mathtris)
	await get_tree().process_frame
	_check(mathtris.active and mathtris.board.size() == 14 and mathtris.board[0].size() == 8, "Mathtris launches an 8 by 14 live board")
	_check(not mathtris.falling.is_empty(), "Mathtris launches an initial falling wave")
	remove_child(mathtris)
	mathtris.free()
	var galaxy = GALAXY_SCENE.instantiate()
	add_child(galaxy)
	await get_tree().process_frame
	_check(galaxy.active and galaxy.target_kills == 10 and galaxy.lives == 3, "Galaxy Unicorn launches with the React target and lives")
	_check(not galaxy.bullets.is_empty(), "Galaxy Unicorn auto-fires its opening bolt")
	remove_child(galaxy)
	galaxy.free()
	var shell = MAIN_SCENE.instantiate()
	add_child(shell)
	await get_tree().process_frame
	_check(shell.get_child_count() >= 2, "navigation shell builds its full-screen page")
	remove_child(shell)
	shell.free()
	AppState.selected_game_id = original_game
	AppState.selected_category = original_category
	if failures.is_empty():
		print("GODOT_RUNTIME_INTEGRATION_OK: %d checks passed" % check_count)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _exercise_first_move(game_id: String, game: Node) -> void:
	if game_id in ["sentence_sprout", "syllable_stamp", "scramble_spell", "size_line_up"]:
		var expected = game.sequence[0]
		var index: int = game.pool.find(expected)
		game.call("_choose_sequence", {"value": expected, "index": index})
		_check(game.picked.size() == 1, "%s accepts the first ordered item" % game_id)
		return
	if game_id == "letter_lift":
		game.call("_handle_letter_input", game.expected_word.left(1))
		_check(game.picked.size() == 1, "Letter Lift accepts the next exact letter")
		return
	if game_id == "sight_spark":
		game.call("_finish_sight_flash")
		game.call("_on_text_submitted", game.expected_word)
		_check(game.round_index == 1, "Sight Spark accepts the memorized word")
		return
	if game_id == "unicorn_blast":
		_check(not game.blast_words.is_empty(), "Unicorn Blast spawns an initial word")
		var word := str(game.blast_words[0]["text"])
		game.call("_handle_blast_input", word)
		_check(game.round_index == 1, "Unicorn Blast destroys an exactly typed word")
		return
	var answer := ""
	match game_id:
		"vowel_vines":
			for button in game.options.get_children():
				if str(button.text).left(1).to_lower() == str(game.current["vowel"]):
					answer = button.text
					break
		"odd_one_out":
			answer = str(game.current["odd"])
		"chain_link":
			for option in game.current["options"]:
				if Rules.is_chain_link(str(game.current["start"]), str(option)):
					answer = str(option)
					break
		_:
			answer = str(game.current.get("answer", ""))
	_check(not answer.is_empty(), "%s exposes a valid answer" % game_id)
	if game_id in ["caption_quest", "odd_one_out"]:
		var wrong := _find_wrong_choice(game_id, game, answer)
		game.call("_choose", wrong)
		_check(game.lives == 2 and game.active, "%s consumes one life without immediate failure" % game_id)
	game.call("_choose", answer)
	_check(game.round_index == 1, "%s accepts its exact correct choice" % game_id)


func _find_wrong_choice(game_id: String, game: Node, answer: String) -> String:
	if game_id == "caption_quest":
		for option in game.current["options"]:
			if str(option) != answer:
				return str(option)
	else:
		for item in game.current["items"]:
			if str(item["label"]) != answer:
				return str(item["label"])
	return "__wrong__"


func _check(condition: bool, message: String) -> void:
	check_count += 1
	if not condition:
		failures.append(message)
