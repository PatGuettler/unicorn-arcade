extends Control

@onready var content: Control = $Content


func _ready() -> void:
	SceneRouter.set_content_root(content)
	await get_tree().process_frame
	SceneRouter.start_app()
