extends Control

# Marketplace deliberately owns a small, immutable Control tree.  Godot 4.7.1
# can recurse through Container minimum-size notifications when a long catalog
# is appended or rebuilt during a touch scroll, so cards are a fixed pool and
# only their contents change after _ready.
const Catalog = preload("res://scripts/meta_catalog.gd")
const Rules = preload("res://scripts/room_rules.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")

const NAVY := Color("08112f")
const PANEL := Color("14214a")
const PINK := Color("b83f7c")
const GOLD := Color("e1ae4f")
const CREAM := Color("fff3d6")
const MUTED := Color("c9d3ef")
const CYAN := Color("58d6e8")
const DECOR_SLOTS := 8
const DECOR_CARD_HEIGHT := 188.0
const CATALOG_CONTENT_HEIGHT := 1636.0
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

var content: Control
var catalog_scroll: ScrollContainer
var category_scroll: ScrollContainer
var coin_label: Label
var message_label: Label
var tab := "companions"
var category := "all"
var query := ""
var catalog_ready := false
var _decor_filtered: Array = []
var _decor_page := 0
var _companion_cards: Array[Dictionary] = []
var _decor_cards: Array[Dictionary] = []
var _category_chips: Array[Button] = []
var _companions_panel: Control
var _decor_panel: Control
var _search: LineEdit
var _search_button: Button
var _page_label: Label
var _previous_button: Button
var _next_button: Button
var _companions_tab: Button
var _decor_tab: Button
var category_dragging := false
var _category_touch_active := false
var _category_touch_start := Vector2.ZERO
var _category_scroll_start := 0
var _category_suppress_until_ms := 0
var catalog_dragging := false
var _catalog_touch_active := false
var _catalog_touch_start := Vector2.ZERO
var _catalog_scroll_start := 0
var _catalog_suppress_until_ms := 0


func _ready() -> void:
	_build_fixed_tree()
	_show_companions()
	catalog_ready = true
	catalog_build_complete.emit()


func _build_fixed_tree() -> void:
	var background := ColorRect.new()
	background.name = "MarketplaceBackground"
	background.color = NAVY
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_build_header()
	_build_tabs()
	message_label = _label("MarketplaceMessage", "", Vector2.ZERO, Vector2.ZERO, CREAM, 18)
	_anchor_rect(message_label, 0.0, 1.0, 14, -14, 140, 167)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.clip_text = true
	_build_decor_filters()

	catalog_scroll = ScrollContainer.new()
	catalog_scroll.name = "MarketplaceScroll"
	catalog_scroll.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	catalog_scroll.anchor_top = 0.0
	catalog_scroll.anchor_bottom = 1.0
	catalog_scroll.offset_left = 14
	catalog_scroll.offset_right = -14
	catalog_scroll.offset_top = 168
	catalog_scroll.offset_bottom = -20
	catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	catalog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	catalog_scroll.scroll_deadzone = 4
	catalog_scroll.follow_focus = false
	catalog_scroll.clip_contents = true
	catalog_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(catalog_scroll)

	content = Control.new()
	content.name = "MarketplaceCatalog"
	content.set_anchors_preset(Control.PRESET_TOP_WIDE)
	content.offset_bottom = CATALOG_CONTENT_HEIGHT
	content.custom_minimum_size = Vector2(0, CATALOG_CONTENT_HEIGHT)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	catalog_scroll.add_child(content)
	_build_companion_pool()
	_build_decor_pool()


