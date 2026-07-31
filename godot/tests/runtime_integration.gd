extends Node

const Rules = preload("res://scripts/games/word_game_rules.gd")
const WORD_SCENE = preload("res://scenes/games/word_game.tscn")
const CASH_SCENE = preload("res://scenes/games/cash_counter.tscn")
const MAIN_SCENE = preload("res://scenes/main.tscn")

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
