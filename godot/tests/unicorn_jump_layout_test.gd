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
	_check(jump.world_viewport != null and jump.world_viewport is Control, "Unicorn Jump uses a pan/pinch game camera instead of a scrollbar")
	_check(jump.find_child("GameWorldViewport", true, false) != null, "the playfield is a clipped GameWorldViewport")
	_check(not (jump.world_viewport is ScrollContainer), "the playfield does not expose a ScrollContainer scrollbar")
	var view_rect: Rect2 = jump.world_viewport.get_global_rect()
	var first_five_centers_visible := true
	for index in range(mini(5, jump.node_buttons.size())):
		first_five_centers_visible = first_five_centers_visible and view_rect.has_point(jump.node_buttons[index].get_global_rect().get_center())
	_check(jump.world_viewport.zoom < 1.0 and first_five_centers_visible, "the initial camera frames the current stone and four forward stones while keeping pinch zoom available")

	var experience = get_tree().root.get_node("GameExperience")
	var previous_scene = experience.attached_scene
	var previous_game_id: String = experience.attached_game_id
	var was_processing: bool = experience.is_processing()
	experience.set_process(false)
	experience.attached_scene = jump
	experience.attached_game_id = "unicorn_jump"
	var objective_plaque := experience.call("_build_objective_plaque") as PanelContainer
	var hud_mascot := objective_plaque.find_child("EquippedCompanionMascot", true, false) as RoomItemPreview3D
	var hud_cameras := hud_mascot.find_children("*", "Camera3D", true, false) if is_instance_valid(hud_mascot) else []
	var hud_camera: Camera3D = hud_cameras[0] as Camera3D if not hud_cameras.is_empty() else null
	_check(is_instance_valid(hud_mascot) and hud_mascot.presentation_context == "game_hud" and hud_mascot.custom_minimum_size.x >= 96.0 and is_instance_valid(hud_camera) and hud_camera.size >= 8.8, "the shared objective HUD uses an isolated padded companion framing without clipping other preview contexts")
	objective_plaque.queue_free()
	experience.call("_show_notice", "Lucky Rainbow", "Gives a chance at bonus coins.")
	await get_tree().process_frame
	await get_tree().process_frame

	var notice := jump.find_child("CompanionAbilityNotice", true, false) as Control
	_check(notice != null, "the companion dialog opens inside Unicorn Jump")
	if notice != null:
		_check(notice.get_parent() == jump.world_viewport.get_parent() and notice.get_index() < jump.world_viewport.get_index(), "the companion dialog reserves space above the trail")
		var notice_rect := notice.get_global_rect()
		_check(not notice_rect.intersects(jump.node_buttons[0].get_global_rect()), "the dialog does not cover the unicorn's current stone")
		_check(not notice_rect.intersects(jump.node_buttons[landing].get_global_rect()), "the dialog does not cover the upcoming landing stone")
		notice.queue_free()

	experience.call("_request_leave", false)
	await get_tree().process_frame
	var leave_overlay := jump.find_child("LeaveRunOverlay", true, false) as Control
	var leave_copy := jump.find_child("LeaveRunCopy", true, false) as Label
	var leave_button := jump.find_child("LeaveRunConfirm", true, false) as Button
	var keep_button := jump.find_child("LeaveRunCancel", true, false) as Button
	_check(is_instance_valid(leave_overlay) and is_instance_valid(leave_copy) and leave_copy.get_theme_font_size("font_size") >= 23 and is_instance_valid(leave_button) and leave_button.text == "LEAVE RUN" and is_instance_valid(keep_button) and keep_button.text == "KEEP PLAYING", "leaving an active run uses the readable in-game storybook modal and styled choices")
	_check(jump.find_children("*", "ConfirmationDialog", true, false).is_empty(), "leave confirmation never opens a system ConfirmationDialog")
	if is_instance_valid(keep_button):
		keep_button.emit_signal("pressed")

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
