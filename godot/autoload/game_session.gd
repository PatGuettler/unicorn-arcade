extends Node

## Shared level timer, hints, and victory flow (mirrors useGameSystem.js).

signal state_changed
signal level_completed(level: int, time_sec: float)

enum State { PLAYING, SCORING, LEVEL_COMPLETE, FAILED }

const HINT_COST := 5

var state: State = State.PLAYING
var level: int = 1
var elapsed_ms: int = 0
var show_hint: bool = false
var fail_message: String = ""

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 0.05
	_timer.timeout.connect(_on_tick)
	add_child(_timer)


func reset_for_game() -> void:
	state = State.PLAYING
	level = 1
	elapsed_ms = 0
	show_hint = false
	fail_message = ""
	_timer.stop()


func start_level(lvl: int) -> void:
	level = lvl
	elapsed_ms = 0
	show_hint = level == 1
	fail_message = ""
	state = State.PLAYING
	_timer.start()
	state_changed.emit()


func _on_tick() -> void:
	if state != State.PLAYING:
		return
	elapsed_ms += 50
	state_changed.emit()


func register_move(valid: bool) -> void:
	if state != State.PLAYING:
		return
	if valid:
		show_hint = false
		state_changed.emit()


func buy_hint() -> bool:
	if state != State.PLAYING or show_hint:
		return false
	if level == 1:
		show_hint = true
		state_changed.emit()
		return true
	if SaveManager.spend_coins(HINT_COST):
		show_hint = true
		state_changed.emit()
		return true
	return false


func complete_level() -> void:
	if state != State.PLAYING:
		return
	_timer.stop()
	state = State.SCORING
	state_changed.emit()
	var time_sec := elapsed_ms / 1000.0
	await get_tree().create_timer(1.0).timeout
	state = State.LEVEL_COMPLETE
	level_completed.emit(level, time_sec)
	state_changed.emit()


func fail_level(message: String = "") -> void:
	_timer.stop()
	fail_message = message
	state = State.FAILED
	state_changed.emit()


func elapsed_seconds() -> float:
	return elapsed_ms / 1000.0
