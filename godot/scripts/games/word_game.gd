extends ArcadeGameController

const Rules = preload("res://scripts/games/word_game_rules.gd")
const RoundCatalog = preload("res://scripts/games/word_round_catalog.gd")
const WordChoiceStrategy = preload("res://scripts/games/word_choice_strategy.gd")
const WordSequenceStrategy = preload("res://scripts/games/word_sequence_strategy.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const NAVY := Color("08112f")
const PANEL := Color("14214a")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")

var game_id := ""
var game_info: Dictionary = {}
var level := 1
var round_index := 0
var target_rounds := 0
var lives := 0
var started_ms := 0
var active := false
var hint_visible := false
var current: Dictionary = {}
var sequence: Array = []
var pool: Array = []
var picked: Array = []
var expected_word := ""
var phase := "choice"
var rng := RandomNumberGenerator.new()
var blast_words: Array = []
var blast_source_exhausted := false
var spawn_elapsed := 0.0
var suppress_text_event := false
var choice_strategy := WordChoiceStrategy.new()
var sequence_strategy := WordSequenceStrategy.new()

var title_label: Label
var coin_label: Label
var level_label: Label
var timer_label: Label
var progress_label: Label
var lives_label: Label
var instruction_label: Label
var prompt_label: Label
var secondary_label: Label
var message_label: Label
var options: GridContainer
var input_line: LineEdit
var play_area: Control
var hint_button: Button
var retry_button: Button
var flash_timer: Timer


func _ready() -> void:
	rng.randomize()
	game_id = AppState.selected_game_id
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--game-id="):
			game_id = argument.trim_prefix("--game-id=")
	if game_id.is_empty():
		game_id = "sentence_sprout"
	game_info = GameRegistry.get_game(game_id)
	level = AppState.current_level(game_id)
	_build_ui()
	_start_level()


func _process(delta: float) -> void:
	super(delta)
	if active:
		timer_label.text = "%.1fs" % ((Time.get_ticks_msec() - started_ms) / 1000.0)
	if active and game_id == "unicorn_blast":
		_update_blast(delta * CompanionAbilityService.time_scale())


func _start_level() -> void:
	_start_level_with_lifecycle(true)


func _start_level_with_lifecycle(begin_run: bool) -> void:
	_clear_blast_words()
	level = AppState.current_level(game_id) if level < 1 else level
	if begin_run:
		level_run.begin(game_id, level)
		level = level_run.level
	else:
		level = level_run.level
	round_index = 0
	target_rounds = Rules.target_for_level(level)
	if game_id == "caption_quest":
		target_rounds = Rules.caption_target(level)
	elif game_id == "odd_one_out":
		target_rounds = Rules.odd_one_out_target(level)
	lives = 3 if game_id in ["caption_quest", "odd_one_out", "unicorn_blast"] else 0
	started_ms = level_run.started_ms
	active = level_run.active
	blast_source_exhausted = false
	hint_visible = level == 1
	phase = "choice"
	level_label.text = "LEVEL %d" % level
	retry_button.hide()
	hint_button.disabled = false
	hint_button.text = "FREE HINT" if level == 1 else "HINT  ★5"
	message_label.text = ""
	_load_round()


func _load_round() -> void:
	_clear_options()
	_hide_special_controls()
	picked.clear()
	sequence.clear()
	pool.clear()
	secondary_label.text = ""
	progress_label.text = "%d / %d" % [round_index, target_rounds]
	lives_label.text = "♥ %d" % lives if lives > 0 else ""
	if _load_choice_round():
		return
	if _load_sequence_round():
		return
	match game_id:
		"sight_spark":
			_load_sight_spark()
		"letter_lift":
			_load_letter_lift()
		"unicorn_blast":
			_load_unicorn_blast()
		_:
			_fail("This game is not configured.")


func _load_choice_round() -> bool:
	var choice_round := choice_strategy.begin_round(_strategy_context())
	if not bool(choice_round.get("handled", false)):
		return false
	if not bool(choice_round.get("ok", false)):
		_fail("This word round needs a refresh. Try again soon.")
		return true
	_apply_choice_round(choice_round)
	return true


func _apply_choice_round(choice_round: Dictionary) -> void:
	current = choice_round.get("current", {})
	instruction_label.text = str(choice_round.get("instruction", ""))
	prompt_label.text = str(choice_round.get("prompt", ""))
	_render_choice_specs(choice_round.get("options", []))


func _load_sequence_round() -> bool:
	var sequence_round := sequence_strategy.begin_round(_strategy_context())
	if not bool(sequence_round.get("handled", false)):
		return false
	if not bool(sequence_round.get("ok", false)):
		_fail("This word round needs a refresh. Try again soon.")
		return true
	_apply_sequence_round(sequence_round)
	return true


func _apply_sequence_round(sequence_round: Dictionary) -> void:
	current = sequence_round.get("current", {})
	sequence = sequence_round.get("sequence", [])
	pool = sequence_round.get("pool", [])
	picked.clear()
	phase = str(sequence_round.get("phase", "choice"))
	instruction_label.text = str(sequence_round.get("instruction", ""))
	_render_sequence()


func _load_sequence(_key: String, _field: String, _instruction: String, _mode: String) -> void:
	_load_sequence_round()


func _load_sight_spark() -> void:
	var words := Rules.words_for_level(level)
	expected_word = RoundCatalog.word_for_round(words, level, round_index)
	if expected_word.is_empty():
		_fail("This word round needs a refresh. Try again soon.")
		return
	phase = "flash"
	instruction_label.text = "Remember this word"
	prompt_label.text = expected_word
	input_line.hide()
	flash_timer.wait_time = Rules.sight_flash_ms(level) / 1000.0
	flash_timer.start()


func _finish_sight_flash() -> void:
	if not active or game_id != "sight_spark":
		return
	phase = "type"
	instruction_label.text = "Type the word from memory"
	prompt_label.text = expected_word if hint_visible else "?"
	_show_text_input("What did you see?")


func _load_vowel_vines() -> void:
	_load_choice_round()


func _load_letter_lift() -> void:
	var words := Rules.words_for_level(level)
	expected_word = RoundCatalog.word_for_round(words, level, round_index)
	if expected_word.is_empty():
		_fail("This word round needs a refresh. Try again soon.")
		return
	phase = "letter"
	picked.clear()
	instruction_label.text = "Type each letter in order"
	_render_letter_lift()
	_show_text_input("Type letters…")


func _load_scramble() -> void:
	_load_sequence_round()


func _load_odd_one_out() -> void:
	_load_choice_round()


func _load_size_line_up() -> void:
	_load_sequence_round()


func _load_chain_link() -> void:
	_load_choice_round()


func _load_unicorn_blast() -> void:
	phase = "blast"
	instruction_label.text = "Type each falling word before it reaches the cannon"
	prompt_label.text = "UNICORN CANNON"
	play_area.show()
	_show_text_input("Type a falling word…")
	spawn_elapsed = 0.0
	_spawn_blast_word()


func _render_missing_magic() -> void:
	_apply_choice_hint(choice_strategy.hint(_strategy_context()))


func _render_choice_buttons(choices: Array) -> void:
	for choice in choices:
		_add_option(str(choice), choice)


func _render_choice_specs(specs: Array) -> void:
	for spec in specs:
		_add_option(str(spec.get("text", "")), spec.get("payload"))


func _render_sequence() -> void:
	_clear_options()
	var built: Array[String] = []
	for value in picked:
		built.append(str(value))
	if phase == "sentence":
		prompt_label.text = " ".join(built) if not built.is_empty() else "Build it!"
		secondary_label.text = "Next: %s" % sequence[picked.size()] if hint_visible and picked.size() < sequence.size() else ""
	elif phase == "syllable":
		prompt_label.text = current.get("word", "")
		secondary_label.text = "Stamped: %s" % "-".join(built)
	elif phase == "scramble":
		prompt_label.text = "".join(built).to_upper()
		secondary_label.text = "Next letter: %s" % sequence[picked.size()].to_upper() if hint_visible and picked.size() < sequence.size() else ""
	elif phase == "size":
		prompt_label.text = " → ".join(built) if not built.is_empty() else "Line them up!"
		secondary_label.text = "Next: %s" % sequence[picked.size()] if hint_visible and picked.size() < sequence.size() else ""
	for index in pool.size():
		_add_option(str(pool[index]), {"value": pool[index], "index": index})


func _render_letter_lift() -> void:
	var typed := "".join(picked)
	prompt_label.text = typed.to_upper() + "_".repeat(maxi(0, expected_word.length() - typed.length()))
	secondary_label.text = "Spell: %s" % expected_word.to_upper() if hint_visible else "Next letter: %s" % expected_word.substr(picked.size(), 1).to_upper()


func _choose(payload) -> void:
	if not active:
		return
	if payload is Dictionary:
		_choose_sequence(payload)
		return
	var choice_result := choice_strategy.submit(_strategy_context(), payload)
	match str(choice_result.get("outcome", "ignored")):
		"success":
			_successful_round()
			return
		"lost_life":
			_lost_life()
			return
		"failure":
			_fail(_fail_reason())
			return
	_fail(_fail_reason())


func _choose_sequence(payload: Dictionary) -> void:
	var sequence_result := sequence_strategy.submit(_strategy_context(), payload)
	match str(sequence_result.get("outcome", "ignored")):
		"failure":
			_fail(_fail_reason())
			return
		"continue", "success":
			picked = sequence_result.get("picked", [])
			pool = sequence_result.get("pool", [])
			hint_visible = false
			if sequence_result.get("outcome") == "success":
				_successful_round()
			else:
				_render_sequence()
			return
	_fail(_fail_reason())


func _on_text_submitted(value: String) -> void:
	if not active or game_id != "sight_spark" or phase != "type":
		return
	if value.strip_edges().to_lower() == expected_word:
		_successful_round()
	else:
		_fail(_fail_reason())


func _on_text_changed(value: String) -> void:
	if suppress_text_event or not active:
		return
	if game_id == "letter_lift":
		_handle_letter_input(value)
	elif game_id == "unicorn_blast":
		_handle_blast_input(value)


func _handle_letter_input(value: String) -> void:
	var typed := "".join(picked)
	if value.length() <= typed.length():
		_set_input_text(typed)
		return
	var character := value.substr(typed.length(), 1).to_lower()
	if character == expected_word.substr(picked.size(), 1):
		picked.append(character)
		hint_visible = false
		_set_input_text("".join(picked))
		_render_letter_lift()
		if picked.size() >= expected_word.length():
			_successful_round()
	else:
		_fail(_fail_reason())


func _handle_blast_input(value: String) -> void:
	var candidate := value.strip_edges().to_lower()
	for index in blast_words.size():
		if blast_words[index].get("text", "") == candidate:
			_remove_blast_word(index)
			_set_input_text("")
			message_label.text = "BLAST!"
			_successful_round(false)
			return


func _successful_round(load_next := true) -> void:
	hint_visible = false
	round_index += 1
	if round_index >= target_rounds:
		_complete_level()
	elif load_next:
		_load_round()
	else:
		progress_label.text = "%d / %d" % [round_index, target_rounds]


func _lost_life() -> void:
	lives -= 1
	lives_label.text = "♥ %d" % maxi(0, lives)
	message_label.text = "Not quite—%d hearts left." % maxi(0, lives)
	if lives <= 0:
		_fail(_fail_reason())


func _complete_level() -> void:
	var reward := level_run.complete()
	active = level_run.active
	flash_timer.stop()
	message_label.text = "Level complete! +%d coins" % reward
	coin_label.text = "★ %d" % AppState.coins()
	retry_button.text = "NEXT LEVEL"
	retry_button.show()
	hint_button.disabled = true
	input_line.editable = false
	level = level_run.next_level


func _fail(reason: String) -> void:
	level_run.fail(reason)
	active = level_run.active
	flash_timer.stop()
	message_label.text = reason
	retry_button.text = "RETRY"
	retry_button.show()
	hint_button.disabled = true
	input_line.editable = false


func can_retry_failure() -> bool:
	return level_run.can_retry()


func retry_failure() -> void:
	if can_retry_failure():
		level_run.retry()
		_start_level_with_lifecycle(false)


func _advance_level() -> void:
	match level_run.outcome:
		LevelRunController.Outcome.SUCCESS:
			level_run.retry()
			_start_level_with_lifecycle(false)
		LevelRunController.Outcome.FAILURE:
			retry_failure()


func can_show_hint() -> bool:
	return active and not hint_visible


func _show_hint() -> void:
	if not active or hint_visible:
		return
	hint_visible = true
	coin_label.text = "★ %d" % AppState.coins()
	if game_id == "unicorn_blast":
		message_label.text = "Blast: %s" % _urgent_blast_word()
	elif game_id == "letter_lift":
		_render_letter_lift()
	elif sequence_strategy.supports(game_id):
		_apply_sequence_hint(sequence_strategy.hint(_strategy_context()))
	elif game_id == "sight_spark" and phase == "type":
		prompt_label.text = expected_word
	elif choice_strategy.supports(game_id):
		_apply_choice_hint(choice_strategy.hint(_strategy_context()))
	else:
		message_label.text = _hint_text()


func _request_hint() -> void:
	if not active or hint_visible:
		return
	if level > 1 and not AppState.spend_hint(level):
		message_label.text = "You need 5 coins for a hint. Keep playing to earn more!"
		return
	_show_hint()


func _hint_text() -> String:
	if sequence_strategy.supports(game_id):
		return "Next: %s" % str(sequence_strategy.hint(_strategy_context()).get("next", ""))
	if choice_strategy.supports(game_id):
		var choice_hint := choice_strategy.hint(_strategy_context())
		var choice_message := str(choice_hint.get("message", ""))
		if not choice_message.is_empty():
			return choice_message
	return "Look closely at the prompt."


func _fail_reason() -> String:
	if sequence_strategy.supports(game_id):
		return sequence_strategy.failure_reason(_strategy_context())
	if choice_strategy.supports(game_id):
		return choice_strategy.failure_reason(_strategy_context())
	match game_id:
		"sight_spark": return "Spell the spark word from memory!"
		"letter_lift": return "Type each letter in order!"
		"unicorn_blast": return "Words reached your cannon!"
	return "Try this level again."


func _strategy_context() -> Dictionary:
	return {
		"game_id": game_id,
		"level": level,
		"round_index": round_index,
		"rng": rng,
		"hint_visible": hint_visible,
		"current": current,
		"sequence": sequence,
		"pool": pool,
		"picked": picked,
		"phase": phase,
	}


func _apply_choice_hint(hint: Dictionary) -> void:
	if hint.has("prompt"):
		prompt_label.text = str(hint["prompt"])
	if hint.has("message"):
		message_label.text = str(hint["message"])


func _apply_sequence_hint(_hint: Dictionary) -> void:
	_render_sequence()


func _update_blast(delta: float) -> void:
	spawn_elapsed += delta
	if not blast_source_exhausted and spawn_elapsed * 1000.0 >= Rules.blast_spawn_ms(level):
		spawn_elapsed = 0.0
		_spawn_blast_word()
	var escaped: Array[int] = []
	for index in blast_words.size():
		var entry: Dictionary = blast_words[index]
		entry["y"] = float(entry.get("y", 8.0)) + Rules.blast_speed(level) * delta * 60.0
		_position_blast_word(entry)
		if entry["y"] > 78.0:
			escaped.append(index)
	for position in range(escaped.size() - 1, -1, -1):
		_remove_blast_word(escaped[position])
		_lost_life()
		if not active:
			break
	if hint_visible and active:
		message_label.text = "Blast: %s" % _urgent_blast_word()


func _spawn_blast_word() -> bool:
	if not active:
		return false
	var words := Rules.words_for_level(level)
	if words.is_empty():
		if not blast_source_exhausted:
			blast_source_exhausted = true
			message_label.text = "This word cloud needs a refill. Try again soon."
		return false
	var text := str(words[rng.randi_range(0, words.size() - 1)])
	var button := Button.new()
	button.text = text
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.custom_minimum_size = Vector2(104, 42)
	play_area.add_child(button)
	var entry := {"text": text, "x": rng.randf_range(12.0, 76.0), "y": 8.0, "button": button}
	blast_words.append(entry)
	_position_blast_word(entry)
	return true


func _position_blast_word(entry: Dictionary) -> void:
	var button: Button = entry["button"]
	var width := maxf(play_area.size.x, 430.0)
	var height := maxf(play_area.size.y, 330.0)
	button.position = Vector2(width * float(entry["x"]) / 100.0 - 52.0, height * float(entry["y"]) / 100.0)


func _remove_blast_word(index: int) -> void:
	if index < 0 or index >= blast_words.size():
		return
	var button: Button = blast_words[index].get("button")
	if is_instance_valid(button):
		button.queue_free()
	blast_words.remove_at(index)


func _clear_blast_words() -> void:
	for entry in blast_words:
		var button: Button = entry.get("button")
		if is_instance_valid(button):
			button.queue_free()
	blast_words.clear()


func _urgent_blast_word() -> String:
	var urgent := ""
	var highest := -1.0
	for entry in blast_words:
		if float(entry.get("y", 0.0)) > highest:
			highest = float(entry["y"])
			urgent = str(entry["text"])
	return urgent


func _hide_special_controls() -> void:
	input_line.hide()
	input_line.editable = true
	_set_input_text("")
	play_area.hide()


func _show_text_input(placeholder: String) -> void:
	input_line.placeholder_text = placeholder
	input_line.editable = true
	input_line.show()
	input_line.grab_focus()


func _set_input_text(value: String) -> void:
	suppress_text_event = true
	input_line.text = value
	input_line.caret_column = value.length()
	suppress_text_event = false


func _clear_options() -> void:
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()


func _add_option(text: String, payload) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 72)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 19)
	button.pressed.connect(_choose.bind(payload))
	options.add_child(button)