func _build_header() -> void:
	var header := Panel.new()
	header.name = "MarketplaceHeader"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 16
	header.offset_right = -16
	header.offset_top = 14
	header.offset_bottom = 72
	header.add_theme_stylebox_override("panel", StorybookUI.button_style(PANEL, GOLD, 3, 14))
	add_child(header)
	var title := _label("MarketplaceTitle", "MARKETPLACE", Vector2.ZERO, Vector2.ZERO, CREAM, 20, header)
	_anchor_rect(title, 0.5, 0.5, -90, 90, 7, 51)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var home := Button.new()
	home.name = "MarketplaceHome"
	home.set_meta("compact_header_control", true)
	home.set_meta("standard_game_chrome", true)
	home.tooltip_text = "Home"
	home.text = ""
	StorybookUI.apply_button(home, Color("22345f"), false, 12)
	_compact_header_button(home)
	home.custom_minimum_size = Vector2(48, 48)
	_anchor_rect(home, 1.0, 1.0, -138, -90, 5, 53)
	var home_glyph := TextureRect.new()
	home_glyph.name = "MarketplaceHomeGlyph"
	home_glyph.texture = load(StorybookUI.UNICORN_HOUSE_HOME_ICON_PATH) as Texture2D
	home_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	home_glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_anchor_rect(home_glyph, 0.5, 0.5, -12, 12, 12, 36)
	home.add_child(home_glyph)
	home.pressed.connect(_go_home)
	header.add_child(home)
	var coin_icon := _label("MarketplaceCoinIcon", "★", Vector2.ZERO, Vector2.ZERO, GOLD, 26, header)
	coin_icon.text = "★"
	_anchor_rect(coin_icon, 1.0, 1.0, -86, -60, 9, 47)
	coin_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_label = _label("MarketplaceCoinBalance", str(AppState.coins()), Vector2.ZERO, Vector2.ZERO, CREAM, 18, header)
	_anchor_rect(coin_label, 1.0, 1.0, -56, -8, 11, 45)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_tabs() -> void:
	_companions_tab = _button("CompanionsTab", "COMPANIONS", Vector2.ZERO, Vector2.ZERO, PANEL)
	_anchor_rect(_companions_tab, 0.0, 0.5, 16, -3, 82, 132)
	_companions_tab.pressed.connect(_show_companions)
	_decor_tab = _button("DecorTab", "DECOR", Vector2.ZERO, Vector2.ZERO, PANEL)
	_anchor_rect(_decor_tab, 0.5, 1.0, 3, -16, 82, 132)
	_decor_tab.pressed.connect(_open_decor_tab)


func _build_decor_filters() -> void:
	_search = LineEdit.new()
	_search.name = "DecorSearch"
	_anchor_rect(_search, 0.0, 1.0, 14, -162, 169, 225)
	_search.placeholder_text = "Search decor"
	_search.add_theme_font_size_override("font_size", 19)
	_search.add_theme_constant_override("outline_size", 2)
	_search.custom_minimum_size = Vector2(358, 56)
	StorybookUI.apply_line_edit(_search)
	add_child(_search)
	_search_button = _button("ApplyDecorSearch", "SEARCH", Vector2.ZERO, Vector2.ZERO, PANEL)
	_anchor_rect(_search_button, 1.0, 1.0, -154, -14, 169, 225)
	_search_button.pressed.connect(_apply_decor_search)

	category_scroll = ScrollContainer.new()
	category_scroll.name = "DecorCategoryScroll"
	_anchor_rect(category_scroll, 0.0, 1.0, 14, -14, 233, 291)
	category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	category_scroll.scroll_deadzone = 4
	category_scroll.follow_focus = false
	category_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	category_scroll.clip_contents = true
	add_child(category_scroll)
	var chips := Control.new()
	chips.name = "DecorCategoryChips"
	chips.custom_minimum_size = Vector2(1360, 52)
	chips.mouse_filter = Control.MOUSE_FILTER_PASS
	category_scroll.add_child(chips)
	var x := 0.0
	for definition in Catalog.categories():
		var id := str(definition.get("id", "all"))
		var label := str(definition.get("label", id)).to_upper()
		var width := maxf(96.0, label.length() * 11.0 + 28.0)
		var chip := _button("Category_%s" % id, label, Vector2(x, 0), Vector2(width, 48), PANEL, chips)
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.pressed.connect(_guarded_category_action.bind(id))
		_category_chips.append(chip)
		x += width + 8.0
	chips.custom_minimum_size.x = x


