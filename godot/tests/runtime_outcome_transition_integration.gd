extends Node


class OutcomeFixture extends ArcadeGameController:
	var game_id := "coin_count"
	var level := 1
	var active := true


class LegacyFixture extends Control:
	var active := true


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var experience := GameExperience
	var ad_service := AdBarService
	var prior := {"attached_scene": experience.attached_scene, "attached_controller": experience.attached_controller, "attached_game_id": experience.attached_game_id, "was_active": experience.was_active, "outcome_overlay": experience.outcome_overlay, "sparkle_retry_overlay": experience.sparkle_retry_overlay, "objective_primary": experience.objective_primary, "objective_detail": experience.objective_detail, "coin_button": experience.coin_button, "ability_button": experience.ability_button, "hint_button": experience.hint_button, "last_level": experience.last_level, "update_accumulator": experience.update_accumulator, "inactivity_seconds": experience.inactivity_seconds, "hosted_scene": ad_service._hosted_scene, "process": experience.is_processing()}
	var issues: Array[String] = []
	experience.set_process(false)
	var controller := OutcomeFixture.new()
	controller.name = "OutcomeControllerFixture"
	controller.set_process(false)
	add_child(controller)
	ad_service._hosted_scene = controller
	experience.attached_scene = controller
	experience.attached_controller = controller
	experience.attached_game_id = "coin_count"
	experience.was_active = true
	experience.last_level = controller.level
	experience.update_accumulator = 0.0
	experience.inactivity_seconds = 0.0
	experience.outcome_overlay = null
	experience.sparkle_retry_overlay = null
	controller.run_activity_changed.connect(experience._on_run_activity_changed)
	controller.active = false
	experience._process(0.2)
	await get_tree().process_frame
	if controller.get_node_or_null("GameOutcomeOverlay") != null:
		issues.append("controller polling does not synthesize an outcome")
	controller._last_active = true
	controller.publish_runtime_state()
	await get_tree().process_frame
	await get_tree().process_frame
	var first_overlay := controller.get_node_or_null("GameOutcomeOverlay")
	controller.publish_runtime_state()
	experience._on_run_activity_changed(false)
	await get_tree().process_frame
	var controller_overlays := controller.find_children("GameOutcomeOverlay", "Control", true, false)
	if not is_instance_valid(first_overlay) or controller_overlays.size() != 1:
		issues.append("controller activity signal creates exactly one outcome overlay")
	if is_instance_valid(first_overlay):
		first_overlay.queue_free()
	await get_tree().process_frame
	var legacy := LegacyFixture.new()
	legacy.name = "LegacyOutcomeFixture"
	add_child(legacy)
	ad_service._hosted_scene = legacy
	experience.attached_scene = legacy
	experience.attached_controller = null
	experience.attached_game_id = "coin_count"
	experience.was_active = true
	experience.outcome_overlay = null
	experience.sparkle_retry_overlay = null
	legacy.active = false
	experience._poll_legacy_run_activity(legacy)
	await get_tree().process_frame
	await get_tree().process_frame
	if legacy.get_node_or_null("GameOutcomeOverlay") == null:
		issues.append("legacy active-property polling remains functional")
	for overlay in legacy.find_children("GameOutcomeOverlay", "Control", true, false):
		overlay.queue_free()
	legacy.queue_free()
	controller.queue_free()
	await get_tree().process_frame
	experience.attached_scene = prior["attached_scene"]
	experience.attached_controller = prior["attached_controller"]
	experience.attached_game_id = prior["attached_game_id"]
	experience.was_active = prior["was_active"]
	experience.outcome_overlay = prior["outcome_overlay"]
	experience.sparkle_retry_overlay = prior["sparkle_retry_overlay"]
	experience.objective_primary = prior["objective_primary"]
	experience.objective_detail = prior["objective_detail"]
	experience.coin_button = prior["coin_button"]
	experience.ability_button = prior["ability_button"]
	experience.hint_button = prior["hint_button"]
	experience.last_level = prior["last_level"]
	experience.update_accumulator = prior["update_accumulator"]
	experience.inactivity_seconds = prior["inactivity_seconds"]
	ad_service._hosted_scene = prior["hosted_scene"]
	experience.set_process(prior["process"])
	if issues.is_empty():
		print("RUNTIME_OUTCOME_TRANSITION_INTEGRATION_OK")
		get_tree().quit(0)
	else:
		push_error("Outcome transition assertions failed: %s" % "; ".join(issues))
		get_tree().quit(1)
