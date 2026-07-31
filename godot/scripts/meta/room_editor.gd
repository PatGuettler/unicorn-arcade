extends Control

const Catalog = preload("res://scripts/meta_catalog.gd")
const Rules = preload("res://scripts/room_rules.gd")

const NAVY := Color("08112f")
const PANEL := Color("14214a")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const MUTED := Color("aab7e8")

var companion_id := "sparkle"
var grid_snap := true
var selected_id := ""
var dragging_id := ""
var reset_armed := false
var room_canvas: Control
var item_buttons := {}
var local_items: Array = []
var status_label: Label
var selection_label: Label
var reset_button: Button
var bag_category := "all"


func _ready() -> void:
	companion_id = AppState.active_room_companion
	_build_editor()


func _clear_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	item_buttons.clear()


func _build_editor() -> void:
	_clear_ui()
	local_items = AppState.room_items(companion_id)
	local_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("z_index", 0)) < int(b.get("z_index", 0)))
	var definition := Catalog.companion(companion_id)
	var bg := ColorRect.new()
	bg.color = NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	root.add_theme_constant_override("separation", 7)
	add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var alley := Button.new()
	alley.text = "< ALLEY"
	alley.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta/unicorn_alley.tscn"))
	header.add_child(alley)
	var title := Label.new()
	title.text = "%s'S ROOM" % str(definition.get("name", companion_id)).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(str(definition.get("color", "f26fa7"))))
	header.add_child(title)
	var home := Button.new()
	home.text = "HOME"
	home.pressed.connect(func() -> void: AppState.shell_view = "home"; get_tree().change_scene_to_file("res://scenes/main.tscn"))
	header.add_child(home)
	var tools := HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(tools)
	var snap := CheckButton.new()
	snap.text = "8% GRID SNAP"
	snap.button_pressed = grid_snap
	snap.toggled.connect(func(value: bool) -> void: grid_snap = value)
	tools.add_child(snap)
	reset_button = Button.new()
	reset_button.text = "RESET ROOM" if not reset_armed else "CONFIRM RESET?"
	reset_button.pressed.connect(_reset_room)
	tools.add_child(reset_button)
	room_canvas = Control.new()
	room_canvas.custom_minimum_size = Vector2(420, 500)
	room_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room_canvas.clip_contents = true
	root.add_child(room_canvas)
	var room_bg := ColorRect.new()
	room_bg.color = Color(str(definition.get("color", "f26fa7"))).darkened(0.72)
	room_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_canvas.add_child(room_bg)
	var floor := ColorRect.new()
	floor.color = Color("29345c")
	floor.anchor_top = 0.42
	floor.anchor_right = 1.0
	floor.anchor_bottom = 1.0
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_bg.add_child(floor)
	for item in local_items:
		_create_item_button(item)
	room_canvas.resized.connect(_position_items)
	selection_label = Label.new()
	selection_label.text = "Select and drag an item"
	selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_label.add_theme_color_override("font_color", MUTED)
	root.add_child(selection_label)
	var controls := GridContainer.new()
	controls.columns = 3
	controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(controls)
	for action in ["ROTATE", "SMALLER", "LARGER", "BACK", "FRONT", "REMOVE"]:
		var button := Button.new()
		button.text = action
		button.pressed.connect(_selection_action.bind(action))
		controls.add_child(button)
	var bag := Button.new()
	bag.text = "FURNITURE BAG"
	bag.custom_minimum_size.y = 54
	bag.pressed.connect(_show_bag)
	root.add_child(bag)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", YELLOW)
	status_label.text = "%d decorations placed. Drag, rotate, resize, and layer them." % local_items.size()
	root.add_child(status_label)
	_position_items.call_deferred()


