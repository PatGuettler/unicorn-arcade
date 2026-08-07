extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	host.name = "AbilityPopupHost"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var experience := root.get_node("GameExperience")
	var previous_scene = experience.attached_scene
	var was_processing := experience.is_processing()
	experience.set_process(false)
	experience.attached_scene = host
	experience.call("_show_notice", "Lucky Rainbow", "Gives a chance at bonus coins.")
	await process_frame

	var notice := host.get_node_or_null("CompanionAbilityNotice")
	var card := notice.find_child("AbilityNoticeCard", true, false) if notice != null else null
	var copy := notice.find_child("AbilityNoticeCopy", true, false) if notice != null else null
	var close := notice.find_child("AbilityNoticeClose", true, false) if notice != null else null
	_check(card is PanelContainer and card.has_theme_stylebox_override("panel"), "companion power opens in a styled storybook card")
	_check(copy is Label and copy.text == "Gives a chance at bonus coins." and copy.get_theme_font_size("font_size") >= 24, "companion power popup uses large child-friendly text")
	_check(close is Button and close.has_meta("storybook_game_action"), "companion power popup has a large storybook close button")
	_check(host.find_children("*", "AcceptDialog", true, false).is_empty(), "companion power does not use an unstyled system dialog")

	if close is Button:
		close.pressed.emit()
	await process_frame
	_check(not host.has_node("CompanionAbilityNotice"), "GOT IT closes the companion power popup")

	host.queue_free()
	experience.attached_scene = previous_scene
	experience.set_process(was_processing)
	await process_frame
	if failures.is_empty():
		print("COMPANION ABILITY POPUP TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