func _build_companion_pool() -> void:
	_companions_panel = Control.new()
	_companions_panel.name = "CompanionCatalog"
	_companions_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_companions_panel.offset_bottom = CATALOG_CONTENT_HEIGHT
	_companions_panel.custom_minimum_size = Vector2(0, CATALOG_CONTENT_HEIGHT)
	_companions_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_companions_panel)
	var definitions := Catalog.companions()
	for index in definitions.size():
		var col := index % 2
		var row := index / 2
		var card := Panel.new()
		card.name = "CompanionCard_%s" % str(definitions[index].get("id", index))
		_anchor_rect(card, 0.0 if col == 0 else 0.5, 0.5 if col == 0 else 1.0, 4 if col == 0 else 3, -3 if col == 0 else -4, 8 + row * 262, 264 + row * 262)
		card.set_meta("source_model_id", str(definitions[index].get("id", "")))
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("111c41"), GOLD, 15))
		_companions_panel.add_child(card)
		var portrait := TextureRect.new()
		portrait.name = "CompanionPortrait"
		_anchor_rect(portrait, 0.5, 0.5, -60, 60, 10, 112)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.set_meta("source_model_id", str(definitions[index].get("id", "")))
		card.add_child(portrait)
		var name := _label("CompanionName", "", Vector2.ZERO, Vector2.ZERO, CREAM, 18, card)
		_anchor_rect(name, 0.0, 1.0, 10, -10, 112, 137)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var description := _label("CompanionDescription", "", Vector2.ZERO, Vector2.ZERO, MUTED, 16, card)
		_anchor_rect(description, 0.0, 1.0, 10, -10, 140, 191)
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		var action := _button("CompanionAction", "", Vector2.ZERO, Vector2.ZERO, PANEL, card)
		_anchor_rect(action, 0.0, 1.0, 12, -12, 198, 254)
		action.pressed.connect(_companion_action.bind(index))
		_companion_cards.append({"definition": definitions[index], "card": card, "portrait": portrait, "name": name, "description": description, "action": action})


func _build_decor_pool() -> void:
	_decor_panel = Control.new()
	_decor_panel.name = "DecorCatalog"
	_decor_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_decor_panel.offset_bottom = CATALOG_CONTENT_HEIGHT
	_decor_panel.custom_minimum_size = Vector2(0, CATALOG_CONTENT_HEIGHT)
	_decor_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_decor_panel.visible = false
	content.add_child(_decor_panel)
	for index in DECOR_SLOTS:
		var card := Panel.new()
		card.name = "DecorCardSlot_%d" % index
		_anchor_rect(card, 0.0, 1.0, 2, -2, index * DECOR_CARD_HEIGHT, index * DECOR_CARD_HEIGHT + DECOR_CARD_HEIGHT - 8)
		card.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("111c41"), GOLD, 14))
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		_decor_panel.add_child(card)
		var thumbnail := TextureRect.new()
		thumbnail.name = "CatalogModelThumbnail"
		_anchor_rect(thumbnail, 0.0, 0.0, 12, 130, 18, 136)
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(thumbnail)
		var name := _label("DecorName", "", Vector2.ZERO, Vector2.ZERO, CREAM, 18, card)
		_anchor_rect(name, 0.0, 1.0, 142, -164, 12, 36)
		var rarity := _label("DecorRarity", "", Vector2.ZERO, Vector2.ZERO, GOLD, 14, card)
		_anchor_rect(rarity, 1.0, 1.0, -156, -12, 12, 36)
		rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rarity.clip_text = false
		_restore_catalog_rarity_font.call_deferred(rarity)
		var description := _label("DecorDescription", "", Vector2.ZERO, Vector2.ZERO, MUTED, 15, card)
		_anchor_rect(description, 0.0, 1.0, 142, -12, 40, 83)
		var counts := _label("DecorCounts", "", Vector2.ZERO, Vector2.ZERO, CYAN, 14, card)
		_anchor_rect(counts, 0.0, 1.0, 142, -12, 97, 119)
		var buy := _button("DecorBuy", "", Vector2.ZERO, Vector2.ZERO, PANEL, card)
		_anchor_rect(buy, 0.0, 0.5, 142, 82, 124, 180)
		buy.pressed.connect(_buy_decor.bind(index))
		var sell := _button("DecorSell", "", Vector2.ZERO, Vector2.ZERO, Color("4a2859"), card)
		_anchor_rect(sell, 0.5, 1.0, 92, -12, 124, 180)
		sell.pressed.connect(_sell_decor.bind(index))
		_decor_cards.append({"card": card, "thumbnail": thumbnail, "name": name, "rarity": rarity, "description": description, "counts": counts, "buy": buy, "sell": sell, "item": {}})
	var pager := Panel.new()
	pager.name = "DecorPager"
	_anchor_rect(pager, 0.0, 1.0, 2, -2, DECOR_SLOTS * DECOR_CARD_HEIGHT, DECOR_SLOTS * DECOR_CARD_HEIGHT + 62)
	pager.add_theme_stylebox_override("panel", StorybookUI.button_style(PANEL, GOLD, 2, 12))
	_decor_panel.add_child(pager)
	_previous_button = _button("DecorPrevious", "PREVIOUS", Vector2.ZERO, Vector2.ZERO, PANEL, pager)
	_anchor_rect(_previous_button, 0.0, 0.0, 8, 146, 7, 55)
	_previous_button.pressed.connect(_previous_decor_page)
	_page_label = _label("DecorPage", "", Vector2.ZERO, Vector2.ZERO, CREAM, 16, pager)
	_anchor_rect(_page_label, 0.0, 1.0, 152, -152, 8, 54)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_next_button = _button("DecorNext", "NEXT", Vector2.ZERO, Vector2.ZERO, PANEL, pager)
	_anchor_rect(_next_button, 1.0, 1.0, -146, -8, 7, 55)
	_next_button.pressed.connect(_next_decor_page)
	var alley := _button("MarketplaceAlley", "UNICORN ALLEY", Vector2.ZERO, Vector2.ZERO, PINK, _decor_panel)
	_anchor_rect(alley, 0.0, 1.0, 2, -2, DECOR_SLOTS * DECOR_CARD_HEIGHT + 66, DECOR_SLOTS * DECOR_CARD_HEIGHT + 120)
	alley.pressed.connect(_go_alley)


