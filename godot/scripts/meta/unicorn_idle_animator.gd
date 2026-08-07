class_name UnicornIdleAnimator
extends Node

const MIN_IDLE_SECONDS := 1.8
const MAX_IDLE_SECONDS := 4.5
const DEFAULT_ROAM_RADIUS := 1.15
const MIN_WALK_DISTANCE := 0.48
const WALK_SPEED := 0.62
const WALK_TURN_SECONDS := 0.28

var model: Node3D
var animation_player: AnimationPlayer
var timer: Timer
var available_animations: Array[StringName] = []
var walk_animation := StringName()
var idle_animation := StringName()
var active_action := StringName()
var last_animation_name := ""
var next_delay_seconds := 0.0
var rng := RandomNumberGenerator.new()
var walk_tween: Tween
var home_position := Vector3.ZERO
var home_rotation_y := 0.0
var roam_radius := DEFAULT_ROAM_RADIUS


func setup(target: Node3D, options: Dictionary = {}) -> void:
	model = target
	home_position = model.position
	home_rotation_y = model.rotation.y
	roam_radius = maxf(MIN_WALK_DISTANCE, float(options.get("roam_radius", DEFAULT_ROAM_RADIUS)))
	var roaming_seed := str(options.get("seed", target.name))
	# A stable seed gives every unicorn its own route without changing its
	# behavior every time a page is rebuilt.
	rng.seed = hash(roaming_seed)
	animation_player = _find_animation_player(model)
	timer = Timer.new()
	timer.name = "WalkTimer"
	timer.one_shot = true
	timer.timeout.connect(_start_walk)
	add_child(timer)
	if not is_instance_valid(animation_player):
		push_warning("Unicorn model %s has no AnimationPlayer." % model.name)
		return
	_collect_animations()
	walk_animation = _resolve_animation("walk")
	if walk_animation == &"":
		push_warning("Unicorn model %s has no Walk animation." % model.name)
		return
	var animation := animation_player.get_animation(walk_animation)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR
	_pose_standing()
	_schedule_next()


func animation_names() -> PackedStringArray:
	var names := PackedStringArray()
	for animation_name in available_animations:
		names.append(_simple_name(animation_name))
	return names


func play_random_animation_now() -> void:
	if is_instance_valid(timer):
		timer.stop()
	_start_walk()


func play_animation_now(requested: String) -> bool:
	if requested.to_lower() != "walk" or walk_animation == &"":
		return false
	if is_instance_valid(timer):
		timer.stop()
	_start_walk()
	return true


func _collect_animations() -> void:
	available_animations.clear()
	for animation_name in animation_player.get_animation_list():
		if _simple_name(animation_name) != "reset":
			available_animations.append(animation_name)


func _start_walk() -> void:
	if not is_instance_valid(animation_player) or walk_animation == &"":
		return
	_cancel_walk_journey()
	active_action = walk_animation
	last_animation_name = "walk"
	animation_player.play(walk_animation, 0.18)
	_start_walk_journey()


func _start_walk_journey() -> void:
	if not is_instance_valid(model):
		return
	var current_offset := model.position.z - home_position.z
	var destination_offset := rng.randf_range(-roam_radius, roam_radius)
	var attempts := 0
	while absf(destination_offset - current_offset) < MIN_WALK_DISTANCE and attempts < 6:
		destination_offset = rng.randf_range(-roam_radius, roam_radius)
		attempts += 1
	if absf(destination_offset - current_offset) < MIN_WALK_DISTANCE:
		destination_offset = -roam_radius if current_offset > 0.0 else roam_radius
	var direction := signf(destination_offset - current_offset)
	var destination := home_position + Vector3(0.0, 0.0, destination_offset)
	var facing_rotation := home_rotation_y if direction > 0.0 else home_rotation_y + PI
	var walk_seconds := maxf(0.65, absf(destination_offset - current_offset) / WALK_SPEED)
	walk_tween = create_tween()
	walk_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	walk_tween.tween_property(model, "rotation:y", facing_rotation, WALK_TURN_SECONDS)
	walk_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	walk_tween.tween_property(model, "position", destination, walk_seconds)
	walk_tween.tween_callback(_finish_walk_journey)


func _finish_walk_journey() -> void:
	walk_tween = null
	active_action = &""
	_pose_standing()
	_schedule_next()


func _cancel_walk_journey() -> void:
	if walk_tween != null and walk_tween.is_valid():
		walk_tween.kill()
	walk_tween = null


func _pose_standing() -> void:
	if not is_instance_valid(animation_player) or walk_animation == &"":
		return
	animation_player.play(walk_animation)
	animation_player.seek(0.0, true)
	animation_player.pause()
	_reset_skeleton_poses(model)


func _schedule_next() -> void:
	if not is_instance_valid(timer):
		return
	next_delay_seconds = rng.randf_range(MIN_IDLE_SECONDS, MAX_IDLE_SECONDS)
	timer.wait_time = next_delay_seconds
	if timer.is_inside_tree():
		timer.start()
	else:
		timer.autostart = true


func _resolve_animation(requested: String) -> StringName:
	for animation_name in available_animations:
		if _simple_name(animation_name) == requested.to_lower():
			return animation_name
	return &""


func _simple_name(animation_name: StringName) -> String:
	return String(animation_name).get_file().get_basename().to_lower()


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _reset_skeleton_poses(node: Node) -> void:
	if node is Skeleton3D:
		(node as Skeleton3D).reset_bone_poses()
	for child in node.get_children():
		_reset_skeleton_poses(child)
