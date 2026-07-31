extends Control

const Catalog = preload("res://scripts/meta_catalog.gd")
const Rules = preload("res://scripts/room_rules.gd")

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
		card.custom_minimum_size = Vector2(190, 210)
		card.add_theme_constant_override("separation", 6)
		grid.add_child(card)
		var portrait := ColorRect.new()
		portrait.color = Color(str(definition.get("color", "f26fa7")))
		portrait.custom_minimum_size.y = 72
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
	var filters := HBoxContainer.new()
	content.add_child(filters)
	var search := LineEdit.new()
	search.placeholder_text = "Search decor..."
	search.text = query
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_submitted.connect(func(value: String) -> void: query = value; _show_decor())
	filters.add_child(search)
	var category_picker := OptionButton.new()
	var selected_index := 0
	for index in Catalog.categories().size():
		var item: Dictionary = Catalog.categories()[index]
		category_picker.add_item(str(item["label"]))
		category_picker.set_item_metadata(index, str(item["id"]))
		if str(item["id"]) == category:
			selected_index = index
	category_picker.select(selected_index)
	category_picker.item_selected.connect(func(index: int) -> void: category = str(category_picker.get_item_metadata(index)); _show_decor())
	filters.add_child(category_picker)
	for definition in Catalog.filtered_furniture(category, query):
		var id := str(definition["id"])
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 112
		row.add_theme_constant_override("separation", 8)
		content.add_child(row)
		var badge := Label.new()
		badge.text = str(definition["name"]).left(1).to_upper()
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.custom_minimum_size = Vector2(58, 58)
		badge.add_theme_font_size_override("font_size", 28)
		badge.add_theme_color_override("font_color", _rarity_color(str(definition.get("rarity", "common"))))
		row.add_child(badge)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var name := Label.new()
		name.text = "%s  [%s]" % [definition["name"], str(definition.get("rarity", "common")).to_upper()]
		name.add_theme_font_size_override("font_size", 17)
		details.add_child(name)
		var desc := Label.new()
		desc.text = str(definition.get("desc", ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", MUTED)
		details.add_child(desc)
		var counts := Label.new()
		counts.text = "Owned %d  |  Placed %d  |  Bag %d" % [int(AppState.data["inventory"].get(id, 0)), AppState.placed_count(id), AppState.available_count(id)]
		counts.add_theme_color_override("font_color", CYAN)
		details.add_child(counts)
		var actions := VBoxContainer.new()
		row.add_child(actions)
		var buy := Button.new()
		buy.text = "BUY\n%d" % int(definition["price"])
		buy.disabled = AppState.coins() < int(definition["price"])
		buy.pressed.connect(_buy_decor.bind(id))
		actions.add_child(buy)
		var sell := Button.new()
		sell.text = "SELL\n%d" % Rules.sell_refund(int(definition["price"]))
		sell.disabled = AppState.available_count(id) <= 0
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
	button.add_theme_stylebox_override("normal", _style(color))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.12)))
	return button


func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style


func _rarity_color(rarity: String) -> Color:
	return {"common": MUTED, "uncommon": Color("62e6a7"), "rare": Color("6da9ff"), "legendary": YELLOW}.get(rarity, MUTED)
