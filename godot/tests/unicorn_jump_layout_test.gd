extends Node

const JumpScene = preload("res://scenes/games/unicorn_jump.tscn")

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var jump = JumpScene.instantiate()
	get_tree().root.add_child(jump)
	await get_tree().process_frame
	await get_tree().process_frame

	var landing: int = jump.level_data[0]
	_check(jump.node_buttons[0].global_position.y < jump.node_buttons[-1].global_position.y, "forward progress runs from the top of the trail downward")
	_check(jump.node_buttons[landing].global_position.y > jump.node_buttons[0].global_position.y, "the first forward jump lands lower on the path")
	_check(jump.find_child("TrailTopClearance", true, false) != null, "the trail keeps the unicorn clear of its top clipping edge")

	var experience = get_tree().root.get_node("GameExperience")
	var previous_scene = experience.attached_scene
	var previous_game_id: String = experience.attached_game_id
	var was_processing: bool = experience.is_processing()
	experience.set_process(false)
	experience.attached_scene = jump
	experience.attached_game_id = "unicorn_jump"
	experience.call("_show_notice", "Lucky Rainbow", "Gives a chance at bonus coins.")
	await get_tree().process_frame
	await get_tree().process_frame

	var notice := jump.find_child("CompanionAbilityNotice", true, false) as Control
	_check(notice != null, "the companion dialog opens inside Unicorn Jump")
	if notice != null:
		_check(notice.get_parent() == jump.scroller.get_parent() and notice.get_index() < jump.scroller.get_index(), "the companion dialog reserves space above the trail")
		var notice_rect := notice.get_global_rect()
		_check(not notice_rect.intersects(jump.node_buttons[0].get_global_rect()), "the dialog does not cover the unicorn's current stone")
		_check(not notice_rect.intersects(jump.node_buttons[landing].get_global_rect()), "the dialog does not cover the upcoming landing stone")
		notice.queue_free()

	experience.attached_scene = previous_scene
	experience.attached_game_id = previous_game_id
	experience.set_process(was_processing)
	jump.queue_free()
	await get_tree().process_frame

	if failures.is_empty():
		print("UNICORN JUMP LAYOUT TESTS PASSED")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
