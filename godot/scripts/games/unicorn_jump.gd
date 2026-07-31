extends Control

const Rules = preload("res://scripts/games/gameplay_rules.gd")

var level := 1
var level_data: Array[int] = []
var current_index := 0
var visited: Array[int] = []
var active := false
var started_ms := 0
var node_buttons: Array[Button] = []
var status_label: Label
var jump_label: Label
var path_box: VBoxContainer
var scroller: ScrollContainer
var action_button: Button
var zoom := 1.0


func _ready() -> void:
	level = AppState.current_level("unicorn_jump")
	_build_ui()
	_start_level(level)


func generate_level_data(for_level: int, rng: RandomNumberGenerator = null) -> Array[int]:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var length := Rules.jump_path_length(for_level)
	var data: Array[int] = []
	data.resize(length)
	data.fill(0)
	var current := 0
	var last := 0
	var maximum := Rules.jump_max(for_level)
	var allow_negative := for_level >= 15
	var max_negative := Rules.jump_negative_max(for_level)
	while current < length:
		var do_trick := allow_negative and rng.randf() < 0.2 and length - current > 6
		if do_trick:
			var backward := rng.randi_range(1, max_negative)
			var forward := backward + rng.randi_range(1, 3)
			if current + forward < length and data[current + forward] == 0:
				data[current] = forward
				data[current + forward] = -backward
				current += forward - backward
				last = -999
				continue
		var jump := 1
		var attempts := 0
		while true:
			jump = rng.randi_range(1, maximum)
			attempts += 1
			if not ((jump == last and length - current > jump and attempts < 10) or (current + jump < length and data[current + jump] != 0)):
				break
		if current + jump > length:
			jump = length - current
		data[current] = jump
		current += jump
		last = jump
	for index in length:
		if data[index] == 0:
			if allow_negative and rng.randf() < 0.3:
				data[index] = -rng.randi_range(1, max_negative)
			else:
				data[index] = rng.randi_range(1, maximum)
	return data


func _start_level(for_level: int) -> void:
	level = for_level
	level_data = generate_level_data(level)
	current_index = 0
	visited = [0]
	started_ms = Time.get_ticks_msec()
	active = true
	action_button.hide()
	status_label.text = "Tap the one exact landing spot. Drag the path to explore."
	_rebuild_path()
	_update_path()


func _choose_node(index: int) -> void:
	if not active or index == current_index:
		return
	var expected := current_index + level_data[current_index]
	if index != expected:
		active = false
		status_label.text = "Wrong landing. You needed node %d." % expected
		action_button.text = "Retry"
		action_button.show()
		_set_nodes_enabled(false)
		return
	current_index = index
	visited.append(index)
	if current_index == level_data.size():
		active = false
		var reward := AppState.complete_level("unicorn_jump", level, Time.get_ticks_msec() - started_ms)
		status_label.text = "Trail complete! +%d coins" % reward
		action_button.text = "Next Level"
		action_button.show()
		_set_nodes_enabled(false)
	else:
		status_label.text = "Perfect landing. Keep going!"
	_update_path()


func _rebuild_path() -> void:
	for child in path_box.get_children():
		child.queue_free()
	node_buttons.clear()
	# Reverse order keeps the finish visually above the start, like the climbing React trail.
	for index in range(level_data.size(), -1, -1):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var spacer := Control.new()
		spacer.custom_minimum_size.x = 50.0 + sin(float(index) / maxf(1.0, level_data.size()) * PI * 3.0) * 45.0
		row.add_child(spacer)
		var button := Button.new()
		button.text = "FINISH" if index == level_data.size() else str(index)
		button.custom_minimum_size = Vector2(150, 62)
		button.pressed.connect(_choose_node.bind(index))
		row.add_child(button)
		path_box.add_child(row)
		node_buttons.push_front(button)


func _update_path() -> void:
	jump_label.text = "LEVEL %d  |  NODE %d / %d  |  JUMP %s" % [level, current_index, level_data.size(), _signed(level_data[current_index]) if current_index < level_data.size() else "DONE"]
	for index in node_buttons.size():
		var button := node_buttons[index]
		if index == current_index:
			button.text = ("START" if index == 0 else str(index)) + "  [YOU]"
			button.modulate = Color("ffdf67")
		elif index in visited:
			button.text = str(index) + "  OK"
			button.modulate = Color("75e6bb")
		else:
			button.text = "FINISH" if index == level_data.size() else str(index)
			button.modulate = Color.WHITE
	await get_tree().process_frame
	var reversed_index := level_data.size() - current_index
	var desired := maxf(0.0, reversed_index * 70.0 - scroller.size.y * 0.45)
	scroller.scroll_vertical = int(desired)


func _change_zoom(amount: float) -> void:
	zoom = clampf(zoom + amount, 0.7, 1.4)
	for button in node_buttons:
		button.custom_minimum_size = Vector2(150, 62) * zoom
		button.add_theme_font_size_override("font_size", int(16 * zoom))
	path_box.add_theme_constant_override("separation", int(8 * zoom))


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("11113d")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var title := Label.new()
	title.text = "UNICORN JUMP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("f79cff"))
	root.add_child(title)
	jump_label = Label.new()
	jump_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jump_label.add_theme_font_size_override("font_size", 20)
	root.add_child(jump_label)
	scroller = ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroller)
	path_box = VBoxContainer.new()
	path_box.custom_minimum_size.x = 620
	path_box.add_theme_constant_override("separation", 8)
	scroller.add_child(path_box)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(actions)
	var zoom_out := Button.new()
	zoom_out.text = "Zoom -"
	zoom_out.pressed.connect(_change_zoom.bind(-0.1))
	actions.add_child(zoom_out)
	var zoom_in := Button.new()
	zoom_in.text = "Zoom +"
	zoom_in.pressed.connect(_change_zoom.bind(0.1))
	actions.add_child(zoom_in)
	action_button = Button.new()
	action_button.pressed.connect(func() -> void: _start_level(level + 1 if action_button.text == "Next Level" else level))
	actions.add_child(action_button)
	var back := Button.new()
	back.text = "Number Games"
	back.pressed.connect(func() -> void:
		AppState.set_shell_destination("category", "Number")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	actions.add_child(back)


func _set_nodes_enabled(enabled: bool) -> void:
	for button in node_buttons:
		button.disabled = not enabled


func _signed(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)
