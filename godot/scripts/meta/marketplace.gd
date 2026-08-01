extends Control

const Catalog = preload("res://scripts/meta_catalog.gd")
const Rules = preload("res://scripts/room_rules.gd")
const RoomItemPreviewScene = preload("res://scripts/meta/room_item_preview_3d.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")

const NAVY := Color("08112f")
const PANEL := Color("14214a")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const TEXT := Color("f7f1ff")
const MUTED := Color("aab7e8")

var root: VBoxContainer
var content: VBoxContainer
var coin_label: Label
var message_label: Label
var tab := "companions"
var category := "all"
var query := ""


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
	var header := HBoxContainer.new()
	root.add_child(header)
	var back := Button.new()
	back.text = "< HOME"
	back.pressed.connect(_go_home)
	header.add_child(back)
	var title := Label.new()
	title.text = "MARKETPLACE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", PINK)
	header.add_child(title)
	coin_label = Label.new()
	coin_label.add_theme_color_override("font_color", YELLOW)
	header.add_child(coin_label)
	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	var companions := _button("COMPANIONS", PANEL, 50)
	companions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	companions.pressed.connect(_show_companions)
	tabs.add_child(companions)
	var decor := _button("DECOR", PANEL, 50)
	decor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	decor.pressed.connect(_show_decor)
	tabs.add_child(decor)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", YELLOW)
	message_label.custom_minimum_size.y = 24
	root.add_child(message_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	_update_coins()


func _clear_content() -> void:
	for child in content.get_children():
		child.queue_free()
	message_label.text = ""
	_update_coins()


func _show_companions() -> void:
	tab = "companions"
	_clear_content()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for definition in Catalog.companions():
		var id := str(definition["id"])
		var owned := id in AppState.owned_companions()
		var equipped := id == AppState.equipped_companion()
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(190, 252)
		card.add_theme_constant_override("separation", 6)
		grid.add_child(card)
		var portrait := RoomItemPreviewScene.new()
		portrait.name = "CompanionModelPreview"
		portrait.custom_minimum_size.y = 112
		portrait.setup({"id": "companion_%s" % id, "category": "companions"})
		card.add_child(portrait)
		var name := Label.new()
		name.text = str(definition["name"]).to_upper()
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.add_theme_font_size_override("font_size", 19)
		card.add_child(name)
		var desc := Label.new()
		desc.text = str(definition["desc"])
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", MUTED)
		desc.custom_minimum_size.y = 42
		card.add_child(desc)
		var action := _button("EQUIPPED" if equipped else ("EQUIP" if owned else "%d COINS" % int(definition["price"])), Color("286d58") if equipped else PANEL, 48)
		action.disabled = equipped or (not owned and AppState.coins() < int(definition["price"]))
		action.pressed.connect(_companion_action.bind(id, owned))
		card.add_child(action)


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
	_clear_content()
	var search := LineEdit.new()
	search.name = "DecorSearch"
	search.placeholder_text = "Search decor..."
	search.text = query
	search.custom_minimum_size.y = 58
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.add_theme_font_size_override("font_size", 19)
	search.add_theme_constant_override("outline_size", 2)
	StorybookUI.apply_line_edit(search)
	search.text_submitted.connect(func(value: String) -> void: query = value; _show_decor())
	content.add_child(search)
	var category_scroll := ScrollContainer.new()
	category_scroll.name = "DecorCategoryScroll"
	category_scroll.custom_minimum_size.y = 66
	category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(category_scroll)
	var category_row := HBoxContainer.new()
	category_row.name = "DecorCategoryChips"
	category_row.add_theme_constant_override("separation", 8)
	category_scroll.add_child(category_row)
	for item in Catalog.categories():
		var category_id := str(item["id"])
		var chip := _button(str(item["label"]).to_upper(), PINK if category_id == category else PANEL, 56)
		chip.name = "Category_%s" % category_id
		chip.custom_minimum_size.x = maxf(94.0, float(str(item["label"]).length() * 12 + 34))
		chip.pressed.connect(func() -> void: category = category_id; _show_decor())
		category_row.add_child(chip)
	for definition in Catalog.filtered_furniture(category, query):
		var id := str(definition["id"])
		var rarity := str(definition.get("rarity", "common"))
		var card := PanelContainer.new()
		card.name = "DecorCard_%s" % id
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 226
		card.add_theme_stylebox_override("panel", _decor_card_style(_rarity_color(rarity)))
		content.add_child(card)
		var card_layout := VBoxContainer.new()
		card_layout.add_theme_constant_override("separation", 10)
		card.add_child(card_layout)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card_layout.add_child(row)
		var preview_frame := PanelContainer.new()
		preview_frame.name = "DecorPreviewFrame"
		preview_frame.custom_minimum_size = Vector2(126, 126)
		preview_frame.add_theme_stylebox_override("panel", _preview_style())
		row.add_child(preview_frame)
		var preview := RoomItemPreviewScene.new()
		preview.name = "CatalogModelPreview"
		preview.custom_minimum_size = Vector2(118, 118)
		preview.setup(definition)
		preview_frame.add_child(preview)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation", 5)
		row.add_child(details)
		var name := Label.new()
		name.text = str(definition["name"]).to_upper()
		name.add_theme_font_size_override("font_size", 21)
		details.add_child(name)
		var rarity_badge := Label.new()
		rarity_badge.text = "  %s  " % rarity.to_upper()
		rarity_badge.add_theme_font_size_override("font_size", 19)
		rarity_badge.add_theme_color_override("font_color", NAVY if _rarity_color(rarity).get_luminance() > 0.56 else TEXT)
		rarity_badge.add_theme_stylebox_override("normal", _badge_style(_rarity_color(rarity)))
		rarity_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		details.add_child(rarity_badge)
		var desc := Label.new()
		desc.text = str(definition.get("desc", ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", MUTED)
		desc.add_theme_font_size_override("font_size", 19)
		details.add_child(desc)
		var counts := Label.new()
		counts.text = "OWNED %d   •   PLACED %d   •   BAG %d" % [int(AppState.data["inventory"].get(id, 0)), AppState.placed_count(id), AppState.available_count(id)]
		counts.add_theme_color_override("font_color", CYAN)
		counts.add_theme_font_size_override("font_size", 19)
		details.add_child(counts)
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 10)
		card_layout.add_child(actions)
		var buy := _button("★ %d   BUY" % int(definition["price"]), PANEL, 60)
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy.disabled = AppState.coins() < int(definition["price"])
		buy.pressed.connect(_buy_decor.bind(id))
		actions.add_child(buy)
		if AppState.available_count(id) > 0:
			var sell := _button("SELL   +★ %d" % Rules.sell_refund(int(definition["price"])), Color("4a2859"), 60)
			sell.custom_minimum_size.x = 170
			sell.pressed.connect(_sell_decor.bind(id))
			actions.add_child(sell)
	var alley := _button("VISIT UNICORN ALLEY", PINK, 56)
	alley.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta/unicorn_alley.tscn"))
	content.add_child(alley)


func _buy_decor(item_id: String) -> void:
	message_label.text = "Purchased." if AppState.buy_furniture(item_id) else "Not enough coins."
	_show_decor.call_deferred()


func _sell_decor(item_id: String) -> void:
	message_label.text = "Sold one unused item." if AppState.sell_furniture(item_id) else "Only unused bag items can be sold."
	_show_decor.call_deferred()


func _update_coins() -> void:
	coin_label.text = "%d COINS" % AppState.coins()


func _go_home() -> void:
	AppState.shell_view = "home"
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _button(text: String, color: Color, height: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = height
	StorybookUI.apply_button(button, color, StorybookUI.uses_dark_ink(color))
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
