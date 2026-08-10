class_name ScrollTapGuard
extends RefCounted

# Observes a native ScrollContainer gesture without ever moving the container.
# Controls use it to avoid treating the release of a swipe as an action press.
const DEFAULT_SUPPRESSION_MS := 220

var deadzone := 8.0
var suppression_ms := DEFAULT_SUPPRESSION_MS
var touch_index := -1
var surface := ""
var scroll_axis := ""
var dominant_axis := ""
var accumulated_motion := Vector2.ZERO
var scroll_active := false
var suppression_until_ms := 0
var _dragging := false


func _init(deadzone_value: float = 8.0, suppression_ms_value: int = DEFAULT_SUPPRESSION_MS) -> void:
	deadzone = deadzone_value
	suppression_ms = suppression_ms_value


func begin(surface_value: String, axis: String, touch: InputEventScreenTouch) -> void:
	if not touch.pressed:
		finish(touch)
		return
	# A new touch replaces an interrupted observation, but does not clear the
	# previous swipe's time window.
	_reset_observation()
	surface = surface_value
	scroll_axis = axis
	touch_index = touch.index


func observe_drag(drag: InputEventScreenDrag) -> void:
	if drag.index != touch_index or touch_index < 0:
		return
	accumulated_motion += drag.relative
	if not dominant_axis.is_empty() or accumulated_motion.length() < deadzone:
		return
	dominant_axis = "horizontal" if absf(accumulated_motion.x) > absf(accumulated_motion.y) else "vertical"
	_dragging = dominant_axis == scroll_axis


func finish(touch: InputEventScreenTouch) -> void:
	if touch.index != touch_index:
		return
	if _dragging or scroll_active:
		_suppress_actions()
	_reset_observation()


func on_scroll_started() -> void:
	scroll_active = true


func on_scroll_ended() -> void:
	if scroll_active or _dragging:
		_suppress_actions()
	_reset_observation()


func is_action_suppressed() -> bool:
	return Time.get_ticks_msec() < suppression_until_ms


func is_dragging() -> bool:
	return _dragging


func clear_suppression() -> void:
	suppression_until_ms = 0


func _suppress_actions() -> void:
	suppression_until_ms = Time.get_ticks_msec() + suppression_ms


func _reset_observation() -> void:
	touch_index = -1
	surface = ""
	scroll_axis = ""
	dominant_axis = ""
	accumulated_motion = Vector2.ZERO
	scroll_active = false
	_dragging = false
