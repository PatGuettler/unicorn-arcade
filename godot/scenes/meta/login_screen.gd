extends Control

var _name_field: LineEdit


func _ready() -> void:
	UiFactory.make_panel(self)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var title := UiFactory.make_title("UNICORN ARCADE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var sub := Label.new()
	sub.text = "Enter a name to play (saved on device)"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color("#94a3b8"))
	root.add_child(sub)

	_name_field = LineEdit.new()
	_name_field.placeholder_text = "Your name"
	_name_field.custom_minimum_size = Vector2(280, 44)
	root.add_child(_name_field)

	var play := UiFactory.make_button("Play", UiFactory.PINK)
	play.pressed.connect(_on_play)
	root.add_child(play)


func _on_play() -> void:
	var name := _name_field.text.strip_edges()
	if name.is_empty():
		return
	SaveManager.login(name)
	SceneRouter.go_home(false)
