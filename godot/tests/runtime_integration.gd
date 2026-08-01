extends Node

const Rules = preload("res://scripts/games/word_game_rules.gd")
const WORD_SCENE = preload("res://scenes/games/word_game.tscn")
const CASH_SCENE = preload("res://scenes/games/cash_counter.tscn")
const COIN_SCENE = preload("res://scenes/games/coin_count.tscn")
const RHYME_SCENE = preload("res://scenes/games/rhyme_rally.tscn")
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
		_check(_ui_is_accessible(game), "%s meets readable text, contrast, and touch-target minimums" % game_id)
		_check(game.game_id == game_id, "%s selects the requested shared-game mode" % game_id)
		_check(game.active, "%s begins in an active play state" % game_id)
		_check(game.target_rounds > 0, "%s has a positive round target" % game_id)
		_exercise_first_move(game_id, game)
		remove_child(game)
		game.free()
	var cash = CASH_SCENE.instantiate()
	add_child(cash)
	await get_tree().process_frame
	_check(_ui_is_accessible(cash), "Cash Counter meets readable text, contrast, and touch-target minimums")
	_check(cash.active, "Cash Counter begins in an active play state")
	cash.target = 20
	cash.total = 0
	cash.call("_add_bill", 5)
	_check(cash.total == 5 and cash.active, "Cash Counter accepts a non-overshooting bill")
	remove_child(cash)
	cash.free()
	var coin_count = COIN_SCENE.instantiate()
	add_child(coin_count)
	await get_tree().process_frame
	_check(coin_count.target > 0, "Coin Count begins with a positive target")
	_check(_ui_is_accessible(coin_count), "Coin Count meets readable text, contrast, and touch-target minimums")
	remove_child(coin_count)
	coin_count.free()
	var rhyme = RHYME_SCENE.instantiate()
	add_child(rhyme)
	await get_tree().process_frame
	_check(rhyme.target_rounds > 0 and not rhyme.challenge.is_empty(), "Rhyme Rally begins with a playable challenge")
	_check(_ui_is_accessible(rhyme), "Rhyme Rally meets readable text, contrast, and touch-target minimums")
	remove_child(rhyme)
	rhyme.free()
	var math_swipe = MATH_SWIPE_SCENE.instantiate()
	add_child(math_swipe)
	await get_tree().process_frame
	_check(_ui_is_accessible(math_swipe), "Math Swipe meets readable text, contrast, and touch-target minimums")
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
	_check(_ui_is_accessible(jump), "Unicorn Jump meets readable text, contrast, and touch-target minimums")
	_check(jump.active and jump.level_data.size() == 10, "Unicorn Jump launches its level-one ten-node trail")
	var landing: int = jump.level_data[0]
	jump.call("_choose_node", landing)
	_check(jump.current_index == landing and jump.active, "Unicorn Jump accepts the exact indexed landing")
	remove_child(jump)
	jump.free()
	var sliding = SLIDING_SCENE.instantiate()
	add_child(sliding)
	await get_tree().process_frame
	_check(_ui_is_accessible(sliding), "Sliding Window meets readable text, contrast, and touch-target minimums")
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
	_check(_ui_is_accessible(mathtris), "Mathtris meets readable text, contrast, and touch-target minimums")
	_check(mathtris.active and mathtris.board.size() == 14 and mathtris.board[0].size() == 8, "Mathtris launches an 8 by 14 live board")
	_check(not mathtris.falling.is_empty(), "Mathtris launches an initial falling wave")
	remove_child(mathtris)
	mathtris.free()
	var galaxy = GALAXY_SCENE.instantiate()
	add_child(galaxy)
	await get_tree().process_frame
	_check(_ui_is_accessible(galaxy), "Galaxy Unicorn meets readable text, contrast, and touch-target minimums")
	_check(galaxy.active and galaxy.target_kills == 10 and galaxy.lives == 3, "Galaxy Unicorn launches with the React target and lives")
	_check(is_equal_approx(galaxy.player_x, 0.5), "Galaxy Unicorn centers the player for its opening wave")
	galaxy.call("_spawn_enemy", false)
	_check(float(galaxy.enemies[0]["speed"]) <= 0.000125, "Galaxy Unicorn's opening enemies use the gentle level-one speed curve")
	galaxy.enemies.clear()
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
	_check(_ui_is_accessible(market), "companion Marketplace meets readable text, contrast, and touch-target minimums")
	_check(market.tab == "companions" and market.content.get_child_count() > 0, "Marketplace launches its companion catalog")
	_check(market.find_children("CompanionModelPreview", "RoomItemPreview3D", true, false).size() == 6, "Marketplace companion cards use the six live 3D variants")
	market.call("_show_decor")
	await get_tree().process_frame
	_check(_ui_is_accessible(market), "decor Marketplace meets readable text, contrast, and touch-target minimums")
	_check(market.tab == "decor" and market.content.get_child_count() > 100, "Marketplace exposes the full decor catalog")
	_check(market.find_children("CatalogModelPreview", "RoomItemPreview3D", true, false).size() == MetaCatalog.furniture().size(), "every marketplace decor record uses a modeled object preview")
	remove_child(market)
	market.free()
	var alley = ALLEY_SCENE.instantiate()
	add_child(alley)
	await get_tree().process_frame
	_check(_ui_is_accessible(alley), "Unicorn Alley meets readable text, contrast, and touch-target minimums")
	_check(is_instance_valid(alley.message_label) and alley.house_buttons.size() == 6, "Unicorn Alley launches all six selectable houses")
	_check(alley.map_rect.texture.resource_path.ends_with("unicorn_alley_production_v1.png"), "Unicorn Alley uses the new unified six-door pastel map")
	var door_button: Button = alley.house_buttons.get("sparkle")
	_check(door_button.custom_minimum_size.y > door_button.custom_minimum_size.x, "Alley house targets use tall door-shaped controls")
	_check(door_button.text.is_empty() and door_button.has_node("DoorStateArt"), "Alley doors use environmental light cues without floating label shapes")
	remove_child(alley)
	alley.free()
	AppState.active_room_companion = "sparkle"
	var room = ROOM_SCENE.instantiate()
	add_child(room)
	await get_tree().process_frame
	_check(_ui_is_accessible(room), "room editor meets readable text, contrast, and touch-target minimums")
	_check(room.companion_id == "sparkle" and is_instance_valid(room.room_canvas), "Sparkle's room editor launches")
	_check(room.grid_snap, "room editor starts with eight-percent grid snapping enabled")
	var companion_button: Button = room.item_buttons.get("room_companion_sparkle")
	var companion_preview = companion_button.get_node_or_null("RoomItemPreview3D") if is_instance_valid(companion_button) else null
	_check(is_instance_valid(companion_preview) and companion_preview.uses_character_model and companion_preview.mesh_count >= 20, "rooms automatically present the live approved 3D unicorn model")
	var idle_animator = companion_preview.find_child("IdleAnimator", true, false) if is_instance_valid(companion_preview) else null
	_check(is_instance_valid(idle_animator) and is_instance_valid(idle_animator.timer) and not idle_animator.timer.is_stopped(), "live unicorn previews schedule randomized idle animations")
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
	var lamp_preview = lamp_button.get_node_or_null("RoomItemPreview3D") if is_instance_valid(lamp_button) else null
	_check(lamp_button.text.is_empty() and lamp_button.tooltip_text == "Lava Lamp" and is_instance_valid(lamp_preview) and lamp_preview.mesh_count > 0 and not lamp_preview.uses_character_model, "room decor uses a modeled 3D object instead of an icon glyph")
	_check(is_instance_valid(touch_room.selection_toolbar) and touch_room.selection_toolbar.get_child_count() == 6, "selecting decor opens the original six-action contextual toolbar")
	var room_drag := InputEventScreenDrag.new()
	room_drag.position = touch_room.room_canvas.global_position + Vector2(touch_room.room_canvas.size.x * 0.82, touch_room.room_canvas.size.y * 0.66)
	touch_room.call("_input", room_drag)
	var room_release := InputEventScreenTouch.new()
	room_release.pressed = false
	room_release.position = room_drag.position
	touch_room.call("_input", room_release)
	var moved_items := AppState.room_items("rainbow")
	var moved_lamp := moved_items.filter(func(item: Dictionary) -> bool: return str(item.get("instance_id", "")) == "test_lamp")
	_check(moved_lamp.size() == 1 and is_equal_approx(float(moved_lamp[0]["x"]), 80.0) and is_equal_approx(float(moved_lamp[0]["y"]), 64.0), "room decor follows and commits an Android drag outside its button")
	touch_room.call("_show_bag")
	await get_tree().process_frame
	var empty_bag_message := touch_room.bag_grid.find_child("EmptyBagMessage", true, false) as Label
	_check(is_instance_valid(touch_room.bag_overlay) and touch_room.bag_grid.columns == 1 and is_instance_valid(empty_bag_message) and empty_bag_message.custom_minimum_size.x >= 600.0, "empty furniture bag uses one full-width message instead of a one-character column")
	_check(not touch_room.bag_button.visible and not touch_room.status_label.visible, "open furniture bag hides the underlying floating button and room status")
	_check(_ui_is_accessible(touch_room.bag_overlay), "Furniture Bag meets readable text, contrast, and touch-target minimums")
	touch_room.call("_close_bag")
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
	_check(_ui_is_accessible(shell), "navigation shell meets readable text, contrast, and touch-target minimums")
	var centered_slot := shell.find_child("TrueCenterHeaderSlot", true, false) as Control
	var home_sign := shell.find_child("HomeTitleSign", true, false) as TextureRect
	var alley_sign_button := shell.find_child("UnicornAlleyStreetSignButton", true, false) as Button
	var expected_center: float = shell.global_position.x + shell.size.x * 0.5
	var actual_center: float = centered_slot.global_position.x + centered_slot.size.x * 0.5 if is_instance_valid(centered_slot) else -1.0
	_check(is_instance_valid(centered_slot) and absf(actual_center - expected_center) <= 1.0, "navigation headers center titles on the physical screen independently of side controls (actual %.2f, expected %.2f)" % [actual_center, expected_center])
	_check(is_instance_valid(home_sign) and home_sign.texture.resource_path.ends_with("title_sign_option3_compact_v1.png"), "home meadow uses the approved illustrated Unicorn Arcade sign")
	_check(is_instance_valid(alley_sign_button) and alley_sign_button.has_node("StreetSignArt") and alley_sign_button.text == "UNICORN ALLEY", "home uses an accessible illustrated Unicorn Alley street-sign action")
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


func _ui_is_accessible(root: Node) -> bool:
	var issues: Array[String] = []
	_collect_ui_issues(root, issues)
	if not issues.is_empty():
		push_warning("UI accessibility issues: %s" % "; ".join(issues.slice(0, 8)))
	return issues.is_empty()


func _collect_ui_issues(node: Node, issues: Array[String]) -> void:
	if node is Control and (node as Control).is_visible_in_tree():
		var control := node as Control
		if control is Label and not (control as Label).text.strip_edges().is_empty():
			if control.get_theme_font_size("font_size") < 19:
				issues.append("small label %s" % control.name)
			if control.get_theme_constant("outline_size") < 2:
				issues.append("low-contrast label %s" % control.name)
		if control is BaseButton:
			if control.custom_minimum_size.y < 56.0:
				issues.append("short touch target %s" % control.name)
			if control.get_theme_font_size("font_size") < 18:
				issues.append("small button text %s" % control.name)
		if control is LineEdit or control is TextEdit:
			if control.custom_minimum_size.y < 56.0 or control.get_theme_font_size("font_size") < 19:
				issues.append("small text input %s" % control.name)
	for child in node.get_children():
		_collect_ui_issues(child, issues)
