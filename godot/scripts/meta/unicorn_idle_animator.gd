class_name UnicornIdleAnimator
extends Node

var model: Node3D
var pivots := {}
var bases := {}
var timer: Timer
var last_animation := -1


func setup(target: Node3D) -> void:
	model = target
	for pivot_name in ["Pivot_Body", "Pivot_Head", "Pivot_Tail", "Pivot_FrontLeg_L", "Pivot_FrontLeg_R", "Pivot_HindLeg_L", "Pivot_HindLeg_R"]:
		var pivot := model.find_child(pivot_name, true, false) as Node3D
		if is_instance_valid(pivot):
			pivots[pivot_name] = pivot
			bases[pivot_name] = {"position": pivot.position, "rotation": pivot.rotation_degrees, "scale": pivot.scale}
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_play_random_animation)
	add_child(timer)


func _ready() -> void:
	if is_instance_valid(timer):
		timer.start(randf_range(1.4, 2.8))


func _play_random_animation() -> void:
	if not is_instance_valid(model) or pivots.is_empty():
		return
	_reset_pose()
	var animation := randi_range(0, 4)
	if animation == last_animation:
		animation = (animation + 1) % 5
	last_animation = animation
	match animation:
		0: _look_around()
		1: _tail_swish()
		2: _happy_step()
		3: _gentle_bow()
		_: _soft_breathe()


func _reset_pose() -> void:
	for pivot_name in pivots:
		var pivot: Node3D = pivots[pivot_name]
		var base: Dictionary = bases[pivot_name]
		pivot.position = base["position"]
		pivot.rotation_degrees = base["rotation"]
		pivot.scale = base["scale"]


func _look_around() -> void:
	var head := _pivot("Pivot_Head")
	if not is_instance_valid(head):
		_finish_later(1.2)
		return
	var base: Vector3 = bases["Pivot_Head"]["rotation"]
	var tween := create_tween()
	tween.tween_property(head, "rotation_degrees", base + Vector3(-5, 12, 4), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.35)
	tween.tween_property(head, "rotation_degrees", base, 0.55).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(_schedule_next)


func _tail_swish() -> void:
	var tail := _pivot("Pivot_Tail")
	if not is_instance_valid(tail):
		_finish_later(1.2)
		return
	var base: Vector3 = bases["Pivot_Tail"]["rotation"]
	var tween := create_tween()
	for angle in [16.0, -18.0, 11.0, 0.0]:
		tween.tween_property(tail, "rotation_degrees", base + Vector3(0, angle, angle * 0.35), 0.24).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(_schedule_next)


func _happy_step() -> void:
	var body := _pivot("Pivot_Body")
	var front_left := _pivot("Pivot_FrontLeg_L")
	var front_right := _pivot("Pivot_FrontLeg_R")
	if not is_instance_valid(body):
		_finish_later(1.2)
		return
	var body_base: Vector3 = bases["Pivot_Body"]["position"]
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "position", body_base + Vector3(0, 0.09, 0), 0.22).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(front_left):
		tween.tween_property(front_left, "rotation_degrees", bases["Pivot_FrontLeg_L"]["rotation"] + Vector3(18, 0, 0), 0.22)
	if is_instance_valid(front_right):
		tween.tween_property(front_right, "rotation_degrees", bases["Pivot_FrontLeg_R"]["rotation"] + Vector3(-12, 0, 0), 0.22)
	tween.chain().set_parallel(true)
	tween.tween_property(body, "position", body_base, 0.28).set_trans(Tween.TRANS_BOUNCE)
	if is_instance_valid(front_left):
		tween.tween_property(front_left, "rotation_degrees", bases["Pivot_FrontLeg_L"]["rotation"], 0.28)
	if is_instance_valid(front_right):
		tween.tween_property(front_right, "rotation_degrees", bases["Pivot_FrontLeg_R"]["rotation"], 0.28)
	tween.finished.connect(_schedule_next)


func _gentle_bow() -> void:
	var head := _pivot("Pivot_Head")
	if not is_instance_valid(head):
		_finish_later(1.2)
		return
	var base: Vector3 = bases["Pivot_Head"]["rotation"]
	var tween := create_tween()
	tween.tween_property(head, "rotation_degrees", base + Vector3(18, 0, -3), 0.42).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.32)
	tween.tween_property(head, "rotation_degrees", base, 0.5).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(_schedule_next)


func _soft_breathe() -> void:
	var body := _pivot("Pivot_Body")
	if not is_instance_valid(body):
		_finish_later(1.2)
		return
	var base: Vector3 = bases["Pivot_Body"]["scale"]
	var tween := create_tween()
	tween.tween_property(body, "scale", base * Vector3(1.012, 1.022, 1.012), 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_property(body, "scale", base, 0.7).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(_schedule_next)


func _pivot(pivot_name: String) -> Node3D:
	return pivots.get(pivot_name) as Node3D


func _finish_later(duration: float) -> void:
	get_tree().create_timer(duration).timeout.connect(_schedule_next)


func _schedule_next() -> void:
	if is_instance_valid(timer):
		timer.start(randf_range(2.2, 5.5))
