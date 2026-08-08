extends Control

const Catalog = preload("res://scripts/meta_catalog.gd")
const Rules = preload("res://scripts/room_rules.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const UnicornHeader = preload("res://scripts/ui/unicorn_header.gd")

const NAVY := Color("08112f")
const PANEL := Color("14214a")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const TEXT := Color("f7f1ff")
const MUTED := Color("aab7e8")
const DECOR_PAGE_SIZE := 24
const TOUCH_SCROLL_MULTIPLIER := 1.25
const COMPANION_PORTRAITS := {
	"sparkle": preload("res://assets/characters/unicorns/thumbnails/sparkle.png"),
	"rainbow": preload("res://assets/characters/unicorns/thumbnails/rainbow.png"),
	"star": preload("res://assets/characters/unicorns/thumbnails/star.png"),
	"cloud": preload("res://assets/characters/unicorns/thumbnails/cloud.png"),
	"dream": preload("res://assets/characters/unicorns/thumbnails/dream.png"),
	"mystic": preload("res://assets/characters/unicorns/thumbnails/mystic.png"),
}

signal scene_change_ready
signal catalog_build_complete

var root: VBoxContainer
var filters: VBoxContainer
var content: VBoxContainer
var catalog_scroll: ScrollContainer
var category_scroll: ScrollContainer
var coin_label: Label
var message_label: Label
var tab := "companions"
var category := "all"
var query := ""
var decor_page := 0
var catalog_dragging := false
var category_dragging := false
var suppress_catalog_actions_until_ms := 0
var _decor_build_generation := 0
var _scene_change_generation := 0


func _ready() -> void:
	_build_shell()
	_show_companions()


func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var header := UnicornHeader.build("MARKETPLACE", "HOME", _go_home, _go_home)
	root.add_child(header)
	coin_label = header.find_child("SharedCoinBalance", true, false) as Label
	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	var companions := _button("COMPANIONS", PANEL, 50)
	companions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	companions.pressed.connect(_show_companions)
	tabs.add_child(companions)
	var decor := _button("DECOR", PANEL, 50)
	decor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	decor.pressed.connect(_open_decor_tab)
	tabs.add_child(decor)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", YELLOW)
	message_label.custom_minimum_size.y = 24
	root.add_child(message_label)
	# Keep search/chips outside the list scroll. Nested ScrollContainers on Android
	# steal vertical drag and make the decor catalog feel locked.
	filters = VBoxContainer.new()
	filters.name = "MarketplaceFilters"
	filters.add_theme_constant_override("separation", 10)
	root.add_child(filters)
	catalog_scroll = ScrollContainer.new()
	catalog_scroll.name = "MarketplaceScroll"
	catalog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	catalog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	catalog_scroll.scroll_deadzone = 12
	catalog_scroll.follow_focus = false
	catalog_scroll.clip_contents = true
	root.add_child(catalog_scroll)
	content = VBoxContainer.new()
	content.name = "MarketplaceCatalog"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_theme_constant_override("separation", 10)
	catalog_scroll.add_child(content)
	catalog_scroll.resized.connect(_fit_catalog_width)
	_update_coins()


func _drain_content(generation: int) -> bool:
	var catalog_children := content.get_children()
	var filter_children := filters.get_children()
	_set_catalog_visible(false)
	await get_tree().process_frame
	category_scroll = null
	message_label.text = ""
	_update_coins()
	for child in filter_children:
		if child.get_parent() == filters:
			filters.remove_child(child)
		child.queue_free()
	await get_tree().process_frame
	if generation != _decor_build_generation:
		return false
	for start in range(0, catalog_children.size(), 12):
		if generation != _decor_build_generation:
			return false
		for child in catalog_children.slice(start, start + 12):
			if child.get_parent() == content:
				content.remove_child(child)
			child.queue_free()
		# Keep large decor-list teardown bounded across SceneTree frames.
		await get_tree().process_frame
	await get_tree().process_frame
	return generation == _decor_build_generation


func _set_catalog_visible(value: bool) -> void:
	content.visible = value
	filters.visible = value
	catalog_scroll.visible = value


func _fit_catalog_width() -> void:
	if is_instance_valid(content) and is_instance_valid(catalog_scroll):
		content.custom_minimum_size.x = catalog_scroll.size.x


func _show_companions() -> void:
	_decor_build_generation += 1
	var generation := _decor_build_generation
	tab = "companions"
	if not await _drain_content(generation) or generation != _decor_build_generation:
		return
	_build_companion_catalog()
	# Yield after card creation so callers always have a stable readiness
	# boundary, while Marketplace itself remains free of live SubViewports.
	await get_tree().process_frame
	if generation != _decor_build_generation or tab != "companions":
		return
	_set_catalog_visible(true)
	await get_tree().process_frame
	if generation != _decor_build_generation or tab != "companions":
		return
	catalog_build_complete.emit()


func _build_companion_catalog() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for definition in Catalog.companions():
		_add_companion_card(grid, definition)


func _add_companion_card(grid: GridContainer, definition: Dictionary) -> TextureRect:
	var id := str(definition["id"])
	var owned := id in AppState.owned_companions()
	var equipped := id == AppState.equipped_companion()
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(190, 252)
	card.add_theme_constant_override("separation", 6)
	grid.add_child(card)
	var portrait := TextureRect.new()
	portrait.name = "CompanionPortrait"
	portrait.custom_minimum_size = Vector2(112, 112)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = COMPANION_PORTRAITS.get(id)
	portrait.tooltip_text = "%s — authored marketplace portrait" % str(definition["name"])
	portrait.set_meta("source_model_id", id)
	card.add_child(portrait)
	var name := Label.new()
	name.text = str(definition["name"]).to_upper()
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 19)
	name.add_theme_constant_override("outline_size", 2)
	card.add_child(name)
	var desc := Label.new()
	desc.text = str(definition["desc"])
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", MUTED)
	desc.add_theme_font_size_override("font_size", 19)
	desc.add_theme_constant_override("outline_size", 2)
	desc.custom_minimum_size.y = 42
	card.add_child(desc)
	var action := _button("EQUIPPED" if equipped else ("EQUIP" if owned else "%d COINS" % int(definition["price"])), Color("286d58") if equipped else PANEL, 56)
	action.disabled = equipped or (not owned and AppState.coins() < int(definition["price"]))
	action.pressed.connect(_companion_action.bind(id, owned))
	card.add_child(action)
	return portrait


