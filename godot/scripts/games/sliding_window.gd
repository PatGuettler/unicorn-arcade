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
var track_scroller: ScrollContainer


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


func _choose(absolute_index: int) -> void:
	if not active:
		return
	if not _index_is_in_window(absolute_index):
		message_label.text = "Choose a number inside the glowing window."
		return
	var maximum := _window_maximum()
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
	var maximum := _window_maximum()
	for index in value_buttons.size():
		value_buttons[index].modulate = Color("ffe172") if _index_is_in_window(index) and level_data[index] == maximum else Color.WHITE
	message_label.text = "The gold node is the current maximum."


func _index_is_in_window(absolute_index: int) -> bool:
	return absolute_index >= window_pos and absolute_index < window_pos + window_size


func _window_maximum() -> int:
	var maximum := level_data[window_pos]
	for index in range(window_pos + 1, window_pos + window_size):
		maximum = maxi(maximum, level_data[index])
	return maximum


func _rebuild_buttons() -> void:
	for button in value_buttons:
		button.queue_free()
	value_buttons.clear()
	for index in level_data.size():
		var button := Button.new()
		button.name = "TrackValue%d" % index
		button.custom_minimum_size = Vector2(105, 105)
		button.add_theme_font_size_override("font_size", 28)
		button.set_meta("sliding_window_node", true)
		button.pressed.connect(_choose.bind(index))
		value_row.add_child(button)
		value_buttons.append(button)


func _update_window() -> void:
	progress_label.text = "LEVEL %d   YOUR WINDOW %d / %d" % [level, window_pos + 1, level_data.size() - window_size + 1]
	for index in value_buttons.size():
		value_buttons[index].text = str(level_data[index])
		value_buttons[index].modulate = Color.WHITE
		_style_track_node(value_buttons[index], _index_is_in_window(index))
	_center_window.call_deferred()


func _style_track_node(button: Button, in_window: bool) -> void:
	button.disabled = not in_window
	if in_window:
		button.add_theme_color_override("font_color", StorybookUI.CREAM)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_color_override("font_outline_color", StorybookUI.PLUM)
		button.add_theme_constant_override("outline_size", 2)
		button.add_theme_stylebox_override("normal", StorybookUI.button_style(Color("173f68"), Color("62e6b5"), 5, 18, 6))
		button.add_theme_stylebox_override("hover", StorybookUI.button_style(Color("24527b"), Color("8bffcf"), 5, 18, 7))
		button.add_theme_stylebox_override("pressed", StorybookUI.button_style(Color("102f55"), Color("f4d37f"), 5, 18, 3))
		button.add_theme_stylebox_override("focus", StorybookUI.button_style(Color("24527b"), Color("8bffcf"), 5, 18, 7))
	else:
		button.add_theme_color_override("font_disabled_color", Color("a5aec8"))
		button.add_theme_stylebox_override("disabled", StorybookUI.button_style(Color("101933"), Color("46516c"), 2, 14, 1))


func _center_window() -> void:
	if not is_instance_valid(track_scroller) or value_buttons.is_empty():
		return
	var first := value_buttons[window_pos]
	var last := value_buttons[window_pos + window_size - 1]
	var window_center := (first.position.x + last.position.x + last.size.x) * 0.5
	track_scroller.scroll_horizontal = roundi(maxf(0.0, window_center - track_scroller.size.x * 0.5))


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
	track_scroller = ScrollContainer.new()
	track_scroller.name = "NumberTrackScroller"
	track_scroller.custom_minimum_size.y = 132
	track_scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	track_scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(track_scroller)
	value_row = HBoxContainer.new()
	value_row.name = "FullNumberTrack"
	value_row.alignment = BoxContainer.ALIGNMENT_CENTER
	value_row.add_theme_constant_override("separation", 10)
	track_scroller.add_child(value_row)
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