func _show_companions() -> void:
	tab = "companions"
	_companions_panel.visible = true
	_decor_panel.visible = false
	_search.visible = false
	_search_button.visible = false
	category_scroll.visible = false
	catalog_scroll.offset_top = 168
	catalog_scroll.scroll_vertical = 0
	message_label.text = ""
	_refresh_companions()
	_refresh_chrome()


func _open_decor_tab() -> void:
	tab = "decor"
	_companions_panel.visible = false
	_decor_panel.visible = true
	_search.visible = true
	_search_button.visible = true
	category_scroll.visible = true
	catalog_scroll.offset_top = 301
	catalog_scroll.scroll_vertical = 0
	_decor_page = 0
	_refresh_decor_filter()
	_refresh_chrome()


func _show_decor() -> void:
	_open_decor_tab()


func _refresh_companions() -> void:
	for card_data in _companion_cards:
		var definition: Dictionary = card_data["definition"]
		var id := str(definition.get("id", ""))
		var owned := id in AppState.owned_companions()
		var equipped := id == AppState.equipped_companion()
		(card_data["portrait"] as TextureRect).texture = COMPANION_PORTRAITS.get(id)
		(card_data["name"] as Label).text = str(definition.get("name", id)).to_upper()
		(card_data["description"] as Label).text = _manual_wrap(str(definition.get("desc", "")), 25, 2)
		var action := card_data["action"] as Button
		action.text = "EQUIPPED" if equipped else ("EQUIP" if owned else "★ %d  BUY" % int(definition.get("price", 0)))
		action.disabled = equipped or (not owned and AppState.coins() < int(definition.get("price", 0)))


func _refresh_decor_filter() -> void:
	_decor_filtered = Catalog.filtered_furniture(category, query)
	var pages := _decor_page_count()
	_decor_page = clampi(_decor_page, 0, pages - 1)
	_refresh_decor_cards()
	for chip in _category_chips:
		var active := chip.name == "Category_%s" % category
		StorybookUI.apply_button(chip, PINK if active else PANEL, false)


