class_name UnicornIdleAnimator
extends Node

const MIN_IDLE_SECONDS := 10.0
const MAX_IDLE_SECONDS := 30.0
const WALK_DISTANCE := 1.15
const WALK_LEG_SECONDS := 2.0
const WALK_TURN_SECONDS := 0.32

var model: Node3D
var animation_player: AnimationPlayer
var timer: Timer
var available_animations: Array[StringName] = []
var idle_animation := StringName()
var active_action := StringName()
var last_animation_name := ""
var next_delay_seconds := 0.0
var rng := RandomNumberGenerator.new()
var walk_tween: Tween
var home_position := Vector3.ZERO
var home_rotation_y := 0.0


func setup(target: Node3D) -> void:
	model = target
	home_position = model.position
	home_rotation_y = model.rotation.y
	rng.randomize()
	animation_player = _find_animation_player(model)
	timer = Timer.new()
	timer.name = "RandomAnimationTimer"
	timer.one_shot = true
	timer.timeout.connect(_play_random_animation)
	add_child(timer)
	if not is_instance_valid(animation_player):
		push_warning("Unicorn model %s has no AnimationPlayer." % model.name)
		return
	animation_player.animation_finished.connect(_on_animation_finished)
	_collect_animations()
	idle_animation = _resolve_animation("idle")
	if idle_animation == &"":
		push_warning("Unicorn model %s has no idle animation." % model.name)
		return
	_configure_loop_modes()
	_begin_idle()
	_schedule_next()


func animation_names() -> PackedStringArray:
	var names := PackedStringArray()
	for animation_name in available_animations:
		names.append(_simple_name(animation_name))
	return names


func play_random_animation_now() -> void:
	if is_instance_valid(timer):
		timer.stop()
	_play_random_animation()


func play_animation_now(requested: String) -> bool:
	var resolved := _resolve_animation(requested)
	if resolved == &"" or resolved == idle_animation:
		return false
	if is_instance_valid(timer):
		timer.stop()
	_start_action(resolved)
	return true


func _collect_animations() -> void:
	available_animations.clear()
	for animation_name in animation_player.get_animation_list():
		if _simple_name(animation_name).to_lower() == "reset":
			continue
		available_animations.append(animation_name)


func _configure_loop_modes() -> void:
	for animation_name in available_animations:
		var animation := animation_player.get_animation(animation_name)
		if animation != null:
			var simple_name := _simple_name(animation_name)
			animation.loop_mode = Animation.LOOP_LINEAR if animation_name == idle_animation or simple_name == "walk" else Animation.LOOP_NONE


func _play_random_animation() -> void:
	if not is_instance_valid(animation_player):
		return
	var choices: Array[StringName] = []
	for animation_name in available_animations:
		if animation_name != idle_animation and _simple_name(animation_name).to_lower() != "reset":
			choices.append(animation_name)
	if choices.is_empty():
		_schedule_next()
		return
	var selected := choices[rng.randi_range(0, choices.size() - 1)]
	if choices.size() > 1 and _simple_name(selected) == last_animation_name:
		selected = choices[(choices.find(selected) + 1) % choices.size()]
	_start_action(selected)


func _start_action(selected: StringName) -> void:
	_cancel_walk_journey()
	active_action = selected
	last_animation_name = _simple_name(selected)
	animation_player.play(selected, 0.18)
	if last_animation_name == "walk":
		_start_walk_journey()


func _start_walk_journey() -> void:
	if not is_instance_valid(model):
		return
	model.position = home_position
	model.rotation.y = home_rotation_y
	walk_tween = create_tween()
	walk_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	walk_tween.tween_property(model, "rotation:y", home_rotation_y - PI / 2.0, WALK_TURN_SECONDS)
	walk_tween.tween_property(model, "position", home_position + Vector3(WALK_DISTANCE, 0.0, 0.0), WALK_LEG_SECONDS)
	walk_tween.tween_property(model, "rotation:y", home_rotation_y + PI / 2.0, WALK_TURN_SECONDS)
	walk_tween.tween_property(model, "position", home_position, WALK_LEG_SECONDS)
	walk_tween.tween_property(model, "rotation:y", home_rotation_y, WALK_TURN_SECONDS)
	walk_tween.tween_callback(_finish_walk_journey)


func _finish_walk_journey() -> void:
	if is_instance_valid(model):
		model.position = home_position
		model.rotation.y = home_rotation_y
	walk_tween = null
	active_action = &""
	_begin_idle()
	_schedule_next()


func _cancel_walk_journey() -> void:
	if walk_tween != null and walk_tween.is_valid():
		walk_tween.kill()
	walk_tween = null
	if is_instance_valid(model):
		model.position = home_position
		model.rotation.y = home_rotation_y


func _on_animation_finished(animation_name: StringName) -> void:
	if active_action == &"" or animation_name != active_action:
		return
	if _simple_name(active_action) == "walk":
		return
	active_action = &""
	_begin_idle()
	_schedule_next()


func _begin_idle() -> void:
	if is_instance_valid(animation_player) and idle_animation != &"":
		animation_player.play(idle_animation, 0.18)


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
		if _simple_name(animation_name).to_lower() == requested.to_lower():
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
