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
const MARKET_SCENE = preload("res://scenes/meta/marketplace.tscn")
const ALLEY_SCENE = preload("res://scenes/meta/unicorn_alley.tscn")
const ROOM_SCENE = preload("res://scenes/meta/room_editor.tscn")

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
	_check(is_equal_approx(galaxy.player_x, 0.5), "Galaxy Unicorn centers the player for its opening wave")
	galaxy.size = Vector2(720, 1280)
	var galaxy_drag := InputEventScreenDrag.new()
	galaxy_drag.position = Vector2(576, 900)
	galaxy.call("_input", galaxy_drag)
	_check(is_equal_approx(galaxy.player_x, 0.8), "Galaxy Unicorn responds to Android screen dragging")
	galaxy.call("_process", 0.016)
	_check(galaxy.fire_cooldown > 0.0 and galaxy.bolt_flashes.size() > 0, "Galaxy Unicorn auto-fires a visible rainbow bolt")
	_check(galaxy.call("_segment_hits_circle", Vector2(576, 1000), Vector2(576, 300), Vector2(576, 650), 26.0), "Galaxy Unicorn fast bolts use swept collision instead of tunneling through targets")
	remove_child(galaxy)
	galaxy.free()
	var market = MARKET_SCENE.instantiate()
	add_child(market)
	await get_tree().process_frame
	_check(market.tab == "companions" and market.content.get_child_count() > 0, "Marketplace launches its companion catalog")
	market.call("_show_decor")
	await get_tree().process_frame
	_check(market.tab == "decor" and market.content.get_child_count() > 100, "Marketplace exposes the full decor catalog")
	remove_child(market)
	market.free()
	var alley = ALLEY_SCENE.instantiate()
	add_child(alley)
	await get_tree().process_frame
	_check(is_instance_valid(alley.message_label) and alley.house_buttons.size() == 6, "Unicorn Alley launches all six selectable houses")
	remove_child(alley)
	alley.free()
	AppState.active_room_companion = "sparkle"
	var room = ROOM_SCENE.instantiate()
	add_child(room)
	await get_tree().process_frame
	_check(room.companion_id == "sparkle" and is_instance_valid(room.room_canvas), "Sparkle's room editor launches")
	_check(room.grid_snap, "room editor starts with eight-percent grid snapping enabled")
	remove_child(room)
	room.free()
	var original_data := AppState.data.duplicate(true)
	AppState.data = SaveService.default_state()
	AppState.data["player"]["name"] = "Runtime Test"
	_check(AppState.buy_companion("rainbow") and AppState.coins() == 500, "companion adoption deducts the exact catalog price")
	_check(AppState.equip_companion("rainbow") and AppState.equipped_companion() == "rainbow", "owned companions can be equipped")
	_check(AppState.buy_furniture("lamp") and AppState.coins() == 350, "decor purchase adds one catalog item")
	var placement := {"instance_id": "test_lamp", "item_id": "lamp", "x": 48.0, "y": 48.0, "rotation": 0, "scale": 1.0, "z_index": 1}
	_check(AppState.place_room_item("rainbow", placement) and AppState.available_count("lamp") == 0, "room placement consumes one available inventory item")
	_check(not AppState.sell_furniture("lamp"), "placed decor cannot be sold")
	AppState.active_room_companion = "rainbow"
	var touch_room = ROOM_SCENE.instantiate()
	add_child(touch_room)
	await get_tree().process_frame
	var lamp_button: Button = touch_room.item_buttons.get("test_lamp")
	var room_press := InputEventScreenTouch.new()
	room_press.pressed = true
	touch_room.call("_item_input", room_press, "test_lamp", lamp_button)
	var room_drag := InputEventScreenDrag.new()
	room_drag.position = touch_room.room_canvas.global_position + Vector2(touch_room.room_canvas.size.x * 0.82, touch_room.room_canvas.size.y * 0.66)
	touch_room.call("_input", room_drag)
	var room_release := InputEventScreenTouch.new()
	room_release.pressed = false
	room_release.position = room_drag.position
	touch_room.call("_input", room_release)
	var moved_items := AppState.room_items("rainbow")
	_check(moved_items.size() == 1 and is_equal_approx(float(moved_items[0]["x"]), 80.0) and is_equal_approx(float(moved_items[0]["y"]), 64.0), "room decor follows and commits an Android drag outside its button")
	remove_child(touch_room)
	touch_room.free()
	_check(AppState.remove_room_item("rainbow", "test_lamp") and AppState.available_count("lamp") == 1, "removed decor returns to the shared bag")
	_check(AppState.sell_furniture("lamp") and AppState.coins() == 425, "unused decor sells for the floored fifty-percent refund")
	AppState.data = original_data
	SaveService.save_state(AppState.data)
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
