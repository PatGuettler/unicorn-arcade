extends Node

const MAIN_SCENE = preload("res://scenes/main.tscn")

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveService.begin_test_session()
	var profile := SaveService.create_profile("Profile Integration")
	AppState.data = profile
	AppState.shell_view = "profile"
	var shell := MAIN_SCENE.instantiate()
	add_child(shell)
	await shell.page_build_complete
	for _frame in 30:
		var candidate := shell.find_child("ProfileGameGrid", true, false)
		if is_instance_valid(candidate) and candidate.get_child_count() == GameRegistry.all_games().size() and shell.find_child("ProfileLoading", true, false) == null:
			break
		await get_tree().process_frame
	var grid := shell.find_child("ProfileGameGrid", true, false)
	var settings := shell.find_child("ProfileSettings", true, false)
	var meadow := shell.find_child("MeadowCompanionStage3D", true, false)
	if not is_instance_valid(grid) or grid.get_child_count() != GameRegistry.all_games().size() or not is_instance_valid(settings) or meadow != null:
		push_error("Profile-only integration assertions failed")
		get_tree().quit(1)
		return
	shell.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	SaveService.end_test_session()
	print("GODOT_RUNTIME_PROFILE_INTEGRATION_OK")
	get_tree().quit(0)
