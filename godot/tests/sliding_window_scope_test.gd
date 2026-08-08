extends Node

const SlidingWindowScene = preload("res://scenes/games/sliding_window.tscn")

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = SlidingWindowScene.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.set_process(false)
	game.level_data.assign([9, 1, 2, 3, 100, 4])
	game.opponent_data.assign([4, 8, 1, 7, 2, 5])
	game.window_size = 3
	game.window_pos = 1
	game.opponent_pos = 0
	game.active = true
	game.call("_rebuild_tracks")
	game.call("_update_window")
	game.call("_update_rival")
	await get_tree().process_frame

	_check(game.value_buttons.size() == game.level_data.size(), "the full number track stays visible")
	_check(game.rival_nodes.size() == 6 and game.find_child("RivalNumberTrack", true, false) != null, "the rival bot track is visible with matching nodes")
	_check(game.find_child("RIVALMarker", true, false) != null, "the rival bot avatar marker is on the race lanes")
	_check(game.value_buttons[0].disabled and game.value_buttons[4].disabled, "numbers outside the current window are disabled")
	_check(not game.value_buttons[1].disabled and not game.value_buttons[3].disabled, "only numbers inside the current window are selectable")
	_check(game.track_viewport != null and not (game.track_viewport is ScrollContainer), "the number track uses a pan/pinch camera without scrollbars")
	game.track_viewport.set_camera(Vector2(220, -80), 1.3)
	game.call("_start_level", 1)
	await get_tree().process_frame
	var opening_center: Vector2 = game.value_buttons[1].get_global_rect().get_center()
	var viewport_rect: Rect2 = game.track_viewport.get_global_rect()
	var opening_ratio: float = (opening_center.x - viewport_rect.position.x) / maxf(1.0, viewport_rect.size.x)
	var player_labels: Array[Node] = game.player_marker.find_children("*", "Label", true, false)
	_check(is_equal_approx(game.track_viewport.zoom, 1.0) and opening_ratio >= 0.10 and opening_ratio <= 0.28, "a new Sliding Window level resets stale camera state and places its first window toward the left")
	_check(player_labels.is_empty(), "the player unicorn marker has no redundant YOU caption")

	# Replace the fresh level only after its opening camera placement has been
	# verified, so the advance assertions use a deterministic set of values.
	game.level_data.assign([9, 1, 2, 3, 100, 4])
	game.opponent_data.assign([4, 8, 1, 7, 2, 5])
	game.window_size = 3
	game.window_pos = 0
	game.opponent_pos = 0
	game.active = true
	game.call("_rebuild_tracks")
	game.call("_update_window")
	game.call("_update_rival")
	await get_tree().process_frame

	game.call("_choose", 4)
	_check(game.active and game.window_pos == 0, "the global maximum is ignored while it is outside the window")
	game.call("_choose", 0)
	_check(game.active and game.window_pos == 1, "the maximum inside the current window advances the window")
	await get_tree().process_frame
	var first_active: Rect2 = game.value_buttons[game.window_pos].get_global_rect()
	var last_active: Rect2 = game.value_buttons[game.window_pos + game.window_size - 1].get_global_rect()
	var active_center_x: float = (first_active.position.x + last_active.end.x) * 0.5
	var active_center_ratio: float = (active_center_x - viewport_rect.position.x) / maxf(1.0, viewport_rect.size.x)
	_check(active_center_ratio >= 0.45 and active_center_ratio <= 0.55, "the full current player window is centered after advancing")
	game.call("_choose", 3)
	_check(game.active and game.window_pos == 2, "the next window advances from its current maximum")

	game.active = true
	game.call("_choose", 3)
	_check(not game.active and game.window_pos == 2, "a former window maximum fails after a larger value enters the window")

	game.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("SLIDING WINDOW SCOPE TESTS PASSED")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