func _companion_action(companion_id: String, was_owned: bool) -> void:
	if was_owned:
		if AppState.equip_companion(companion_id):
			message_label.text = "%s equipped." % Catalog.companion(companion_id).get("name", companion_id)
	else:
		if AppState.buy_companion(companion_id):
			message_label.text = "%s adopted! Its house and room gift are unlocked." % Catalog.companion(companion_id).get("name", companion_id)
		else:
			message_label.text = "Not enough coins."
	_show_companions.call_deferred()


func _show_decor() -> void:
	tab = "decor"
	_decor_build_generation += 1
	var generation := _decor_build_generation
	if not await _drain_content(generation) or generation != _decor_build_generation or tab != "decor":
		return
	await _build_decor_catalog(generation)


func _build_decor_catalog(generation: int) -> void:
	var search := LineEdit.new()
	search.name = "DecorSearch"
	search.placeholder_text = "Search decor..."
	search.text = query
	search.custom_minimum_size.y = 58
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.add_theme_font_size_override("font_size", 19)
	search.add_theme_constant_override("outline_size", 2)
	StorybookUI.apply_line_edit(search)
	search.text_submitted.connect(_apply_decor_search)
	filters.add_child(search)
	category_scroll = ScrollContainer.new()
	category_scroll.name = "DecorCategoryScroll"
	category_scroll.custom_minimum_size.y = 66
	category_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	category_scroll.scroll_deadzone = 12
	category_scroll.follow_focus = false
	filters.add_child(category_scroll)
	var category_row := HBoxContainer.new()
	category_row.name = "DecorCategoryChips"
	category_row.add_theme_constant_override("separation", 8)
	category_scroll.add_child(category_row)
	for item in Catalog.categories():
		var category_id := str(item["id"])
		var chip := _button(str(item["label"]).to_upper(), PINK if category_id == category else PANEL, 56)
		chip.name = "Category_%s" % category_id
		chip.custom_minimum_size.x = maxf(94.0, float(str(item["label"]).length() * 12 + 34))
		chip.pressed.connect(_set_decor_category.bind(category_id))
		category_row.add_child(chip)
	message_label.text = "LOADING DECOR..."
	_set_catalog_visible(true)
	await get_tree().process_frame
	if generation != _decor_build_generation or tab != "decor":
		return
	var filtered := Catalog.filtered_furniture(category, query)
	var page_count := maxi(1, ceili(float(filtered.size()) / float(DECOR_PAGE_SIZE)))
	decor_page = clampi(decor_page, 0, page_count - 1)
	var page_start := decor_page * DECOR_PAGE_SIZE
	var shown_count := mini(DECOR_PAGE_SIZE, maxi(0, filtered.size() - page_start))
	var item_list := ItemList.new()
	item_list.name = "DecorItemList"
	item_list.custom_minimum_size = Vector2(0, 520)
	item_list.icon_mode = ItemList.ICON_MODE_TOP
	item_list.fixed_icon_size = Vector2i(96, 96)
	item_list.fixed_column_width = 148
	item_list.max_columns = 4
	item_list.allow_reselect = true
	item_list.tooltip_text = "Select a decor item to view details and actions."
	content.add_child(item_list)
	var page_items := filtered.slice(page_start, page_start + shown_count)
	for definition in page_items:
		var id := str(definition["id"])
		var index := item_list.add_item(str(definition["name"]).to_upper(), load("res://assets/store/decor_thumbnails/%s.png" % id))
		item_list.set_item_metadata(index, {"source_model_id": id, "icon_path": "res://assets/store/decor_thumbnails/%s.png" % id})
		item_list.set_item_tooltip(index, "%s — %s" % [str(definition["name"]), str(definition.get("desc", ""))])
		if (index + 1) % 4 == 0:
			await get_tree().process_frame
			if generation != _decor_build_generation or tab != "decor":
				return
	var detail := VBoxContainer.new()
	detail.name = "DecorSelectedDetail"
	detail.add_theme_constant_override("separation", 6)
	content.add_child(detail)
	item_list.item_selected.connect(_show_decor_detail.bind(page_items, detail))
	if not page_items.is_empty():
		item_list.select(0)
		_show_decor_detail(0, page_items, detail)
	if generation != _decor_build_generation or tab != "decor":
		return
	var pagination := HBoxContainer.new()
	pagination.name = "DecorPagination"
	pagination.add_theme_constant_override("separation", 10)
	content.add_child(pagination)
	var previous := _button("PREVIOUS", PANEL, 56)
	previous.name = "PreviousDecorPage"
	previous.disabled = decor_page <= 0
	previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	previous.pressed.connect(_previous_decor_page)
	pagination.add_child(previous)
	var page_indicator := Label.new()
	page_indicator.name = "DecorPageIndicator"
	page_indicator.text = "PAGE %d OF %d" % [decor_page + 1, page_count]
	page_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_indicator.custom_minimum_size = Vector2(160, 56)
	page_indicator.add_theme_font_size_override("font_size", 19)
	page_indicator.add_theme_constant_override("outline_size", 2)
	pagination.add_child(page_indicator)
	var next := _button("NEXT", PANEL, 56)
	next.name = "NextDecorPage"
	next.disabled = decor_page >= page_count - 1
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.pressed.connect(_next_decor_page)
	pagination.add_child(next)
	var alley := _button("VISIT UNICORN ALLEY", PINK, 60)
	alley.pressed.connect(_go_alley)
	content.add_child(alley)
	message_label.text = ""
	catalog_build_complete.emit()


