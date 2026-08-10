extends Node

const MIN_LEFT := 8.0
const MIN_TOP := 40.0
const MIN_RIGHT := 8.0
const MIN_BOTTOM := 12.0

var applied_roots := {}


func _ready() -> void:
	get_tree().node_added.connect(_node_added)
	get_tree().scene_changed.connect(_on_scene_changed)
	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_schedule_current_root)
	var window := get_window()
	if window != null:
		window.focus_entered.connect(_schedule_current_root)
	_schedule_current_root()


func _on_scene_changed() -> void:
	_prune_applied_roots()
	_schedule_current_root()


func _prune_applied_roots() -> void:
	var current := AdBarService.content_scene()
	if not is_instance_valid(current):
		current = get_tree().current_scene
	for instance_id in applied_roots.keys():
		var node := instance_from_id(instance_id)
		if not is_instance_valid(node) or (is_instance_valid(current) and node != current and not current.is_ancestor_of(node)):
			applied_roots.erase(instance_id)


func _schedule_current_root() -> void:
	call_deferred("_apply_current_root")


func _apply_current_root() -> void:
	var current := AdBarService.content_scene()
	if not is_instance_valid(current):
		current = get_tree().current_scene
	if current is Control:
		_apply_to_root(current)


func _node_added(node: Node) -> void:
	if not node is Control:
		return
	call_deferred("_apply_if_scene_root_id", node.get_instance_id())


func _apply_if_scene_root_id(instance_id: int) -> void:
	var candidate := instance_from_id(instance_id)
	if not candidate is Control or not is_instance_valid(candidate):
		return
	var node := candidate as Control
	var current := AdBarService.content_scene()
	if not is_instance_valid(current):
		current = get_tree().current_scene
	if node == current or (is_instance_valid(current) and not current is Control and node.get_parent() == current):
		_apply_to_root(node)


func _apply_to_root(root: Control) -> void:
	if not is_instance_valid(root) or root.get_viewport() == null:
		return
	var viewport_size := root.get_viewport_rect().size
	if viewport_size.x < 1.0 or viewport_size.y < 1.0:
		return
	var insets := _screen_insets(viewport_size)
	var signature := Vector4(insets.position.x, insets.position.y, insets.size.x, insets.size.y)
	if applied_roots.get(root.get_instance_id(), Vector4(-1, -1, -1, -1)) == signature:
		return
	applied_roots[root.get_instance_id()] = signature
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = insets.position.x
	root.offset_top = insets.position.y
	root.offset_right = -insets.size.x
	root.offset_bottom = -insets.size.y


func _screen_insets(viewport_size: Vector2) -> Rect2:
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe := DisplayServer.get_display_safe_area()
	var scale := Vector2.ONE
	if window_size.x > 0.0 and window_size.y > 0.0:
		scale = viewport_size / window_size
	var left := float(safe.position.x) * scale.x
	var top := float(safe.position.y) * scale.y
	var right := maxf(0.0, window_size.x - float(safe.end.x)) * scale.x
	var bottom := maxf(0.0, window_size.y - float(safe.end.y)) * scale.y
	return Rect2(maxf(MIN_LEFT, left), maxf(MIN_TOP, top), maxf(MIN_RIGHT, right), maxf(MIN_BOTTOM, bottom))
