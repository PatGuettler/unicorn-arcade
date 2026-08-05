extends Node

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const MIN_BODY_FONT := 19
const MIN_BUTTON_FONT := 18
const MIN_TOUCH_SIZE := 56.0
const TEXT := StorybookUI.CREAM
const MUTED_TEXT := StorybookUI.MUTED
const OUTLINE := Color("08112fd0")

var applied := {}


func _ready() -> void:
	get_tree().node_added.connect(_node_added)
	call_deferred("_apply_current_scene")


func _node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_apply_by_id", node.get_instance_id())


func _apply_current_scene() -> void:
	var scene := get_tree().current_scene
	if is_instance_valid(scene):
		_apply_tree_by_id(scene.get_instance_id())


func _apply_tree_by_id(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if is_instance_valid(node):
		_apply_tree(node)


func _apply_tree(node: Node) -> void:
	if node is Control:
		_apply_control(node)
	for child in node.get_children():
		_apply_tree(child)


func _apply_by_id(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if node is Control and is_instance_valid(node):
		_apply_control(node)


func _apply_control(control: Control) -> void:
	if applied.has(control.get_instance_id()):
		return
	applied[control.get_instance_id()] = true
	if control is Label:
		_apply_label(control as Label)
	elif control is LineEdit:
		_apply_line_edit(control as LineEdit)
	elif control is TextEdit:
		_apply_text_edit(control as TextEdit)
	if control is BaseButton:
		_apply_button(control as BaseButton)


func _apply_label(label: Label) -> void:
	if label.get_theme_font_size("font_size") < MIN_BODY_FONT:
		label.add_theme_font_size_override("font_size", MIN_BODY_FONT)
	if not label.has_theme_color_override("font_color"):
		label.add_theme_color_override("font_color", TEXT)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", maxi(3, label.get_theme_constant("outline_size")))


func _apply_button(button: BaseButton) -> void:
	var minimum := button.custom_minimum_size
	# Mathtris uses an 8x14 spatial board; a 56px minimum would push its controls
	# off every phone. The contiguous swipe grid gets a 44px target while all
	# standalone controls keep the full 56px accessibility minimum.
	var touch_size := 44.0 if button.has_meta("mathtris_tile") else MIN_TOUCH_SIZE
	minimum.y = maxf(minimum.y, touch_size)
	if minimum.x > 0.0 and minimum.x < MIN_TOUCH_SIZE:
		minimum.x = MIN_TOUCH_SIZE
	button.custom_minimum_size = minimum
	if button.get_theme_font_size("font_size") < MIN_BUTTON_FONT:
		button.add_theme_font_size_override("font_size", MIN_BUTTON_FONT)
	if not button.has_theme_color_override("font_color"):
		button.add_theme_color_override("font_color", TEXT)
	if not button.has_theme_color_override("font_hover_color"):
		button.add_theme_color_override("font_hover_color", Color.WHITE)
	if not button.has_theme_color_override("font_pressed_color"):
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
	if not button.has_theme_color_override("font_focus_color"):
		button.add_theme_color_override("font_focus_color", Color.WHITE)
	if not button.has_theme_color_override("font_disabled_color"):
		button.add_theme_color_override("font_disabled_color", MUTED_TEXT)
	if not button.has_theme_color_override("font_outline_color"):
		button.add_theme_color_override("font_outline_color", OUTLINE)
	button.add_theme_constant_override("outline_size", maxi(2, button.get_theme_constant("outline_size")))
	if button is CheckButton or button is CheckBox or not button is Button:
		return
	var text_button := button as Button
	if text_button.text.strip_edges().is_empty():
		return
	if not text_button.has_theme_stylebox_override("normal"):
		StorybookUI.apply_button(text_button)


func _apply_line_edit(line_edit: LineEdit) -> void:
	line_edit.custom_minimum_size.y = maxf(line_edit.custom_minimum_size.y, MIN_TOUCH_SIZE)
	if line_edit.get_theme_font_size("font_size") < MIN_BODY_FONT:
		line_edit.add_theme_font_size_override("font_size", MIN_BODY_FONT)
	if not line_edit.has_theme_stylebox_override("normal"):
		StorybookUI.apply_line_edit(line_edit)


func _apply_text_edit(text_edit: TextEdit) -> void:
	text_edit.custom_minimum_size.y = maxf(text_edit.custom_minimum_size.y, MIN_TOUCH_SIZE)
	if text_edit.get_theme_font_size("font_size") < MIN_BODY_FONT:
		text_edit.add_theme_font_size_override("font_size", MIN_BODY_FONT)
	if not text_edit.has_theme_color_override("font_color"):
		text_edit.add_theme_color_override("font_color", TEXT)
