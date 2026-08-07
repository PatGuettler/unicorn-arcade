class_name UnicornHeader
extends RefCounted

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")

static func build(title: String, back_text: String, back_action: Callable, home_action: Callable, trailing_text := "", trailing_action := Callable()) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SharedUnicornHeader"
	panel.custom_minimum_size.y = 56
	panel.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("17254d"), StorybookUI.GOLD, 16))
	var grid := GridContainer.new()
	grid.columns = 3
	panel.add_child(grid)
	var back := Button.new()
	back.text = "< " + back_text
	back.custom_minimum_size = Vector2(112, 56)
	back.pressed.connect(back_action)
	grid.add_child(back)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", StorybookUI.CREAM)
	grid.add_child(label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	var home := Button.new()
	home.text = "HOME"
	home.tooltip_text = "Home"
	home.custom_minimum_size = Vector2(56, 56)
	home.pressed.connect(home_action)
	actions.add_child(home)
	var coins := Label.new()
	coins.name = "SharedCoinBalance"
	coins.text = "COINS %d" % AppState.coins()
	coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins.custom_minimum_size.x = 76
	actions.add_child(coins)
	if not trailing_text.is_empty() and trailing_action.is_valid():
		var trailing := Button.new()
		trailing.text = trailing_text
		trailing.custom_minimum_size = Vector2(64, 56)
		trailing.pressed.connect(trailing_action)
		actions.add_child(trailing)
	grid.add_child(actions)
	return panel
