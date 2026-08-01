extends Control

const Catalog = preload("res://scripts/meta_catalog.gd")
const Rules = preload("res://scripts/room_rules.gd")
const FurnitureArtScene = preload("res://scripts/meta/furniture_art.gd")

const NAVY := Color("08112f")
const PANEL := Color("14214a")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const MUTED := Color("aab7e8")
const ROOM_BACKGROUNDS := {
	"sparkle": preload("res://assets/meta/environments/room_sparkle_production_v1.png"),
	"rainbow": preload("res://assets/meta/environments/room_rainbow_production_v1.png"),
	"star": preload("res://assets/meta/environments/room_star_production_v1.png"),
	"cloud": preload("res://assets/meta/environments/room_cloud_production_v1.png"),
	"dream": preload("res://assets/meta/environments/room_dream_production_v1.png"),
	"mystic": preload("res://assets/meta/environments/room_mystic_production_v1.png"),
}

var companion_id := "sparkle"
var grid_snap := true
var selected_id := ""
var dragging_id := ""
var reset_armed := false
var room_canvas: Control
var item_buttons := {}
var local_items: Array = []
var status_label: Label
var reset_button: Button
var selection_toolbar: HBoxContainer
var bag_overlay: Control
var bag_grid: GridContainer
var bag_category := "all"


func _ready() -> void:
	companion_id = AppState.active_room_companion
	_build_editor()


func _input(event: InputEvent) -> void:
	if dragging_id.is_empty() or not is_instance_valid(room_canvas):
		return
	var button := item_buttons.get(dragging_id) as Button
	if not is_instance_valid(button):
		return
	if event is InputEventScreenDrag:
		_move_dragged(dragging_id, event.position - room_canvas.global_position, button)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed:
		_commit_drag(dragging_id)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_dragged(dragging_id, event.position - room_canvas.global_position, button)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_commit_drag(dragging_id)


func _clear_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	item_buttons.clear()
	selection_toolbar = null
	bag_overlay = null
	bag_grid = null


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
	var room_stage := Control.new()
	room_stage.custom_minimum_size = Vector2(420, 500)
	room_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(room_stage)
	room_canvas = Control.new()
	room_canvas.clip_contents = true
	room_stage.add_child(room_canvas)
	var room_texture: Texture2D = ROOM_BACKGROUNDS.get(companion_id, ROOM_BACKGROUNDS["sparkle"])
	var room_bg := TextureRect.new()
	room_bg.texture = room_texture
	room_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	room_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_canvas.add_child(room_bg)
	for item in local_items:
		_create_item_button(item)
	room_canvas.resized.connect(_position_items)
	room_stage.resized.connect(_fit_room_canvas.bind(room_stage, room_texture.get_size()))
	_fit_room_canvas.call_deferred(room_stage, room_texture.get_size())
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", MUTED)
	status_label.text = "%d decorations placed. Tap an item for controls." % local_items.size()
	root.add_child(status_label)
	var bag := Button.new()
	bag.name = "FurnitureBagButton"
	bag.text = "BAG"
	bag.tooltip_text = "Open furniture bag"
	bag.custom_minimum_size = Vector2(72, 58)
	bag.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bag.position = Vector2(-88, -82)
	bag.add_theme_font_size_override("font_size", 16)
	bag.add_theme_color_override("font_color", Color.WHITE)
	bag.add_theme_stylebox_override("normal", _rounded_style(PINK, Color.WHITE, 3, 22))
	bag.add_theme_stylebox_override("hover", _rounded_style(PINK.lightened(0.08), Color.WHITE, 3, 22))
	bag.pressed.connect(_show_bag)
	add_child(bag)
	_position_items.call_deferred()


func _fit_room_canvas(stage: Control, source_size: Vector2) -> void:
	if not is_instance_valid(room_canvas) or stage.size.x < 1.0 or stage.size.y < 1.0:
		return
	var fit_scale := minf(stage.size.x / source_size.x, stage.size.y / source_size.y)
	room_canvas.size = source_size * fit_scale
	room_canvas.position = Vector2((stage.size.x - room_canvas.size.x) * 0.5, 12.0)
	_position_items()


