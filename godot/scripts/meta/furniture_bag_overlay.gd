class_name FurnitureBagOverlay
extends Control

signal item_selected(item_id: String)
signal closed

const Catalog = preload("res://scripts/meta_catalog.gd")
const CompanionAssets = preload("res://scripts/meta/companion_asset_catalog.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const ScrollTapGuard = preload("res://scripts/ui/scroll_tap_guard.gd")
const DECOR_THUMBNAIL_DIRECTORY := "res://assets/store/decor_thumbnails/"
const MUTED := Color("aab7e8")
const SCROLL_TOUCH_DEADZONE := 12.0

var companion_id := "sparkle"
var category := "all"
var grid: GridContainer
var category_scroll: ScrollContainer
var catalog_scroll: ScrollContainer
var category_tap_guard := ScrollTapGuard.new(SCROLL_TOUCH_DEADZONE)
var catalog_tap_guard := ScrollTapGuard.new(SCROLL_TOUCH_DEADZONE)
var _closed_emitted := false


func setup(owner_companion_id: String, initial_category := "all") -> void:
	companion_id = owner_companion_id
	category = initial_category
	_build_overlay()


func close() -> void:
	if _closed_emitted:
		return
	_closed_emitted = true
	closed.emit()
	if is_inside_tree() and not is_queued_for_deletion():
		queue_free()


func _build_overlay() -> void:
	name = "FurnitureBagOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 4000
	var dim := ColorRect.new()
	dim.color = Color("050a20a8")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
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
	sheet.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("17254dfa"), StorybookUI.GOLD, 24))
	add_child(sheet)
	var sheet_margin := MarginContainer.new()
	sheet_margin.add_theme_constant_override("margin_left", 16)
	sheet_margin.add_theme_constant_override("margin_right", 16)
	sheet_margin.add_theme_constant_override("margin_top", 12)
	sheet_margin.add_theme_constant_override("margin_bottom", 12)
	sheet.add_child(sheet_margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	sheet_margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Close furniture bag"
	close_button.custom_minimum_size = Vector2(48, 48)
	close_button.add_theme_font_size_override("font_size", 26)
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var title := Label.new()
	title.text = "FURNITURE BAG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", StorybookUI.CREAM)
	title.add_theme_color_override("font_outline_color", StorybookUI.PLUM)
	title.add_theme_constant_override("outline_size", 3)
	header.add_child(title)
	var shop := Button.new()
	shop.text = "SHOP"
	shop.custom_minimum_size = Vector2(82, 56)
	shop.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta/marketplace.tscn"))
	header.add_child(shop)
	category_scroll = ScrollContainer.new()
	category_scroll.name = "FurnitureBagCategoryScroll"
	category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	category_scroll.scroll_deadzone = 12
	category_scroll.custom_minimum_size.y = 58
	category_scroll.gui_input.connect(_on_bag_category_scroll_gui_input)
	category_scroll.scroll_started.connect(_on_bag_scroll_started.bind(category_tap_guard))
	category_scroll.scroll_ended.connect(_on_bag_scroll_ended.bind(category_tap_guard))
	content.add_child(category_scroll)
	var categories := HBoxContainer.new()
	categories.add_theme_constant_override("separation", 6)
	categories.mouse_filter = Control.MOUSE_FILTER_PASS
	category_scroll.add_child(categories)
	for category_data in Catalog.categories():
		var chip := Button.new()
		var category_id := str(category_data.get("id", "all"))
		chip.text = str(category_data.get("label", category_id))
		chip.button_pressed = category_id == category
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.pressed.connect(_set_bag_category.bind(category_id))
		categories.add_child(chip)
	var companion_chip := Button.new()
	companion_chip.text = "Companion"
	companion_chip.button_pressed = category == "companions"
	companion_chip.mouse_filter = Control.MOUSE_FILTER_PASS
	companion_chip.pressed.connect(_set_bag_category.bind("companions"))
	categories.add_child(companion_chip)
	var count_label := Label.new()
	count_label.name = "BagCountLabel"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_color", MUTED)
	content.add_child(count_label)
	catalog_scroll = ScrollContainer.new()
	catalog_scroll.name = "FurnitureBagScroll"
	catalog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	catalog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	catalog_scroll.scroll_deadzone = 12
	catalog_scroll.follow_focus = false
	catalog_scroll.clip_contents = true
	catalog_scroll.gui_input.connect(_on_bag_catalog_scroll_gui_input)
	catalog_scroll.scroll_started.connect(_on_bag_scroll_started.bind(catalog_tap_guard))
	catalog_scroll.scroll_ended.connect(_on_bag_scroll_ended.bind(catalog_tap_guard))
	content.add_child(catalog_scroll)
	grid = GridContainer.new()
	grid.name = "BagGrid"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	catalog_scroll.add_child(grid)
	catalog_scroll.resized.connect(func() -> void:
		if is_instance_valid(grid):
			grid.custom_minimum_size.x = catalog_scroll.size.x
	)
	_rebuild_bag_grid(count_label)


func _on_bag_category_scroll_gui_input(event: InputEvent) -> void:
	_observe_bag_scroll_gesture(category_tap_guard, "category", "horizontal", event)