func _refresh_decor_cards() -> void:
	var first := _decor_page * DECOR_SLOTS
	for slot_index in _decor_cards.size():
		var card_data: Dictionary = _decor_cards[slot_index]
		var card := card_data["card"] as Panel
		var item: Dictionary = _decor_filtered[first + slot_index] if first + slot_index < _decor_filtered.size() else {}
		card_data["item"] = item
		card.visible = not item.is_empty()
		if item.is_empty():
			continue
		var id := str(item.get("id", ""))
		card.name = "DecorCard_%s" % id
		(card_data["thumbnail"] as TextureRect).texture = load("res://assets/store/decor_thumbnails/%s.png" % id)
		(card_data["thumbnail"] as TextureRect).set_meta("source_model_id", id)
		(card_data["name"] as Label).text = str(item.get("name", id)).to_upper()
		(card_data["rarity"] as Label).text = str(item.get("rarity", "common")).to_upper()
		(card_data["description"] as Label).text = _manual_wrap(str(item.get("desc", "")), 41, 2)
		(card_data["counts"] as Label).text = "OWNED %d  •  PLACED %d  •  BAG %d" % [int(AppState.data.get("inventory", {}).get(id, 0)), AppState.placed_count(id), AppState.available_count(id)]
		var buy := card_data["buy"] as Button
		buy.text = "★ %d  BUY" % int(item.get("price", 0))
		buy.disabled = AppState.coins() < int(item.get("price", 0))
		var sell := card_data["sell"] as Button
		sell.text = "SELL +★ %d" % Rules.sell_refund(int(item.get("price", 0)))
		sell.disabled = AppState.available_count(id) <= 0
	_page_label.text = "PAGE %d / %d" % [_decor_page + 1, _decor_page_count()]
	_previous_button.disabled = _decor_page <= 0
	_next_button.disabled = _decor_page >= _decor_page_count() - 1


func _refresh_chrome() -> void:
	_update_coins()
	_companions_tab.disabled = tab == "companions"
	_decor_tab.disabled = tab == "decor"


func _apply_decor_search() -> void:
	query = _search.text.strip_edges()
	_decor_page = 0
	catalog_scroll.scroll_vertical = 0
	_refresh_decor_filter()
	message_label.text = ""


func _set_decor_category(category_id: String) -> void:
	category = category_id
	_decor_page = 0
	catalog_scroll.scroll_vertical = 0
	_refresh_decor_filter()


func _guarded_category_action(category_id: String) -> void:
	if Time.get_ticks_msec() < _category_suppress_until_ms:
		return
	_set_decor_category(category_id)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if tab == "decor" and category_scroll.visible and category_scroll.get_global_rect().has_point(touch.position):
				_category_touch_active = true
				category_dragging = false
				_category_touch_start = touch.position
				_category_scroll_start = category_scroll.scroll_horizontal
			elif catalog_scroll.get_global_rect().has_point(touch.position):
				_catalog_touch_active = true
				catalog_dragging = false
				_catalog_touch_start = touch.position
				_catalog_scroll_start = catalog_scroll.scroll_vertical
		elif not touch.pressed:
			if category_dragging:
				_category_suppress_until_ms = Time.get_ticks_msec() + 220
			if catalog_dragging:
				_catalog_suppress_until_ms = Time.get_ticks_msec() + 220
			_category_touch_active = false
			category_dragging = false
			_catalog_touch_active = false
			catalog_dragging = false
	elif event is InputEventScreenDrag and _category_touch_active:
		var drag := event as InputEventScreenDrag
		var delta := drag.position - _category_touch_start
		if not category_dragging and absf(delta.x) > absf(delta.y) and absf(delta.x) >= category_scroll.scroll_deadzone:
			category_dragging = true
		if category_dragging:
			var bar := category_scroll.get_h_scroll_bar()
			var maximum := maxi(0, int(round(bar.max_value - bar.page)))
			category_scroll.scroll_horizontal = clampi(_category_scroll_start - int(round(delta.x)), 0, maximum)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _catalog_touch_active:
		var catalog_drag := event as InputEventScreenDrag
		var catalog_delta := catalog_drag.position - _catalog_touch_start
		if not catalog_dragging and absf(catalog_delta.y) > absf(catalog_delta.x) and absf(catalog_delta.y) >= catalog_scroll.scroll_deadzone:
			catalog_dragging = true
		if catalog_dragging:
			var catalog_bar := catalog_scroll.get_v_scroll_bar()
			var catalog_maximum := maxi(0, int(round(catalog_bar.max_value - catalog_bar.page)))
			catalog_scroll.scroll_vertical = clampi(_catalog_scroll_start - int(round(catalog_delta.y)), 0, catalog_maximum)
			get_viewport().set_input_as_handled()


func _catalog_action_suppressed() -> bool:
	return Time.get_ticks_msec() < _catalog_suppress_until_ms


func _previous_decor_page() -> void:
	if _catalog_action_suppressed():
		return
	if _decor_page > 0:
		_decor_page -= 1
		catalog_scroll.scroll_vertical = 0
		_refresh_decor_cards()


