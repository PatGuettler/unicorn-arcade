class_name LevelRunController
extends RefCounted

enum Outcome { IDLE, RUNNING, SUCCESS, FAILURE }
var game_id := ""
var level := 1
var next_level := 1
var active := false
var outcome: Outcome = Outcome.IDLE
var started_ms := 0
var ended_ms := 0
var outcome_message := ""
var reward := 0
var _completed := false

func begin(next_game_id: String, next_level_value: int) -> void:
	game_id = next_game_id
	level = maxi(1, next_level_value)
	next_level = level
	active = true
	outcome = Outcome.RUNNING
	started_ms = Time.get_ticks_msec()
	ended_ms = 0
	outcome_message = ""
	reward = 0
	_completed = false
	CompanionAbilityService.begin_level(game_id, level)

func elapsed_ms() -> int:
	return maxi(0, (Time.get_ticks_msec() if active else ended_ms) - started_ms)

func complete() -> int:
	if _completed or not active:
		return reward
	_completed = true
	active = false
	outcome = Outcome.SUCCESS
	next_level = level + 1
	ended_ms = Time.get_ticks_msec()
	var frozen_elapsed := elapsed_ms()
	reward = AppState.complete_level(game_id, level, frozen_elapsed)
	return reward

func fail(message: String) -> void:
	if not active:
		return
	active = false
	outcome = Outcome.FAILURE
	outcome_message = message
	ended_ms = Time.get_ticks_msec()

func can_retry() -> bool:
	return outcome == Outcome.FAILURE

func retry() -> int:
	var selected := next_level if outcome == Outcome.SUCCESS else level
	begin(game_id, selected)
	return selected

func select_category() -> String:
	return str(GameRegistry.get_game(game_id).get("category", "Number"))