func _on_bag_catalog_scroll_gui_input(event: InputEvent) -> void:
	_observe_bag_scroll_gesture(catalog_tap_guard, "catalog", "vertical", event)


func _observe_bag_scroll_gesture(guard: ScrollTapGuard, surface: String, axis: String, event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			guard.begin(surface, axis, touch)
		else:
			guard.finish(touch)
	elif event is InputEventScreenDrag:
		# ScrollContainer owns physical movement. The guard only observes the
		# matching touch and dominant axis for post-scroll action suppression.
		guard.observe_drag(event as InputEventScreenDrag)


func _on_bag_scroll_started(guard: ScrollTapGuard) -> void:
	guard.on_scroll_started()


func _on_bag_scroll_ended(guard: ScrollTapGuard) -> void:
	guard.on_scroll_ended()


func is_action_suppressed() -> bool:
	return category_tap_guard.is_action_suppressed() or catalog_tap_guard.is_action_suppressed()


func _set_bag_category(category_id: String) -> void:
	if is_action_suppressed():
		return
	category = category_id
	for child in get_children():
		child.queue_free()
	grid = null
	category_scroll = null
	catalog_scroll = null
	category_tap_guard = ScrollTapGuard.new(SCROLL_TOUCH_DEADZONE)
	catalog_tap_guard = ScrollTapGuard.new(SCROLL_TOUCH_DEADZONE)
	_build_overlay()


func _select_item(item_id: String) -> void:
	if not is_action_suppressed():
		item_selected.emit(item_id)


func _add_cached_decor_preview(parent: Control, definition: Dictionary, yaw: float, room_item: bool) -> void:
	var preview := TextureRect.new()
	preview.name = "CachedDecorPreview"
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if room_item:
		preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		preview.set_anchor(SIDE_LEFT, 0.0)
		preview.set_anchor(SIDE_TOP, 0.0)
		preview.set_anchor(SIDE_RIGHT, 1.0)
		preview.set_anchor(SIDE_BOTTOM, 0.0)
		preview.offset_left = 8
		preview.offset_top = 5
		preview.offset_right = -8
		preview.offset_bottom = 88
	parent.add_child(preview)
	_refresh_cached_decor_preview(parent, definition, yaw)


func _refresh_cached_decor_preview(parent: Control, definition: Dictionary, yaw: float) -> void:
	var preview := parent.get_node_or_null("CachedDecorPreview") as TextureRect
	if not is_instance_valid(preview):
		return
	var item_id := str(definition.get("id", definition.get("item_id", "")))
	if item_id.begins_with("companion_"):
		_apply_decor_preview(preview, load(CompanionAssets.thumbnail_path(item_id.trim_prefix("companion_"))) as Texture2D)
		return
	var key := DecorPreviewCache.cache_key(definition, yaw)
	preview.set_meta("decor_preview_key", key)
	var cached := DecorPreviewCache.cached_texture(definition, yaw)
	if cached != null:
		_apply_decor_preview(preview, cached)
		return
	_apply_decor_preview(preview, _decor_thumbnail(item_id))
	DecorPreviewCache.request(definition, yaw, Callable(self, "_apply_cached_preview").bind(preview.get_instance_id(), definition.duplicate(true), yaw))


func _decor_thumbnail(item_id: String) -> Texture2D:
	return load("%s%s.png" % [DECOR_THUMBNAIL_DIRECTORY, item_id]) as Texture2D


func _apply_cached_preview(texture: Texture2D, preview_instance_id: int, definition: Dictionary, yaw: float) -> void:
	var preview := instance_from_id(preview_instance_id) as TextureRect
	var key := DecorPreviewCache.cache_key(definition, yaw)
	if is_instance_valid(preview) and texture != null and str(preview.get_meta("decor_preview_key", "")) == key:
		_apply_decor_preview(preview, texture)


func _apply_decor_preview(preview: TextureRect, texture: Texture2D) -> void:
	preview.texture = texture
	# Decor orientation belongs to the rendered 3D DisplayRotationRoot. A
	# thumbnail fallback is deliberately upright rather than screen-rotated.
	preview.rotation_degrees = 0.0


func _rebuild_bag_grid(count_label: Label) -> void:
	grid.columns = 3
	for child in grid.get_children():
		child.queue_free()
	var candidates: Array = Catalog.furniture().duplicate()
	var companion_definition := Catalog.companion(companion_id)
	candidates.push_front({"id": "companion_%s" % companion_id, "name": companion_definition.get("name", companion_id), "icon": "🦄", "category": "companions", "rarity": "legendary", "desc": "House gift companion"})
	var shown := 0
	for definition in candidates:
		var item_id := str(definition.get("id", ""))
		if category != "all" and str(definition.get("category", "")) != category:
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
		# Route a drag beginning on an item to the outer bag ScrollContainer.
		place.mouse_filter = Control.MOUSE_FILTER_PASS
		place.pressed.connect(_select_item.bind(item_id))
		grid.add_child(place)
		_add_cached_decor_preview(place, definition, 0.0, false)
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
		grid.columns = 1
		var empty := Label.new()
		empty.name = "EmptyBagMessage"
		empty.text = "Nothing available here. Buy decor in the Marketplace or remove a placed item."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(600, 150)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", MUTED)
		grid.add_child(empty)