func _create_item_button(item: Dictionary) -> void:
	var item_id := str(item.get("item_id", ""))
	var definition := _item_definition(item_id)
	var button := Button.new()
	button.text = str(definition.get("name", item_id)).get_slice(" ", 0).to_upper()
	button.custom_minimum_size = Vector2(88, 52) * float(item.get("scale", 1.0))
	button.rotation_degrees = int(item.get("rotation", 0))
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("10172e"))
	button.add_theme_stylebox_override("normal", _item_style(str(definition.get("category", "cozy")), str(item.get("instance_id", "")) == selected_id))
	button.gui_input.connect(_item_input.bind(str(item.get("instance_id", "")), button))
	room_canvas.add_child(button)
	item_buttons[str(item.get("instance_id", ""))] = button


func _position_items() -> void:
	if not is_instance_valid(room_canvas):
		return
	for item in local_items:
		var instance_id := str(item.get("instance_id", ""))
		var button := item_buttons.get(instance_id) as Button
		if not is_instance_valid(button):
			continue
		button.position = Vector2(float(item.get("x", 50.0)) / 100.0 * room_canvas.size.x, float(item.get("y", 50.0)) / 100.0 * room_canvas.size.y) - button.size * 0.5


func _item_input(event: InputEvent, instance_id: String, button: Button) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			selected_id = instance_id
			dragging_id = instance_id
			_mark_selected()
		else:
			_commit_drag(instance_id)
	elif event is InputEventMouseMotion and dragging_id == instance_id and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_dragged(instance_id, room_canvas.get_local_mouse_position(), button)
	elif event is InputEventScreenTouch:
		if event.pressed:
			selected_id = instance_id
			dragging_id = instance_id
			_mark_selected()
		else:
			_commit_drag(instance_id)
	elif event is InputEventScreenDrag and dragging_id == instance_id:
		var local: Vector2 = event.position - room_canvas.global_position
		_move_dragged(instance_id, local, button)


func _move_dragged(instance_id: String, local_position: Vector2, button: Button) -> void:
	var item := _local_item(instance_id)
	if item.is_empty():
		return
	item["x"] = clampf(local_position.x / maxf(1.0, room_canvas.size.x) * 100.0, 0.0, 100.0)
	item["y"] = clampf(local_position.y / maxf(1.0, room_canvas.size.y) * 100.0, 0.0, 100.0)
	button.position = local_position - button.size * 0.5


func _commit_drag(instance_id: String) -> void:
	var item := _local_item(instance_id)
	if not item.is_empty():
		item["x"] = Rules.snap(float(item["x"]), grid_snap)
		item["y"] = Rules.snap(float(item["y"]), grid_snap)
		AppState.place_room_item(companion_id, item)
	dragging_id = ""
	local_items = AppState.room_items(companion_id)
	_position_items()


func _mark_selected() -> void:
	var item := _local_item(selected_id)
	var definition := _item_definition(str(item.get("item_id", "")))
	selection_label.text = str(definition.get("name", "Selected"))
	for instance_id in item_buttons:
		var source := _local_item(instance_id)
		var source_def := _item_definition(str(source.get("item_id", "")))
		item_buttons[instance_id].add_theme_stylebox_override("normal", _item_style(str(source_def.get("category", "cozy")), instance_id == selected_id))


func _selection_action(action: String) -> void:
	if selected_id.is_empty():
		status_label.text = "Select an item first."
		return
	var item := _local_item(selected_id)
	if item.is_empty():
		return
	match action:
		"ROTATE": item["rotation"] = (int(item.get("rotation", 0)) + 45) % 360
		"SMALLER": item["scale"] = clampf(float(item.get("scale", 1.0)) - 0.1, 0.5, 1.8)
		"LARGER": item["scale"] = clampf(float(item.get("scale", 1.0)) + 0.1, 0.5, 1.8)
		"BACK", "FRONT":
			AppState.reorder_room_item(companion_id, selected_id, action.to_lower())
			_build_editor()
			return
		"REMOVE":
			AppState.remove_room_item(companion_id, selected_id)
			selected_id = ""
			_build_editor()
			return
	AppState.place_room_item(companion_id, item)
	_build_editor()