func _create_item_button(item: Dictionary) -> void:
	var item_id := str(item.get("item_id", ""))
	var definition := _item_definition(item_id)
	var button := Button.new()
	button.text = ""
	button.tooltip_text = str(definition.get("name", item_id))
	button.custom_minimum_size = Vector2(92, 92) * float(item.get("scale", 1.0))
	button.rotation_degrees = int(item.get("rotation", 0))
	button.z_index = int(item.get("z_index", 0))
	button.mouse_default_cursor_shape = Control.CURSOR_DRAG
	button.add_theme_stylebox_override("normal", _item_style(str(definition.get("category", "cozy")), str(item.get("instance_id", "")) == selected_id))
	button.add_theme_stylebox_override("hover", _item_style(str(definition.get("category", "cozy")), true))
	button.gui_input.connect(_item_input.bind(str(item.get("instance_id", "")), button))
	room_canvas.add_child(button)
	var art := FurnitureArtScene.new()
	art.name = "FurnitureArt"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.setup(definition.merged({"id": item_id}, true))
	button.add_child(art)
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
	_position_selection_toolbar.call_deferred()


func _item_input(event: InputEvent, instance_id: String, _button: Button) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			selected_id = instance_id
			dragging_id = instance_id
			_mark_selected()
		else:
			_commit_drag(instance_id)
	elif event is InputEventScreenTouch:
		if event.pressed:
			selected_id = instance_id
			dragging_id = instance_id
			_mark_selected()
		else:
			_commit_drag(instance_id)


func _move_dragged(instance_id: String, local_position: Vector2, button: Button) -> void:
	var item := _local_item(instance_id)
	if item.is_empty():
		return
	item["x"] = clampf(local_position.x / maxf(1.0, room_canvas.size.x) * 100.0, 0.0, 100.0)
	item["y"] = clampf(local_position.y / maxf(1.0, room_canvas.size.y) * 100.0, 0.0, 100.0)
	button.position = local_position - button.size * 0.5
	_position_selection_toolbar()


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
	if is_instance_valid(status_label):
		status_label.text = str(definition.get("name", "Selected"))
	for instance_id in item_buttons:
		var source := _local_item(instance_id)
		var source_def := _item_definition(str(source.get("item_id", "")))
		item_buttons[instance_id].add_theme_stylebox_override("normal", _item_style(str(source_def.get("category", "cozy")), instance_id == selected_id))
	_show_selection_toolbar()


func _show_selection_toolbar() -> void:
	if is_instance_valid(selection_toolbar):
		selection_toolbar.queue_free()
	selection_toolbar = HBoxContainer.new()
	selection_toolbar.name = "SelectionToolbar"
	selection_toolbar.z_index = 2000
	selection_toolbar.add_theme_constant_override("separation", 2)
	selection_toolbar.add_theme_stylebox_override("panel", _rounded_style(Color("e90d1738"), Color("99ffffff"), 2, 12))
	room_canvas.add_child(selection_toolbar)
	var actions := [
		["REMOVE", "×", "Remove"],
		["ROTATE", "↻", "Rotate"],
		["SMALLER", "−", "Smaller"],
		["LARGER", "+", "Larger"],
		["BACK", "↓", "Send backward"],
		["FRONT", "↑", "Bring forward"],
	]
	for action in actions:
		var control := Button.new()
		control.text = action[1]
		control.tooltip_text = action[2]
		control.custom_minimum_size = Vector2(40, 38)
		control.add_theme_font_size_override("font_size", 22)
		control.add_theme_stylebox_override("normal", _rounded_style(Color("e9202b53"), Color("446be6ff"), 1, 9))
		control.pressed.connect(_selection_action.bind(action[0]))
		selection_toolbar.add_child(control)
	_position_selection_toolbar.call_deferred()


func _position_selection_toolbar() -> void:
	if selected_id.is_empty() or not is_instance_valid(selection_toolbar) or not is_instance_valid(room_canvas):
		return
	var button := item_buttons.get(selected_id) as Button
	if not is_instance_valid(button):
		return
	var toolbar_size := selection_toolbar.get_combined_minimum_size()
	selection_toolbar.size = toolbar_size
	var target_x := button.position.x + button.size.x * 0.5 - toolbar_size.x * 0.5
	var target_y := button.position.y - toolbar_size.y - 7.0
	if target_y < 5.0:
		target_y = button.position.y + button.size.y + 7.0
	selection_toolbar.position = Vector2(
		clampf(target_x, 5.0, maxf(5.0, room_canvas.size.x - toolbar_size.x - 5.0)),
		clampf(target_y, 5.0, maxf(5.0, room_canvas.size.y - toolbar_size.y - 5.0))
	)


