class_name UnicornHeader
extends RefCounted

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const COIN_ICON_PATH := "res://assets/games/currency/quarter.png"

static func build(title: String, back_text: String, back_action: Callable, home_action: Callable, trailing_text := "", trailing_action := Callable()) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SharedUnicornHeader"
	panel.custom_minimum_size.y = 56
	panel.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("17254d"), StorybookUI.GOLD, 16))
	var grid := GridContainer.new()
	grid.columns = 3
	panel.add_child(grid)
	var left_slot: Control
	if back_text.to_upper() == "HOME":
		# HOME already appears as the consistent icon button at the right. Keep a
		# fixed left slot so the title stays centered without duplicating Home.
		left_slot = Control.new()
		left_slot.name = "HeaderLeftSpacer"
		left_slot.custom_minimum_size = Vector2(112, 56)
	else:
		var back := Button.new()
		back.name = "HeaderBackButton"
		back.text = "< " + back_text
		back.custom_minimum_size = Vector2(112, 56)
		back.pressed.connect(back_action)
		left_slot = back
	grid.add_child(left_slot)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", StorybookUI.CREAM)
	grid.add_child(label)
	var actions := HBoxContainer.new()
	actions.name = "HeaderActions"
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.custom_minimum_size = Vector2(216, 56)
	var home := Button.new()
	home.name = "HeaderHomeButton"
	home.tooltip_text = "Home"
	StorybookUI.apply_home_button(home)
	home.pressed.connect(home_action)
	actions.add_child(home)
	var coin_icon := TextureRect.new()
	coin_icon.name = "SharedCoinIcon"
	coin_icon.texture = load(COIN_ICON_PATH) as Texture2D
	coin_icon.custom_minimum_size = Vector2(34, 34)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_child(coin_icon)
	var coins := Label.new()
	coins.name = "SharedCoinBalance"
	coins.text = "COINS %d" % AppState.coins()
	coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins.custom_minimum_size = Vector2(96, 56)
	coins.add_theme_font_size_override("font_size", 16)
	actions.add_child(coins)
	if not trailing_text.is_empty() and trailing_action.is_valid():
		var trailing := Button.new()
		trailing.text = trailing_text
		trailing.custom_minimum_size = Vector2(64, 56)
		trailing.pressed.connect(trailing_action)
		actions.add_child(trailing)
	grid.add_child(actions)
	return panel
