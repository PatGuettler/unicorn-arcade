extends Node

const GALAXY_SCENE = preload("res://scenes/games/galaxy_unicorn.tscn")

var failures: Array[String] = []
var checks := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _run() -> void:
	var galaxy = GALAXY_SCENE.instantiate()
	add_child(galaxy)
	await get_tree().process_frame
	galaxy.set_process(false)
	galaxy.size = Vector2(720.0, 1280.0)
	galaxy._start_level(1)
	await get_tree().process_frame

	_check(is_equal_approx(galaxy.opening_timer, 1500.0) and galaxy.opening_left == 4, "Galaxy starts level one with the historical 1500ms four-enemy opening delay")
	var player_x_before_pause: float = galaxy.player_x
	var opening_timer_before_pause: float = galaxy.opening_timer
	var spawn_timer_before_pause: float = galaxy.spawn_timer
	galaxy.set_gameplay_paused(true)
	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(648.0, 900.0)
	galaxy._input(drag)
	galaxy._process(1.0)
	_check(is_equal_approx(galaxy.player_x, player_x_before_pause), "Galaxy ignores player drag input while gameplay is paused")
	_check(is_equal_approx(galaxy.opening_timer, opening_timer_before_pause) and is_equal_approx(galaxy.spawn_timer, spawn_timer_before_pause) and galaxy.enemies.is_empty(), "Galaxy pause freezes opening and spawn processing")

	galaxy.set_gameplay_paused(false)
	galaxy._process(1.499)
	_check(galaxy.enemies.is_empty() and galaxy.opening_timer > 0.0, "Galaxy does not spawn its opening wave before 1500ms has elapsed")
	galaxy._process(0.002)
	_check(galaxy.enemies.size() == 1 and galaxy.opening_left == 3, "Galaxy starts its opening wave after the 1500ms delay")
	galaxy.queue_free()
	await get_tree().process_frame

	if failures.is_empty():
		print("GALAXY_PAUSE_OPENING_TEST_OK: %d checks" % checks)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