func _selection_action(action: String) -> void:
	if selected_id.is_empty():
		if is_instance_valid(status_label):
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
			_refresh_room_items()
			return
		"REMOVE":
			AppState.remove_room_item(companion_id, selected_id)
			selected_id = ""
			_build_editor()
			return
	AppState.place_room_item(companion_id, item)
	_refresh_room_items()


func _refresh_room_items() -> void:
	local_items = AppState.room_items(companion_id)
	local_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("z_index", 0)) < int(b.get("z_index", 0)))
	for item in local_items:
		var instance_id := str(item.get("instance_id", ""))
		var button := item_buttons.get(instance_id) as Button
		if not is_instance_valid(button):
			continue
		button.custom_minimum_size = Vector2(92, 92) * float(item.get("scale", 1.0))
		button.size = button.custom_minimum_size
		button.rotation_degrees = int(item.get("rotation", 0))
		button.z_index = int(item.get("z_index", 0))
	_position_items()
	_mark_selected()


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
	if is_instance_valid(bag_overlay):
		return
	bag_overlay = Control.new()
	bag_overlay.name = "FurnitureBagOverlay"
	bag_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bag_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	bag_overlay.z_index = 4000
	add_child(bag_overlay)
	var dim := ColorRect.new()
	dim.color = Color("a8050a20")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	bag_overlay.add_child(dim)
	var sheet := PanelContainer.new()
	sheet.name = "FurnitureBagSheet"
	sheet.set_anchor(SIDE_LEFT, 0.0)
	sheet.set_anchor(SIDE_TOP, 0.34)
	sheet.set_anchor(SIDE_RIGHT, 1.0)
	sheet.set_anchor(SIDE_BOTTOM, 1.0)
	sheet.offset_left = 8
	sheet.offset_top = 0
	sheet.offset_right = -8
	sheet.offset_bottom = -8
	sheet.add_theme_stylebox_override("panel", _rounded_style(Color("fa14214a"), Color("6658d6e8"), 2, 24))
	bag_overlay.add_child(sheet)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.add_theme_constant_override("margin_left", 10)
	content.add_theme_constant_override("margin_right", 10)
	sheet.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "Close furniture bag"
	close.custom_minimum_size = Vector2(48, 48)
	close.add_theme_font_size_override("font_size", 26)
	close.pressed.connect(_close_bag)
	header.add_child(close)
	var title := Label.new()
	title.text = "FURNITURE BAG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", PINK)
	header.add_child(title)
	var shop := Button.new()
	shop.text = "SHOP"
	shop.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta/marketplace.tscn"))
	header.add_child(shop)
	var category_scroll := ScrollContainer.new()
	category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	category_scroll.custom_minimum_size.y = 58
	content.add_child(category_scroll)
	var categories := HBoxContainer.new()
	categories.add_theme_constant_override("separation", 6)
	category_scroll.add_child(categories)
	for category_data in Catalog.categories():
		var chip := Button.new()
		var category_id := str(category_data.get("id", "all"))
		chip.text = str(category_data.get("label", category_id))
		chip.button_pressed = category_id == bag_category
		chip.pressed.connect(_set_bag_category.bind(category_id))
		categories.add_child(chip)
	var companion_chip := Button.new()
	companion_chip.text = "Companion"
	companion_chip.button_pressed = bag_category == "companions"
	companion_chip.pressed.connect(_set_bag_category.bind("companions"))
	categories.add_child(companion_chip)
	var count_label := Label.new()
	count_label.name = "BagCountLabel"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_color", MUTED)
	content.add_child(count_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	bag_grid = GridContainer.new()
	bag_grid.name = "BagGrid"
	bag_grid.columns = 3
	bag_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_grid.add_theme_constant_override("h_separation", 7)
	bag_grid.add_theme_constant_override("v_separation", 7)
	scroll.add_child(bag_grid)
	_rebuild_bag_grid(count_label)


func _close_bag() -> void:
	if is_instance_valid(bag_overlay):
		bag_overlay.queue_free()
	bag_overlay = null
	bag_grid = null


func _set_bag_category(category_id: String) -> void:
	bag_category = category_id
	_close_bag()
	_show_bag()


func _rebuild_bag_grid(count_label: Label) -> void:
	for child in bag_grid.get_children():
		child.queue_free()
	var candidates: Array = Catalog.furniture().duplicate()
	var companion_definition := Catalog.companion(companion_id)
	candidates.push_front({"id": "companion_%s" % companion_id, "name": companion_definition.get("name", companion_id), "icon": "🦄", "category": "companions", "rarity": "legendary", "desc": "House gift companion"})
	var shown := 0
	for definition in candidates:
		var item_id := str(definition.get("id", ""))
		if bag_category != "all" and str(definition.get("category", "")) != bag_category:
			continue
		var available := AppState.available_count(item_id)
		if available <= 0:
			continue
		shown += 1
		var place := Button.new()
		place.text = ""
		place.tooltip_text = str(definition.get("desc", ""))
		place.custom_minimum_size = Vector2(0, 132)
		place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		place.pressed.connect(_place_from_bag.bind(item_id))
		bag_grid.add_child(place)
		var art := FurnitureArtScene.new()
		art.name = "FurnitureArt"
		art.set_anchor(SIDE_LEFT, 0.0)
		art.set_anchor(SIDE_TOP, 0.0)
		art.set_anchor(SIDE_RIGHT, 1.0)
		art.set_anchor(SIDE_BOTTOM, 0.0)
		art.offset_left = 8
		art.offset_top = 5
		art.offset_right = -8
		art.offset_bottom = 88
		art.setup(definition)
		place.add_child(art)
		var item_label := Label.new()
		item_label.text = "%s\nx%d" % [str(definition.get("name", item_id)), available]
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_label.add_theme_font_size_override("font_size", 12)
		item_label.set_anchor(SIDE_LEFT, 0.0)
		item_label.set_anchor(SIDE_TOP, 1.0)
		item_label.set_anchor(SIDE_RIGHT, 1.0)
		item_label.set_anchor(SIDE_BOTTOM, 1.0)
		item_label.offset_left = 4
		item_label.offset_top = -43
		item_label.offset_right = -4
		item_label.offset_bottom = -3
		item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		place.add_child(item_label)
	count_label.text = "%d available item%s" % [shown, "" if shown == 1 else "s"]
	if shown == 0:
		var empty := Label.new()
		empty.text = "Nothing available here. Buy decor in the Marketplace or remove a placed item."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", MUTED)
		bag_grid.add_child(empty)


func _place_from_bag(item_id: String) -> void:
	var items := AppState.room_items(companion_id)
	var item := {
		"instance_id": "%d_%d" % [Time.get_ticks_msec(), randi_range(100, 999)],
		"item_id": item_id,
		"x": Rules.snap(50.0, grid_snap),
		"y": Rules.snap(62.0, grid_snap),
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
		return {"name": definition.get("name", "Companion"), "icon": "🦄", "category": "companions"}
	return Catalog.furniture_item(item_id)


func _item_style(category: String, selected: bool) -> StyleBoxFlat:
	var colors := {"companions": PINK, "nature": Color("62e6a7"), "lighting": YELLOW, "luxury": Color("d5a4ff"), "pets": Color("ff9f7c"), "electronics": CYAN, "seasonal": Color("f59c5b"), "rugs": Color("c99cff"), "beds": Color("89a9ff"), "tables": Color("d49b6a"), "kitchen": Color("ffb66e"), "toys": Color("ff91bd"), "wall": Color("91c9ff"), "unicorn": Color("f68bd8"), "cozy": Color("9da9d9")}
	var color: Color = colors.get(category, Color("9da9d9"))
	var background := Color("12000000") if not selected else Color(color, 0.12)
	var style := _rounded_style(background, Color.WHITE if selected else Color("00000000"), 4 if selected else 0, 16)
	return style


func _rounded_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
