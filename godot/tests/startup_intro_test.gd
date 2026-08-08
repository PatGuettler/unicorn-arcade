extends SceneTree

const STARTUP_SCENE := preload("res://scenes/startup.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var startup = STARTUP_SCENE.instantiate()
	root.add_child(startup)
	_check(not startup._threaded_load_attempted, "startup lets the video decoder advance before preloading the main scene")
	await process_frame

	_check(startup.get_node("Poster") is TextureRect, "startup has an exact-frame poster")
	_check(startup.get_node("Video") is VideoStreamPlayer, "startup has video playback")
	_check(startup.get_node("Video").stream != null, "startup video stream imports")
	_check(startup.get_node("PlaybackGuard").one_shot, "startup timeout is one-shot")
	_check(startup.get_node("PlaybackGuard").wait_time >= 1.4 and startup.get_node("PlaybackGuard").wait_time <= 1.6, "startup uses a short decoder-start fallback instead of delaying the app")
	_check(startup.get_node("Video").autoplay, "startup video is configured for Android-friendly autoplay")
	_check(startup.get_node("SkipButton") is Button, "startup has an Android-reliable full-screen skip target")
	_check(startup.get_node("SkipButton").button_down.is_connected(Callable(startup, "_finish_intro")), "skip reacts on press instead of waiting for release")
	_check(startup.get_node("LoadingCover") is Control, "startup has an immediate visual handoff while the main scene finishes loading")
	await create_timer(0.35).timeout
	_check(startup.get_node("Video").stream_position > 0.0, "startup video decoder advances")
	_check(not startup.get_node("Poster").visible, "poster yields after video playback begins")
	_check(not startup._threaded_load_attempted, "main-scene streaming waits until video playback finishes")
	_check(
		not startup._is_playback_complete(5.0, 5.04, false, false),
		"stopped decoder does not finish before playback starts"
	)
	_check(
		not startup._is_playback_complete(4.5, 5.04, true, true),
		"active video does not finish too early"
	)
	_check(
		startup._is_playback_complete(4.95, 5.04, true, true),
		"active video finishes at its visual endpoint"
	)
	_check(
		startup._is_playback_complete(4.5, 5.04, false, true),
		"stopped video finishes immediately after playback began"
	)

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