func _go_back() -> void:
	AppState.set_shell_destination("category", str(game_info.get("category", "Word")))
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = NAVY
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	var back := StorybookUI.category_back_button("", 120, return_to_category)
	back.text = "‹ BACK"
	header.add_child(back)
	title_label = Label.new()
	title_label.text = str(game_info.get("title", "WORD GAME")).to_upper()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 25)
	title_label.add_theme_color_override("font_color", PINK if game_info.get("category") == "Word" else CYAN)
	header.add_child(title_label)
	coin_label = Label.new()
	coin_label.text = "★ %d" % AppState.coins()
	coin_label.add_theme_color_override("font_color", YELLOW)
	coin_label.add_theme_color_override("font_outline_color", StorybookUI.PLUM)
	coin_label.add_theme_constant_override("outline_size", 3)
	coin_label.add_theme_font_size_override("font_size", 24)
	header.add_child(coin_label)
	layout.add_child(header)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 18)
	level_label = Label.new()
	stats.add_child(level_label)
	progress_label = Label.new()
	stats.add_child(progress_label)
	lives_label = Label.new()
	lives_label.add_theme_color_override("font_color", PINK)
	stats.add_child(lives_label)
	timer_label = Label.new()
	stats.add_child(timer_label)
	layout.add_child(stats)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	instruction_label = Label.new()
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	StorybookUI.apply_story_label(instruction_label, Color("c8d2ff"), 18, true)
	content.add_child(instruction_label)
	var prompt_plaque := PanelContainer.new()
	prompt_plaque.name = "WordPromptPlaque"
	StorybookUI.apply_prompt_plaque(prompt_plaque, Color("fff3d6"))
	content.add_child(prompt_plaque)
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.custom_minimum_size = Vector2(0, 78)
	StorybookUI.apply_story_label(prompt_label, Color("9c356d"), 36, false)
	prompt_plaque.add_child(prompt_label)
	secondary_label = Label.new()
	secondary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secondary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	StorybookUI.apply_story_label(secondary_label, Color("62e6a7"), 20, true)
	content.add_child(secondary_label)
	var play_frame := PanelContainer.new()
	play_frame.name = "WordPlayFrame"
	play_frame.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("14214a"), Color("e1ae4f"), 18))
	content.add_child(play_frame)
	play_area = Control.new()
	play_area.custom_minimum_size = Vector2(0, 350)
	play_area.clip_contents = true
	var play_bg := ColorRect.new()
	play_bg.color = Color("0d1738")
	play_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play_area.add_child(play_bg)
	play_frame.add_child(play_area)
	input_line = LineEdit.new()
	input_line.custom_minimum_size = Vector2(0, 58)
	input_line.add_theme_font_size_override("font_size", 22)
	input_line.text_changed.connect(_on_text_changed)
	input_line.text_submitted.connect(_on_text_submitted)
	content.add_child(input_line)
	options = GridContainer.new()
	options.columns = 2
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("h_separation", 10)
	options.add_theme_constant_override("v_separation", 10)
	content.add_child(options)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(0, 48)
	message_label.add_theme_font_size_override("font_size", 17)
	content.add_child(message_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)
	hint_button = StorybookUI.hint_highlight_button("", 140, _request_hint)
	actions.add_child(hint_button)
	retry_button = StorybookUI.progression_action_button("", 160, _advance_level)
	actions.add_child(retry_button)
	flash_timer = Timer.new()
	flash_timer.one_shot = true
	flash_timer.timeout.connect(_finish_sight_flash)
	add_child(flash_timer)
