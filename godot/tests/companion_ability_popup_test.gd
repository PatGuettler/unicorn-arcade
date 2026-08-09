extends SceneTree

var failures: Array[String] = []


class RetryFixture extends Control:
	var active := false
	var level := 1
	var retry_count := 0
	var action_button: Button
	var message_label: Label

	func _init() -> void:
		action_button = Button.new()
		action_button.text = "Retry"
		add_child(action_button)
		message_label = Label.new()
		message_label.text = "Three comets slipped through. Retry this rescue mission."
		add_child(message_label)

	func can_retry_failure() -> bool:
		return not active and action_button.text == "Retry"

	func retry_failure() -> void:
		retry_count += 1
		active = true
		action_button.hide()


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

	var app_state := root.get_node("AppState")
	var save_service := root.get_node("SaveService")
	var companion_service := root.get_node("CompanionAbilityService")
	var previous_data: Dictionary = app_state.data.duplicate(true)
	var previous_game_id: String = companion_service.game_id
	var previous_level: int = companion_service.level
	var previous_used: bool = companion_service.used
	app_state.data = save_service.default_profile("Second Sparkle Popup")
	app_state.data["player"]["equipped_companion"] = "sparkle"
	var retry_fixture := RetryFixture.new()
	root.add_child(retry_fixture)
	await process_frame
	experience.attached_scene = retry_fixture
	experience.attached_game_id = "retry_fixture"
	companion_service.begin_level("retry_fixture", retry_fixture.level)
	_check(companion_service.consume_checkpoint_retry(), "Second Sparkle is consumed before its blocking retry notice opens")
	experience.call("_show_sparkle_retry_notice", retry_fixture.message_label.text)
	await process_frame
	var sparkle_overlay := retry_fixture.get_node_or_null("SecondSparkleRetryOverlay")
	var sparkle_card := sparkle_overlay.find_child("SecondSparkleRetryCard", true, false) if sparkle_overlay != null else null
	var sparkle_reason := sparkle_overlay.find_child("SecondSparkleFailureReason", true, false) as Label if sparkle_overlay != null else null
	var sparkle_explanation := sparkle_overlay.find_child("SecondSparkleExplanation", true, false) as Label if sparkle_overlay != null else null
	var sparkle_continue := sparkle_overlay.find_child("SecondSparkleContinue", true, false) as Button if sparkle_overlay != null else null
	_check(sparkle_card is PanelContainer and sparkle_card.has_theme_stylebox_override("panel") and sparkle_reason != null and "Three comets slipped through" in sparkle_reason.text, "Second Sparkle uses a styled blocking notice containing the failure reason")
	_check(sparkle_explanation != null and "FREE RETRY" in sparkle_explanation.text and "same level" in sparkle_explanation.text and sparkle_continue != null, "Second Sparkle clearly explains its one-time free retry and exposes CONTINUE")
	_check(not retry_fixture.active and retry_fixture.retry_count == 0, "Second Sparkle does not restart gameplay while its notice is waiting for CONTINUE")
	experience.call("_show_game_outcome")
	await process_frame
	_check(retry_fixture.get_node_or_null("GameOutcomeOverlay") == null, "Second Sparkle blocks the normal outcome overlay while its retry notice is open")
	if sparkle_continue != null:
		sparkle_continue.pressed.emit()
	await process_frame
	await process_frame
	_check(retry_fixture.active and retry_fixture.level == 1 and retry_fixture.retry_count == 1 and retry_fixture.get_node_or_null("SecondSparkleRetryOverlay") == null, "CONTINUE restarts the same level exactly once and dismisses the blocking notice")
	_check(companion_service.used and not companion_service.consume_checkpoint_retry(), "Second Sparkle cannot provide a second free retry on the restarted level")
	retry_fixture.queue_free()
	app_state.data = previous_data
	companion_service.game_id = previous_game_id
	companion_service.level = previous_level
	companion_service.used = previous_used

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
