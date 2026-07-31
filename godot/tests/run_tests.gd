extends SceneTree

const RewardServiceScript = preload("res://autoload/reward_service.gd")
const GameRegistryScript = preload("res://autoload/game_registry.gd")
const SaveServiceScript = preload("res://autoload/save_service.gd")

var failures: Array[String] = []


func _init() -> void:
	var rewards = RewardServiceScript.new()
	var registry = GameRegistryScript.new()
	var saves = SaveServiceScript.new()
	_check(rewards.level_reward(1) == 15, "level 1 reward is 15")
	_check(rewards.level_reward(10) == 60, "level 10 reward is 60")
	_check(rewards.hint_cost(1) == 0, "level 1 hints are free")
	_check(rewards.hint_cost(2) == 5, "paid hint cost is 5")
	_check(registry.all_games().size() == 22, "registry contains 22 games")
	_check(registry.games_in_category("Number").size() == 6, "number category contains 6 games")
	_check(registry.games_in_category("Word").size() == 10, "word category contains 10 games")
	_check(registry.games_in_category("Mystery").size() == 5, "mystery category contains 5 games")
	_check(registry.games_in_category("Arcade").size() == 1, "arcade category contains 1 game")
	var defaults: Dictionary = saves.default_state()
	_check(defaults["player"]["coins"] == 1000, "new players start with 1000 coins")
	_check(defaults["owned_companions"] == ["sparkle"], "new players own Sparkle")
	_check(_validate_sparkle_import(), "Sparkle GLB exposes required runtime pivots and meshes")
	rewards.free()
	registry.free()
	saves.free()
	if failures.is_empty():
		print("GODOT_PARITY_TESTS_OK: 12 checks passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _validate_sparkle_import() -> bool:
	var scene = load("res://assets/characters/sparkle/sparkle_v1.glb")
	if scene == null or not scene is PackedScene:
		return false
	var instance: Node = scene.instantiate()
	var required := ["SparkleRoot", "Pivot_Body", "Pivot_Head", "Pivot_Horn", "Pivot_Tail", "Pivot_FrontLeg_L", "Pivot_FrontLeg_R", "Pivot_HindLeg_L", "Pivot_HindLeg_R"]
	for node_name in required:
		if instance.find_child(node_name, true, false) == null:
			instance.free()
			return false
	var mesh_count := _count_meshes(instance)
	instance.free()
	return mesh_count >= 20


func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count