func _next_decor_page() -> void:
	if _catalog_action_suppressed():
		return
	if _decor_page < _decor_page_count() - 1:
		_decor_page += 1
		catalog_scroll.scroll_vertical = 0
		_refresh_decor_cards()


func _companion_action(slot_index: int) -> void:
	if _catalog_action_suppressed():
		return
	var definition: Dictionary = _companion_cards[slot_index]["definition"]
	var id := str(definition.get("id", ""))
	var was_owned := id in AppState.owned_companions()
	var result := AppState.equip_companion(id) if was_owned else AppState.buy_companion(id)
	message_label.text = "%s equipped." % str(definition.get("name", id)) if result and was_owned else ("Not enough coins." if not result else "%s adopted!" % str(definition.get("name", id)))
	_refresh_companions()
	_refresh_chrome()


func _buy_decor(slot_index: int) -> void:
	if _catalog_action_suppressed():
		return
	var item: Dictionary = _decor_cards[slot_index]["item"]
	if item.is_empty():
		return
	message_label.text = "Purchased." if AppState.buy_furniture(str(item.get("id", ""))) else "Not enough coins."
	_refresh_decor_cards()
	_refresh_chrome()


func _sell_decor(slot_index: int) -> void:
	if _catalog_action_suppressed():
		return
	var item: Dictionary = _decor_cards[slot_index]["item"]
	if item.is_empty():
		return
	message_label.text = "Sold one unused item." if AppState.sell_furniture(str(item.get("id", ""))) else "Only unused bag items can be sold."
	_refresh_decor_cards()
	_refresh_chrome()


func _decor_page_count() -> int:
	return maxi(1, ceili(float(_decor_filtered.size()) / float(DECOR_SLOTS)))


func _update_coins() -> void:
	coin_label.text = str(AppState.coins())


func _go_home() -> void:
	AppState.shell_view = "home"
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _go_alley() -> void:
	if _catalog_action_suppressed():
		return
	get_tree().change_scene_to_file("res://scenes/meta/unicorn_alley.tscn")


func prepare_for_scene_change() -> void:
	# There are no delayed builds, previews, or queue-free operations to drain.
	return


func _anchor_rect(control: Control, left_anchor: float, right_anchor: float, left_offset: float, right_offset: float, top_offset: float, bottom_offset: float) -> void:
	# Called only while constructing the immutable Marketplace tree.  Anchors make
	# the same fixed pool fill both the narrow 534px and native 720px canvases.
	control.anchor_left = left_anchor
	control.anchor_right = right_anchor
	control.anchor_top = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = left_offset
	control.offset_right = right_offset
	control.offset_top = top_offset
	control.offset_bottom = bottom_offset


func _compact_header_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := button.get_theme_stylebox(state)
		if style is StyleBoxFlat:
			var compact := (style as StyleBoxFlat).duplicate() as StyleBoxFlat
			compact.content_margin_left = 4
			compact.content_margin_right = 4
			compact.content_margin_top = 2
			compact.content_margin_bottom = 2
			compact.shadow_size = 0
			compact.shadow_offset = Vector2.ZERO
			button.add_theme_stylebox_override(state, compact)


func _restore_catalog_rarity_font(rarity: Label) -> void:
	if is_instance_valid(rarity):
		rarity.add_theme_font_size_override("font_size", 14)


func _button(node_name: String, text: String, position_value: Vector2, size_value: Vector2, fill: Color, parent: Control = self) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.position = position_value
	button.size = size_value
	button.custom_minimum_size = size_value
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_constant_override("outline_size", 2)
	StorybookUI.apply_button(button, fill, StorybookUI.uses_dark_ink(fill))
	parent.add_child(button)
	return button


func _label(node_name: String, text: String, position_value: Vector2, size_value: Vector2, color: Color, font_size: int, parent: Control = self) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = position_value
	label.size = size_value
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("3c183d"))
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)
	return label


func _manual_wrap(value: String, characters: int, max_lines: int) -> String:
	var words := value.split(" ", false)
	var lines: Array[String] = []
	var line := ""
	for word in words:
		if lines.size() >= max_lines:
			break
		if line.is_empty() or line.length() + word.length() + 1 <= characters:
			line = word if line.is_empty() else "%s %s" % [line, word]
		else:
			lines.append(line)
			line = word
	if not line.is_empty() and lines.size() < max_lines:
		lines.append(line)
	return "\n".join(lines)
