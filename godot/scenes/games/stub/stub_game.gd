extends Control


func _ready() -> void:
	UiFactory.make_panel(self)
	var game_id := SceneRouter.get_game_id()
	var entry := GameCatalog.get_game_entry(SceneRouter.get_category_id(), game_id)
	UiFactory.make_header(self, entry.get("title", game_id), func(): SceneRouter.pop())

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.text = "This game is not ported yet.\nCoin Count is the reference implementation."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
