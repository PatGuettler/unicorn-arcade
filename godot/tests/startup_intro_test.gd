extends SceneTree

const STARTUP_SCENE := preload("res://scenes/startup.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var startup = STARTUP_SCENE.instantiate()
	root.add_child(startup)
	await process_frame

	_check(startup.get_node("Poster") is TextureRect, "startup has an exact-frame poster")
	_check(startup.get_node("Video") is VideoStreamPlayer, "startup has video playback")
	_check(startup.get_node("Video").stream != null, "startup video stream imports")
	_check(startup.get_node("PlaybackGuard").one_shot, "startup timeout is one-shot")
	await create_timer(0.35).timeout
	_check(startup.get_node("Video").stream_position > 0.0, "startup video decoder advances")
	_check(not startup.get_node("Poster").visible, "poster yields after video playback begins")

	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	_check(startup._is_skip_event(touch), "touch press skips")

	var click := InputEventMouseButton.new()
	click.pressed = true
	_check(startup._is_skip_event(click), "mouse press skips")

	var key := InputEventKey.new()
	key.pressed = true
	_check(startup._is_skip_event(key), "keyboard press skips")

	var controller := InputEventJoypadButton.new()
	controller.pressed = true
	_check(startup._is_skip_event(controller), "controller press skips")

	var motion := InputEventMouseMotion.new()
	_check(not startup._is_skip_event(motion), "pointer motion does not skip")

	startup.queue_free()
	await process_frame
	if failures.is_empty():
		print("STARTUP INTRO TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
