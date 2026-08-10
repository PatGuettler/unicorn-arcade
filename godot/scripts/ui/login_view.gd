class_name LoginView
extends VBoxContainer

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const TITLE_SIGN = preload("res://assets/ui/title_sign_option3_v1.png")
const RoomItemPreviewScene = preload("res://scripts/meta/room_item_preview_3d.gd")

var _authenticated_callback := Callable()


func configure(authenticated_callback: Callable) -> void:
	_authenticated_callback = authenticated_callback


func build() -> void:
	name = "LoginView"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)

	var brand := TextureRect.new()
	brand.name = "IllustratedTitleSign"
	brand.texture = TITLE_SIGN
	brand.custom_minimum_size = Vector2(0, 245)
	brand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(brand)

	var tagline_plaque := PanelContainer.new()
	tagline_plaque.name = "TaglinePlaque"
	tagline_plaque.custom_minimum_size = Vector2(0, 56)
	tagline_plaque.add_theme_stylebox_override("panel", StorybookUI.plaque_style())
	add_child(tagline_plaque)
	var tagline := Label.new()
	tagline.text = "Train your brain with code-based games."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", StorybookUI.INK)
	tagline.add_theme_color_override("font_outline_color", Color("fff3d600"))
	tagline.add_theme_constant_override("outline_size", 0)
	tagline.add_theme_font_size_override("font_size", 19)
	tagline_plaque.add_child(tagline)

	var name_prompt := Label.new()
	name_prompt.name = "PlayerNamePrompt"
	name_prompt.text = "WHAT SHOULD WE CALL YOU?"
	name_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_prompt.add_theme_font_size_override("font_size", 22)
	name_prompt.add_theme_color_override("font_color", StorybookUI.INK)
	name_prompt.add_theme_color_override("font_outline_color", StorybookUI.CREAM)
	name_prompt.add_theme_constant_override("outline_size", 3)
	add_child(name_prompt)

	var name_input := LineEdit.new()
	name_input.name = "PlayerNameInput"
	name_input.placeholder_text = "Tap here and enter your name"
	name_input.custom_minimum_size = Vector2(0, 64)
	name_input.add_theme_font_size_override("font_size", 21)
	add_child(name_input)

	_build_saved_profile_choices()

	var enter := _button("ENTER ARCADE", StorybookUI.NAVY, 68)
	enter.name = "LoginEnterButton"
	enter.disabled = true
	name_input.text_changed.connect(func(value: String) -> void: enter.disabled = value.strip_edges().is_empty())
	var submit := func() -> void:
		if name_input.text.strip_edges().is_empty():
			return
		AppState.set_player_name(name_input.text)
		AppState.shell_view = "home"
		_authenticate()
	enter.pressed.connect(submit)
	name_input.text_submitted.connect(func(_value: String) -> void: submit.call())
	add_child(enter)

	var preview := _build_companion_preview(AppState.equipped_companion(), "hero", 300.0)
	preview.name = "LoginCompanionPreview"
	preview.custom_minimum_size.y = 210
	add_child(preview)

	var bottom := Control.new()
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(bottom)


func _build_saved_profile_choices() -> void:
	var profiles := AppState.profile_names()
	if profiles.is_empty():
		return
	var choose_label := Label.new()
	choose_label.name = "SavedProfilePrompt"
	choose_label.text = "OR PICK A SAVED PROFILE"
	choose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choose_label.add_theme_font_size_override("font_size", 15)
	add_child(choose_label)
	var choices := HBoxContainer.new()
	choices.name = "SavedProfileChoices"
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 8)
	add_child(choices)
	for profile_name in profiles:
		var profile_button := _button(profile_name.to_upper(), StorybookUI.NAVY, 52)
		profile_button.pressed.connect(_select_saved_profile.bind(profile_name))
		choices.add_child(profile_button)


func _select_saved_profile(profile_name: String) -> void:
	if AppState.select_profile(profile_name):
		_authenticate()


func _authenticate() -> void:
	if _authenticated_callback.is_valid():
		_authenticated_callback.call()


func _build_companion_preview(companion_id: String, presentation: String, minimum_height: float) -> SubViewportContainer:
	var container := RoomItemPreviewScene.new()
	container.custom_minimum_size = Vector2(0, minimum_height)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.setup({"id": "companion_%s" % companion_id, "category": "companions", "presentation": presentation})
	return container


func _button(value: String, color: Color, height: float) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, height)
	button.add_theme_font_size_override("font_size", 18)
	StorybookUI.apply_button(button, color, StorybookUI.uses_dark_ink(color))
	return button