func _show_decor_detail(index: int, page_items: Array, detail: VBoxContainer) -> void:
	for child in detail.get_children():
		child.queue_free()
	if index < 0 or index >= page_items.size():
		return
	var definition: Dictionary = page_items[index]
	var id := str(definition["id"])
	var name := Label.new()
	name.text = str(definition["name"]).to_upper()
	name.add_theme_font_size_override("font_size", 21)
	name.add_theme_constant_override("outline_size", 2)
	detail.add_child(name)
	var description := Label.new()
	description.text = "%s  •  %s\nOWNED %d  •  PLACED %d  •  BAG %d" % [str(definition.get("rarity", "common")).to_upper(), str(definition.get("desc", "")), int(AppState.data["inventory"].get(id, 0)), AppState.placed_count(id), AppState.available_count(id)]
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", MUTED)
	description.add_theme_font_size_override("font_size", 19)
	description.add_theme_constant_override("outline_size", 2)
	detail.add_child(description)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	detail.add_child(actions)
	var buy := _button("★ %d   BUY" % int(definition["price"]), PANEL, 60)
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.disabled = AppState.coins() < int(definition["price"])
	buy.pressed.connect(_buy_decor.bind(id))
	actions.add_child(buy)
	if AppState.available_count(id) > 0:
		var sell := _button("SELL   +★ %d" % Rules.sell_refund(int(definition["price"])), Color("4a2859"), 60)
		sell.pressed.connect(_sell_decor.bind(id))
		actions.add_child(sell)


