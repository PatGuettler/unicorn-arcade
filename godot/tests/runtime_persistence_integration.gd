extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var prior_data := AppState.data.duplicate(true)
	var prior_dirty := AppState._has_unsaved_changes
	var counters := {"state": 0, "coins": 0, "failed": 0, "recovered": 0}
	var on_state := func() -> void: counters["state"] += 1
	var on_coins := func(_coins: int) -> void: counters["coins"] += 1
	var on_failed := func(_message: String) -> void: counters["failed"] += 1
	var on_recovered := func() -> void: counters["recovered"] += 1
	AppState.state_changed.connect(on_state)
	AppState.coins_changed.connect(on_coins)
	AppState.save_failed.connect(on_failed)
	AppState.save_recovered.connect(on_recovered)
	var issues: Array[String] = []
	if not SaveService.begin_test_session():
		issues.append("editor test session")
	else:
		AppState._has_unsaved_changes = false
		var imported := {
			"lastUser": "React B",
			"users": {
				"React A": {"name": "React A", "coins": 123},
				"React B": {"name": "React B", "coins": 456},
			},
		}
		LegacyReactImport._import_users(imported, "persistence-integration")
		var selected_agrees := AppState.player_name() == "React B" and SaveService._active_key == "react_b" and str(SaveService._envelope.get("last_user", "")) == "react_b" and SaveService.has_active_profile()
		var import_completed := str(SaveService._envelope.get("legacy_import", {}).get("status", "")) == "success"
		if not selected_agrees or not import_completed:
			issues.append("legacy imported-profile selection agreement")
		var saved_before_failure := SaveService._envelope.duplicate(true)
		var state_before_failure: int = counters["state"]
		var coins_before_failure: int = counters["coins"]
		SaveService.set_test_write_failure(true)
		AppState.set_setting("music", false)
		await get_tree().process_frame
		var failed_mutation_kept_memory: bool = not bool(AppState.setting("music", true)) and counters["state"] == state_before_failure + 1 and counters["coins"] == coins_before_failure + 1
		var failed_envelope_unchanged := JSON.stringify(SaveService._envelope) == JSON.stringify(saved_before_failure)
		if AppState.flush_pending_save():
			issues.append("failed retry remains dirty")
		await get_tree().process_frame
		var warning_layer := GameExperience.persistence_warning_layer
		var warning_banner := GameExperience.persistence_warning_banner
		var warning_label := warning_banner.get_node_or_null("PersistenceWarningText") as Label if is_instance_valid(warning_banner) else null
		var warning_layers := 0
		for child in GameExperience.get_children():
			if child.name == "PersistenceWarningLayer":
				warning_layers += 1
		var warning_visible := is_instance_valid(warning_layer) and is_instance_valid(warning_banner) and warning_layer == GameExperience.get_node_or_null("PersistenceWarningLayer") and warning_layers == 1
		var warning_nonblocking := warning_banner.mouse_filter == Control.MOUSE_FILTER_IGNORE and is_instance_valid(warning_label) and warning_label.mouse_filter == Control.MOUSE_FILTER_IGNORE
		if not failed_mutation_kept_memory or not failed_envelope_unchanged or not AppState.has_unsaved_changes() or counters["failed"] < 2 or not warning_visible or not warning_nonblocking:
			issues.append("failed mutation dirty state and warning")
		var active_before_guard := SaveService._active_key
		var profile_before_guard := AppState.player_name()
		if AppState.select_profile("React A") or AppState.logout() or SaveService._active_key != active_before_guard or AppState.player_name() != profile_before_guard:
			issues.append("dirty selection and logout guarding")
		SaveService.set_test_write_failure(false)
		SaveService._active_key = "react_a"
		var envelope_before_mismatch := SaveService._envelope.duplicate(true)
		if AppState.flush_pending_save() or JSON.stringify(SaveService._envelope) != JSON.stringify(envelope_before_mismatch):
			issues.append("mismatched identity refuses flush")
		SaveService._active_key = "react_b"
		if not AppState.flush_pending_save():
			issues.append("valid identity retry")
		await get_tree().process_frame
		var persisted_profile: Dictionary = SaveService._envelope.get("users", {}).get("react_b", {}).get("profile", {})
		var recovered_cleanly: bool = not AppState.has_unsaved_changes() and not bool(persisted_profile.get("settings", {}).get("music", true)) and counters["recovered"] == 1 and GameExperience.get_node_or_null("PersistenceWarningLayer") == null
		if not recovered_cleanly:
			issues.append("retry persistence and warning recovery")
	SaveService.set_test_write_failure(false)
	if AppState.state_changed.is_connected(on_state): AppState.state_changed.disconnect(on_state)
	if AppState.coins_changed.is_connected(on_coins): AppState.coins_changed.disconnect(on_coins)
	if AppState.save_failed.is_connected(on_failed): AppState.save_failed.disconnect(on_failed)
	if AppState.save_recovered.is_connected(on_recovered): AppState.save_recovered.disconnect(on_recovered)
	GameExperience._clear_persistence_warning()
	SaveService.end_test_session()
	AppState.data = prior_data
	AppState._has_unsaved_changes = prior_dirty
	if issues.is_empty():
		print("RUNTIME_PERSISTENCE_INTEGRATION_OK")
		get_tree().quit(0)
	else:
		push_error("Persistence integration assertions failed: %s" % "; ".join(issues))
		get_tree().quit(1)
