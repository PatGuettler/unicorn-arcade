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
	game.call("_start_level", 6)
	await get_tree().process_frame
	await get_tree().process_frame
	var player_labels: Array[Node] = game.player_marker.find_children("*", "Label", true, false)
	_check(game.window_size == 5 and _active_window_centered(game) and _active_window_has_side_padding(game) and _player_marker_centered(game), "a new Sliding Window level resets stale camera state and centers its fitted five-node opening window")
	_check(player_labels.is_empty(), "the player unicorn marker has no redundant YOU caption")
	var wider_zoom: float = game.track_viewport.min_zoom
	game.track_viewport.set_camera(Vector2(190, -70), wider_zoom)
	game.window_pos = 1
	game.call("_update_window")
	await get_tree().process_frame
	_check(is_equal_approx(game.track_viewport.zoom, wider_zoom) and _active_window_centered(game) and _active_window_has_side_padding(game), "advancing preserves a wider user zoom while recentering the exact active bounds")
	var full_track_size: Vector2 = game.track_viewport.size
	game.track_viewport.size = Vector2(700, full_track_size.y)
	game.track_viewport.set_camera(Vector2(-240, 90), game.track_viewport.max_zoom)
	game.window_pos = 2
	game.call("_layout_and_center_player_window", game.layout_generation, false)
	_check(game.track_viewport.zoom < game.track_viewport.max_zoom and _active_window_centered(game) and _active_window_has_side_padding(game), "advancing clamps a too-close user zoom down until every active node fits")
	game.track_viewport.size = full_track_size

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
	_check(_active_window_centered(game) and _active_window_has_side_padding(game) and _player_marker_centered(game), "odd-sized active windows center both their bounds and unicorn marker exactly")
	game.window_size = 4
	game.window_pos = 1
	game.call("_update_window")
	await get_tree().process_frame
	_check(_active_window_centered(game) and _active_window_has_side_padding(game) and _player_marker_centered(game), "even-sized active windows center between the middle nodes with the unicorn at the exact bounds center")
	game.window_size = 3
	game.window_pos = 0
	game.call("_update_window")
	await get_tree().process_frame

	game.call("_choose", 4)
	_check(game.active and game.window_pos == 0, "the global maximum is ignored while it is outside the window")
	game.call("_choose", 0)
	_check(game.active and game.window_pos == 1, "the maximum inside the current window advances the window")
	await get_tree().process_frame
	_check(_active_window_centered(game) and _active_window_has_side_padding(game) and _player_marker_centered(game), "the full current player window and marker are centered after advancing")
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


func _active_window_rect(game: Control) -> Rect2:
	var first: Rect2 = game.value_buttons[game.window_pos].get_global_rect()
	var last: Rect2 = game.value_buttons[game.window_pos + game.window_size - 1].get_global_rect()
	return first.merge(last)


func _active_window_centered(game: Control) -> bool:
	var active := _active_window_rect(game)
	var viewport: Rect2 = game.track_viewport.get_global_rect()
	return absf(active.get_center().x - viewport.get_center().x) <= 0.75


func _active_window_has_side_padding(game: Control) -> bool:
	var active := _active_window_rect(game)
	var viewport: Rect2 = game.track_viewport.get_global_rect()
	return active.position.x >= viewport.position.x + 23.5 and active.end.x <= viewport.end.x - 23.5


func _player_marker_centered(game: Control) -> bool:
	return absf(game.player_marker.get_global_rect().get_center().x - _active_window_rect(game).get_center().x) <= 0.75


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
