class_name UnicornHeader
extends RefCounted

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const CURRENCY_STAR := Color("ffd166")

static func build(title: String, back_text: String, back_action: Callable, home_action: Callable, trailing_text := "", trailing_action := Callable()) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SharedUnicornHeader"
	panel.custom_minimum_size.y = 56
	var panel_style := StorybookUI.plaque_style(Color("17254d"), StorybookUI.GOLD, 16)
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	var grid := GridContainer.new()
	grid.columns = 3
	panel.add_child(grid)
	var left_slot: Control
	if back_text.to_upper() == "HOME":
		# HOME already appears as the consistent icon button at the right. Keep a
		# fixed left slot so the title stays centered without duplicating Home.
		left_slot = Control.new()
		left_slot.name = "HeaderLeftSpacer"
		left_slot.custom_minimum_size = Vector2(48, 56)
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
	actions.add_theme_constant_override("separation", 4)
	var has_trailing_action := not trailing_text.is_empty() and trailing_action.is_valid()
	actions.custom_minimum_size = Vector2(202 if has_trailing_action else 138, 56)
	var home := Button.new()
	home.name = "HeaderHomeButton"
	home.tooltip_text = "Home"
	StorybookUI.apply_home_button(home)
	home.pressed.connect(home_action)
	actions.add_child(home)
	var coin_icon := Label.new()
	coin_icon.name = "SharedCoinIcon"
	coin_icon.text = "★"
	coin_icon.tooltip_text = "Coins"
	coin_icon.custom_minimum_size = Vector2(24, 30)
	coin_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_icon.add_theme_font_size_override("font_size", 24)
	coin_icon.add_theme_color_override("font_color", CURRENCY_STAR)
	coin_icon.add_theme_color_override("font_outline_color", StorybookUI.PLUM)
	coin_icon.add_theme_constant_override("outline_size", 3)
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_child(coin_icon)
	var coins := Label.new()
	coins.name = "SharedCoinBalance"
	coins.text = str(AppState.coins())
	coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins.custom_minimum_size = Vector2(52, 56)
	coins.add_theme_font_size_override("font_size", 16)
	actions.add_child(coins)
	if has_trailing_action:
		var trailing := Button.new()
		trailing.text = trailing_text
		trailing.custom_minimum_size = Vector2(60, 56)
		trailing.pressed.connect(trailing_action)
		actions.add_child(trailing)
	grid.add_child(actions)
	return panel