func _open_decor_tab() -> void:
	decor_page = 0
	_show_decor()
	catalog_scroll.set_deferred("scroll_vertical", 0)


func _apply_decor_search(value: String) -> void:
	query = value
	decor_page = 0
	_show_decor()
	catalog_scroll.set_deferred("scroll_vertical", 0)


func _set_decor_category(category_id: String) -> void:
	if Time.get_ticks_msec() < suppress_catalog_actions_until_ms:
		return
	category = category_id
	decor_page = 0
	_show_decor()
	catalog_scroll.set_deferred("scroll_vertical", 0)


func _previous_decor_page() -> void:
	if decor_page <= 0:
		return
	decor_page -= 1
	_show_decor()
	catalog_scroll.set_deferred("scroll_vertical", 0)


func _next_decor_page() -> void:
	var filtered_count := Catalog.filtered_furniture(category, query).size()
	if (decor_page + 1) * DECOR_PAGE_SIZE >= filtered_count:
		return
	decor_page += 1
	_show_decor()
	catalog_scroll.set_deferred("scroll_vertical", 0)


func _input(event: InputEvent) -> void:
	if tab != "decor" or not is_instance_valid(catalog_scroll):
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if is_instance_valid(category_scroll) and category_scroll.get_global_rect().has_point(drag.position) and absf(drag.relative.x) > absf(drag.relative.y):
			category_scroll.scroll_horizontal -= roundi(drag.relative.x * TOUCH_SCROLL_MULTIPLIER)
			category_dragging = true
			get_viewport().set_input_as_handled()
			return
		if not catalog_scroll.get_global_rect().has_point(drag.position):
			return
		if absf(drag.relative.y) <= absf(drag.relative.x):
			return
		catalog_scroll.scroll_vertical -= roundi(drag.relative.y * TOUCH_SCROLL_MULTIPLIER)
		catalog_dragging = true
		# Drop LineEdit focus so the list can take over the gesture.
		var focused := get_viewport().gui_get_focus_owner()
		if focused != null and focused is LineEdit:
			focused.release_focus()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		if catalog_dragging or category_dragging:
			catalog_dragging = false
			category_dragging = false
			suppress_catalog_actions_until_ms = Time.get_ticks_msec() + 220


func _buy_decor(item_id: String) -> void:
	if Time.get_ticks_msec() < suppress_catalog_actions_until_ms:
		return
	var previous_scroll := catalog_scroll.scroll_vertical
	message_label.text = "Purchased." if AppState.buy_furniture(item_id) else "Not enough coins."
	_show_decor()
	catalog_scroll.set_deferred("scroll_vertical", previous_scroll)


func _sell_decor(item_id: String) -> void:
	if Time.get_ticks_msec() < suppress_catalog_actions_until_ms:
		return
	var previous_scroll := catalog_scroll.scroll_vertical
	message_label.text = "Sold one unused item." if AppState.sell_furniture(item_id) else "Only unused bag items can be sold."
	_show_decor()
	catalog_scroll.set_deferred("scroll_vertical", previous_scroll)


func _update_coins() -> void:
	coin_label.text = str(AppState.coins())


func prepare_for_scene_change() -> Signal:
	_decor_build_generation += 1
	_scene_change_generation += 1
	_finish_scene_change_cleanup(_scene_change_generation)
	return scene_change_ready


func _finish_scene_change_cleanup(generation: int) -> void:
	if await _drain_content(_decor_build_generation) and generation == _scene_change_generation:
		scene_change_ready.emit()


func _go_home() -> void:
	AppState.shell_view = "home"
	await prepare_for_scene_change()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _go_alley() -> void:
	await prepare_for_scene_change()
	get_tree().change_scene_to_file("res://scenes/meta/unicorn_alley.tscn")


func _button(text: String, color: Color, height: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = height
	StorybookUI.apply_button(button, color, StorybookUI.uses_dark_ink(color))
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_constant_override("outline_size", 2)
	return button


func _rarity_color(rarity: String) -> Color:
	return {"common": MUTED, "uncommon": Color("62e6a7"), "rare": Color("6da9ff"), "legendary": YELLOW}.get(rarity, MUTED)


func _decor_card_style(border: Color) -> StyleBoxFlat:
	var style := StorybookUI.plaque_style(Color("111c41"), border, 18)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _preview_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202f5e")
	style.border_color = Color("e1ae4f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _badge_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(10)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style
