class_name GameWorldViewport
extends Control

## Clipped game camera: drag to pan, pinch/wheel to zoom. No scrollbars.

signal camera_changed(pan: Vector2, zoom: float)

var world: Control
var pan := Vector2.ZERO
var zoom := 1.0
var min_zoom := 0.65
var max_zoom := 1.75
var drag_threshold := 10.0

var _touches := {}
var _pinch_distance := 0.0
var _pinch_zoom_start := 1.0
var _dragging := false
var _drag_start := Vector2.ZERO
var _pan_at_drag_start := Vector2.ZERO
var _drag_moved := false
var _suppress_next_press := false


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_world()
	_apply_camera()


func _ensure_world() -> void:
	if is_instance_valid(world):
		return
	world = Control.new()
	world.name = "World"
	world.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(world)


func mount(content: Control) -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_world()
	if content.get_parent() == world:
		return
	if content.get_parent() != null:
		content.get_parent().remove_child(content)
	world.add_child(content)
	_apply_camera()


func did_drag() -> bool:
	return _drag_moved


func consume_press_suppression() -> bool:
	if _suppress_next_press or _drag_moved:
		_suppress_next_press = false
		return true
	return false


func set_camera(next_pan: Vector2, next_zoom: float, emit_signal: bool = true) -> void:
	zoom = clampf(next_zoom, min_zoom, max_zoom)
	pan = next_pan
	_apply_camera()
	if emit_signal:
		camera_changed.emit(pan, zoom)


func focus_global_point(global_point: Vector2, viewport_ratio: Vector2 = Vector2(0.5, 0.32)) -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var local_point := get_global_transform_with_canvas().affine_inverse() * global_point
	var target := size * viewport_ratio
	# Point in world space before pan: (local - pan) / zoom ≈ world
	var world_point := (local_point - pan) / maxf(zoom, 0.001)
	var next_pan := target - world_point * zoom
	set_camera(next_pan, zoom)


func focus_control(target: Control, viewport_ratio: Vector2 = Vector2(0.5, 0.32)) -> void:
	if not is_instance_valid(target):
		return
	focus_global_point(target.global_position + target.size * 0.5, viewport_ratio)


func _apply_camera() -> void:
	if not is_instance_valid(world):
		return
	world.position = pan
	world.scale = Vector2(zoom, zoom)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		_zoom_at(get_local_mouse_position(), zoom * (event as InputEventMagnifyGesture).factor)
		accept_event()
	elif event is InputEventPanGesture:
		var pan_gesture := event as InputEventPanGesture
		set_camera(pan + pan_gesture.delta * -1.2, zoom)
		_drag_moved = true
		_suppress_next_press = true
		accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			_zoom_at(mouse.position, zoom * 1.08)
			accept_event()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_zoom_at(mouse.position, zoom * 0.92)
			accept_event()
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_begin_drag(mouse.position)
			else:
				_end_drag()
	elif event is InputEventMouseMotion and _dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_continue_drag((event as InputEventMouseMotion).position)
		accept_event()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not get_global_rect().has_point(_event_global_position(event)):
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = touch.position
			if _touches.size() == 1:
				_begin_drag(_to_local(touch.position))
			elif _touches.size() >= 2:
				_dragging = false
				_pinch_distance = _touch_distance()
				_pinch_zoom_start = zoom
		else:
			_touches.erase(touch.index)
			if _touches.size() < 2:
				_pinch_distance = 0.0
			if _touches.is_empty():
				_end_drag()
			elif _touches.size() == 1:
				var remaining: Vector2 = _touches.values()[0]
				_begin_drag(_to_local(remaining))
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_touches[drag.index] = drag.position
		if _touches.size() >= 2:
			var distance := _touch_distance()
			if _pinch_distance > 0.0:
				var center := _touch_center_local()
				_zoom_at(center, _pinch_zoom_start * distance / _pinch_distance)
			_drag_moved = true
			_suppress_next_press = true
			get_viewport().set_input_as_handled()
		elif _dragging:
			_continue_drag(_to_local(drag.position))
			if _drag_moved:
				get_viewport().set_input_as_handled()


func _begin_drag(local_point: Vector2) -> void:
	_dragging = true
	_drag_moved = false
	_drag_start = local_point
	_pan_at_drag_start = pan


func _continue_drag(local_point: Vector2) -> void:
	if not _dragging:
		return
	var delta := local_point - _drag_start
	if delta.length() >= drag_threshold:
		_drag_moved = true
		_suppress_next_press = true
	if _drag_moved:
		set_camera(_pan_at_drag_start + delta, zoom)


func _end_drag() -> void:
	_dragging = false


func _zoom_at(local_point: Vector2, next_zoom: float) -> void:
	var clamped := clampf(next_zoom, min_zoom, max_zoom)
	if is_equal_approx(clamped, zoom):
		return
	var world_point := (local_point - pan) / maxf(zoom, 0.001)
	var next_pan := local_point - world_point * clamped
	_drag_moved = true
	_suppress_next_press = true
	set_camera(next_pan, clamped)


func _touch_distance() -> float:
	var points: Array = _touches.values()
	if points.size() < 2:
		return 0.0
	return (points[0] as Vector2).distance_to(points[1] as Vector2)


func _touch_center_local() -> Vector2:
	var points: Array = _touches.values()
	if points.is_empty():
		return size * 0.5
	var sum := Vector2.ZERO
	for point in points:
		sum += _to_local(point)
	return sum / float(points.size())


func _to_local(global_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_point


func _event_global_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	if event is InputEventMouse:
		return (event as InputEventMouse).global_position
	return Vector2(-99999, -99999)