func _reset_room() -> void:
	if not reset_armed:
		reset_armed = true
		reset_button.text = "CONFIRM RESET?"
		status_label.text = "Tap again to return every item to the bag."
		return
	AppState.reset_room(companion_id)
	selected_id = ""
	reset_armed = false
	_build_editor()


func _show_bag() -> void:
	_clear_ui()
	var bg := ColorRect.new()
	bg.color = NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var close := Button.new()
	close.text = "< ROOM"
	close.pressed.connect(_build_editor)
	header.add_child(close)
	var title := Label.new()
	title.text = "FURNITURE BAG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", PINK)
	header.add_child(title)
	var picker := OptionButton.new()
	for category_data in Catalog.categories():
		picker.add_item(str(category_data["label"]))
		picker.set_item_metadata(picker.item_count - 1, str(category_data["id"]))
	picker.add_item("Companion")
	picker.set_item_metadata(picker.item_count - 1, "companions")
	for index in picker.item_count:
		if str(picker.get_item_metadata(index)) == bag_category:
			picker.select(index)
			break
	picker.item_selected.connect(func(index: int) -> void: bag_category = str(picker.get_item_metadata(index)); _show_bag())
	header.add_child(picker)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var candidates: Array = Catalog.furniture().duplicate()
	var companion_item := {"id": "companion_%s" % companion_id, "name": Catalog.companion(companion_id).get("name", companion_id), "category": "companions", "rarity": "legendary", "desc": "House gift companion"}
	candidates.push_front(companion_item)
	var shown := 0
	for definition in candidates:
		var id := str(definition["id"])
		if bag_category != "all" and str(definition.get("category", "")) != bag_category:
			continue
		var available := AppState.available_count(id)
		if available <= 0:
			continue
		shown += 1
		var place := Button.new()
		place.text = "%s\n%s  |  x%d available" % [definition["name"], definition.get("desc", ""), available]
		place.custom_minimum_size.y = 72
		place.alignment = HORIZONTAL_ALIGNMENT_LEFT
		place.pressed.connect(_place_from_bag.bind(id))
		list.add_child(place)
	if shown == 0:
		var empty := Label.new()
		empty.text = "Nothing available in this category. Buy decor in the Marketplace or remove placed items."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", MUTED)
		list.add_child(empty)
	var shop := Button.new()
	shop.text = "OPEN MARKETPLACE"
	shop.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta/marketplace.tscn"))
	root.add_child(shop)


func _place_from_bag(item_id: String) -> void:
	var items := AppState.room_items(companion_id)
	var item := {
		"instance_id": "%d_%d" % [Time.get_ticks_msec(), randi_range(100, 999)],
		"item_id": item_id,
		"x": Rules.snap(50.0, grid_snap),
		"y": Rules.snap(50.0, grid_snap),
		"rotation": 0,
		"scale": 1.2 if item_id.begins_with("companion_") else 1.0,
		"z_index": Rules.next_z(items),
	}
	if AppState.place_room_item(companion_id, item):
		selected_id = str(item["instance_id"])
		_build_editor()


func _local_item(instance_id: String) -> Dictionary:
	for item in local_items:
		if str(item.get("instance_id", "")) == instance_id:
			return item
	return {}


func _item_definition(item_id: String) -> Dictionary:
	if item_id.begins_with("companion_"):
		var definition := Catalog.companion(item_id.trim_prefix("companion_"))
		return {"name": definition.get("name", "Companion"), "category": "companions"}
	return Catalog.furniture_item(item_id)


func _item_style(category: String, selected: bool) -> StyleBoxFlat:
	var colors := {"companions": PINK, "nature": Color("62e6a7"), "lighting": YELLOW, "luxury": Color("d5a4ff"), "pets": Color("ff9f7c"), "electronics": CYAN, "seasonal": Color("f59c5b")}
	var color: Color = colors.get(category, Color("9da9d9"))
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.WHITE if selected else color.darkened(0.35)
	style.set_border_width_all(4 if selected else 2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style
