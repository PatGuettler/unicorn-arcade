extends Control

const Rules = preload("res://scripts/games/gameplay_rules.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")

var level := 1
var level_data: Array[int] = []
var opponent_data: Array[int] = []
var window_size := 3
var window_pos := 0
var opponent_pos := 0
var active := false
var rival_elapsed := -500.0
var started_ms := 0
var value_buttons: Array[Button] = []
var progress_label: Label
var rival_label: Label
var message_label: Label
var action_button: Button
var value_row: HBoxContainer


func _ready() -> void:
	level = AppState.current_level("sliding_window")
	_build_ui()
	_start_level(level)


func _process(delta: float) -> void:
	if not active:
		return
	rival_elapsed += delta * 1000.0 * CompanionAbilityService.time_scale()
	var speed := Rules.rival_move_ms(level)
	while rival_elapsed >= speed:
		rival_elapsed -= speed
		if opponent_pos + window_size >= opponent_data.size():
			_fail("The rival beat you to the finish!")
			return
		opponent_pos += 1
		if opponent_pos + window_size >= opponent_data.size():
			_fail("The rival beat you to the finish!")
			return
		_update_rival()


func _start_level(for_level: int) -> void:
	level = for_level
	var bounds := Rules.sliding_bounds(level)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	level_data.clear()
	opponent_data.clear()
	for index in Rules.sliding_length(level):
		level_data.append(rng.randi_range(bounds.x, bounds.y))
		opponent_data.append(rng.randi_range(bounds.x, bounds.y))
	window_size = Rules.sliding_window(level)
	window_pos = 0
	opponent_pos = 0
	rival_elapsed = -500.0
	started_ms = Time.get_ticks_msec()
	active = true
	action_button.hide()
	message_label.text = "Choose the largest number inside your moving window."
	_rebuild_buttons()
	_update_window()
	_update_rival()


func _choose(index_in_window: int) -> void:
	if not active:
		return
	var absolute_index := window_pos + index_in_window
	var maximum := level_data[window_pos]
	for index in range(window_pos, window_pos + window_size):
		maximum = maxi(maximum, level_data[index])
	if level_data[absolute_index] != maximum:
		_fail("Wrong node selected! The maximum was %d." % maximum)
		return
	if window_pos + window_size >= level_data.size():
		active = false
		var reward := AppState.complete_level("sliding_window", level, Time.get_ticks_msec() - started_ms)
		message_label.text = "You won the race! +%d coins" % reward
		action_button.text = "Next Level"
		action_button.show()
		_set_buttons_enabled(false)
		return
	window_pos += 1
	message_label.text = "Great choice. The window slides forward!"
	_update_window()


func _fail(reason: String) -> void:
	active = false
	message_label.text = reason
	action_button.text = "Retry"
	action_button.show()
	_set_buttons_enabled(false)


func _show_hint() -> void:
	if not active or not AppState.spend_hint(level):
		return
	var maximum := level_data[window_pos]
	for index in range(window_pos, window_pos + window_size):
		maximum = maxi(maximum, level_data[index])
	for index in value_buttons.size():
		value_buttons[index].modulate = Color("ffe172") if int(value_buttons[index].text) == maximum else Color.WHITE
	message_label.text = "The gold node is the current maximum."


func _rebuild_buttons() -> void:
	for button in value_buttons:
		button.queue_free()
	value_buttons.clear()
	for index in window_size:
		var button := Button.new()
		button.custom_minimum_size = Vector2(105, 105)
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_choose.bind(index))
		value_row.add_child(button)
		value_buttons.append(button)


func _update_window() -> void:
	progress_label.text = "LEVEL %d   YOUR WINDOW %d / %d" % [level, window_pos + 1, level_data.size() - window_size + 1]
	for index in window_size:
		value_buttons[index].text = str(level_data[window_pos + index])
		value_buttons[index].disabled = false
		value_buttons[index].modulate = Color.WHITE


func _update_rival() -> void:
	var finish := opponent_data.size() - window_size
	var percent := int(100.0 * opponent_pos / maxf(1.0, finish))
	rival_label.text = "RIVAL  %d%%   (moves every %.1fs)" % [percent, Rules.rival_move_ms(level) / 1000.0]


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0a1732")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 18)
	add_child(root)
	var title := Label.new()
	title.text = "RACE THE UNICORN!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(title, Color("65e7ff"), 36, true)
	root.add_child(title)
	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(progress_label, Color("fff3d6"), 20, true)
	root.add_child(progress_label)
	var instruction_plaque := PanelContainer.new()
	StorybookUI.apply_prompt_plaque(instruction_plaque, Color("ffe8fb"))
	root.add_child(instruction_plaque)
	var instruction := Label.new()
	instruction.text = "FIND THE MAXIMUM"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(instruction, Color("5b2a68"), 22, false)
	instruction_plaque.add_child(instruction)
	value_row = HBoxContainer.new()
	value_row.alignment = BoxContainer.ALIGNMENT_CENTER
	value_row.add_theme_constant_override("separation", 10)
	root.add_child(value_row)
	var player_bar := ProgressBar.new()
	player_bar.value = 100
	player_bar.custom_minimum_size = Vector2(560, 18)
	player_bar.show_percentage = false
	root.add_child(player_bar)
	rival_label = Label.new()
	rival_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rival_label.add_theme_color_override("font_color", Color("f69cff"))
	root.add_child(rival_label)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(message_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(actions)
	var hint := Button.new()
	StorybookUI.apply_game_action(hint, 120)
	hint.text = "Hint"
	hint.pressed.connect(_show_hint)
	actions.add_child(hint)
	action_button = Button.new()
	StorybookUI.apply_game_action(action_button, 160)
	action_button.pressed.connect(func() -> void: _start_level(level + 1 if action_button.text == "Next Level" else level))
	actions.add_child(action_button)
	var back := Button.new()
	StorybookUI.apply_game_action(back, 170)
	back.text = "Number Games"
	back.pressed.connect(func() -> void:
		AppState.set_shell_destination("category", "Number")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	actions.add_child(back)


func _set_buttons_enabled(enabled: bool) -> void:
	for button in value_buttons:
		button.disabled = not enabled
