extends Node

const RoomEditor = preload("res://scripts/meta/room_editor.gd")
const RoomItemPreview3D = preload("res://scripts/meta/room_item_preview_3d.gd")

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	if not value: failures.append(message)


func _has_visible_pixels(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var image := texture.get_image()
	return image != null and not image.is_empty() and image.get_used_rect().has_area()


func _fixture_room_button(texture: Texture2D) -> Button:
	var button := Button.new()
	button.size = Vector2(112, 112)
	button.rotation_degrees = 0.0
	var cached := TextureRect.new()
	cached.name = "CachedDecorPreview"
	cached.texture = texture
	cached.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cached.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(cached)
	return button


func _live_decor_count(buttons: Array) -> int:
	var count := 0
	for button in buttons:
		if is_instance_valid(button) and is_instance_valid((button as Button).get_node_or_null("RoomItemPreview3D")):
			count += 1
	return count

func _run() -> void:
	var received: Array = []
	var path := "res://scenes/games/coin_count.tscn"
	RuntimeAssetLoader.load_packed_scene(path, func(scene: PackedScene) -> void: received.append(scene))
	RuntimeAssetLoader.load_packed_scene(path, func(scene: PackedScene) -> void: received.append(scene))
	for frame in 120:
		await get_tree().process_frame
	_check(received.size() == 2 and received[0] != null and received[0] == received[1], "loader coalesces duplicate successful requests")
	var missing: Array = []
	RuntimeAssetLoader.load_packed_scene("res://missing/refactor-test.tscn", func(scene: PackedScene) -> void: missing.append(scene))
	for frame in 3:
		await get_tree().process_frame
	_check(missing.size() == 1 and missing[0] == null and not RuntimeAssetLoader.is_processing(), "loader reports a missing path and idles")
	var definition := {"id":"rug", "category":"rugs"}
	var yaw := 45.0
	var rotation_preview := RoomItemPreview3D.new()
	rotation_preview.setup(definition.merged({"animate": false, "presentation": "cache"}, true))
	rotation_preview.set_display_yaw(0.0)
	var rotation_root := rotation_preview.display_rotation_root
	var zero_yaw_is_upright := is_instance_valid(rotation_root) and is_zero_approx(rotation_root.rotation_degrees.x) and is_zero_approx(rotation_root.rotation_degrees.y) and is_zero_approx(rotation_root.rotation_degrees.z)
	rotation_preview.set_display_yaw(yaw)
	_check(zero_yaw_is_upright and is_equal_approx(rotation_root.rotation_degrees.y, yaw) and is_zero_approx(rotation_root.rotation_degrees.x) and is_zero_approx(rotation_root.rotation_degrees.z), "3D decor rotation root turns only around Y for each requested yaw")
	rotation_preview.free()
	_check(DecorPreviewCache.cache_key(definition, 0.0) != DecorPreviewCache.cache_key(definition, yaw), "decor cache keeps 0 and 45 degree renders in distinct yaw keys")
	var transparent_readback := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	_check(not bool(DecorPreviewCache.call("_has_visible_pixels", transparent_readback)), "decor cache rejects a fully transparent viewport readback")
	var textures: Array = []
	DecorPreviewCache.request(definition, yaw, func(texture: Texture2D) -> void: textures.append(texture))
	DecorPreviewCache.request(definition, yaw, func(texture: Texture2D) -> void: textures.append(texture))
	_check(DecorPreviewCache.active_viewport_count() <= 1, "decor cache has at most one transient viewport")
	for frame in 40:
		await get_tree().process_frame
	for frame in 3:
		await get_tree().process_frame
	_check(textures.size() == 2 and textures[0] is ImageTexture and _has_visible_pixels(textures[0]) and textures[0] == textures[1] and DecorPreviewCache.is_thumbnail_fallback(definition, yaw), "Fluffy Rug cache coalesces active duplicates into a visible thumbnail fallback ImageTexture")
	var room_editor := RoomEditor.new()
	var placeholder := room_editor.call("_decor_thumbnail", "rug") as Texture2D
	_check(_has_visible_pixels(placeholder), "room editor assigns the Fluffy Rug thumbnail while its 3D preview is pending")
	var preview_parent := Button.new()
	preview_parent.size = Vector2(100, 100)
	preview_parent.rotation_degrees = 0.0
	var preview := TextureRect.new()
	preview.name = "CachedDecorPreview"
	preview.size = preview_parent.size
	preview_parent.add_child(preview)
	room_editor.call("_refresh_cached_decor_preview", preview_parent, definition, yaw)
	_check(preview.texture == textures[0] and is_zero_approx(preview.rotation_degrees) and is_zero_approx(preview_parent.rotation_degrees), "room editor keeps both the fallback Fluffy Rug texture and its button upright")
	preview_parent.free()
	room_editor.free()
	var teardown_editor := RoomEditor.new()
	teardown_editor.selected_id = "forced_empty_capture"
	teardown_editor.local_items = [{"instance_id": "forced_empty_capture", "item_id": "rug", "rotation": 45.0}]
	var teardown_button := Button.new()
	var retained_cached := TextureRect.new()
	retained_cached.name = "CachedDecorPreview"
	retained_cached.texture = placeholder
	retained_cached.hide()
	teardown_button.add_child(retained_cached)
	var empty_live_preview := RoomItemPreview3D.new()
	empty_live_preview.name = "RoomItemPreview3D"
	teardown_button.add_child(empty_live_preview)
	teardown_editor.item_buttons = {"forced_empty_capture": teardown_button}
	teardown_editor.call("_retire_live_decor_preview", "forced_empty_capture")
	_check(retained_cached.visible and retained_cached.texture == placeholder and empty_live_preview.is_queued_for_deletion(), "empty live-readback teardown restores the retained cached snapshot before freeing the live preview")
	teardown_button.free()
	teardown_editor.free()
	var lifecycle_host := Control.new()
	add_child(lifecycle_host)
	var lifecycle_editor := RoomEditor.new()
	var first_item := {"instance_id": "live_rug_a", "item_id": "rug", "rotation": 0.0, "scale": 1.0}
	var second_item := {"instance_id": "live_rug_b", "item_id": "rug", "rotation": 0.0, "scale": 1.0}
	var first_button := _fixture_room_button(placeholder)
	var second_button := _fixture_room_button(placeholder)
	second_button.position.x = 120.0
	lifecycle_host.add_child(first_button)
	lifecycle_host.add_child(second_button)
	lifecycle_editor.local_items = [first_item, second_item]
	lifecycle_editor.item_buttons = {"live_rug_a": first_button, "live_rug_b": second_button}
	lifecycle_editor.selected_id = "live_rug_a"
	lifecycle_editor.call("_activate_selected_live_decor")
	for _frame in 4:
		await get_tree().process_frame
	var first_cached := first_button.get_node_or_null("CachedDecorPreview") as TextureRect
	var first_live := first_button.get_node_or_null("RoomItemPreview3D") as RoomItemPreview3D
	var first_root := first_live.display_rotation_root if is_instance_valid(first_live) else null
	_check(is_instance_valid(first_live) and _live_decor_count([first_button, second_button]) == 1 and not first_cached.visible and is_instance_valid(first_root) and is_zero_approx(first_root.rotation_degrees.x) and is_zero_approx(first_root.rotation_degrees.z), "selecting decor mounts one live RoomItemPreview3D and hides its cached snapshot")
	first_item["rotation"] = 45.0
	lifecycle_editor.call("_activate_selected_live_decor")
	_check(is_equal_approx(first_root.rotation_degrees.y, 45.0) and is_zero_approx(first_root.rotation_degrees.x) and is_zero_approx(first_root.rotation_degrees.z) and is_zero_approx(first_button.rotation_degrees), "selected live decor updates only DisplayRotationRoot Y when its saved yaw rotates")
	lifecycle_editor.call("_retire_live_decor_preview", "live_rug_a")
	await get_tree().process_frame
	_check(not is_instance_valid(first_button.get_node_or_null("RoomItemPreview3D")) and first_cached.visible and first_cached.texture != null, "retiring selected decor frees its live viewport and restores a visible frozen snapshot")
	lifecycle_editor.selected_id = "live_rug_b"
	lifecycle_editor.call("_activate_selected_live_decor")
	await get_tree().process_frame
	var second_live := second_button.get_node_or_null("RoomItemPreview3D") as RoomItemPreview3D
	_check(is_instance_valid(second_live) and _live_decor_count([first_button, second_button]) == 1, "switching selection still leaves exactly one live decor viewport")
	lifecycle_editor.call("_retire_live_decor_preview", "live_rug_b")
	await get_tree().process_frame
	lifecycle_editor.selected_id = "live_rug_a"
	lifecycle_editor.call("_activate_selected_live_decor")
	await get_tree().process_frame
	var restored_live := first_button.get_node_or_null("RoomItemPreview3D") as RoomItemPreview3D
	var restored_root := restored_live.display_rotation_root if is_instance_valid(restored_live) else null
	_check(is_instance_valid(restored_root) and is_equal_approx(restored_root.rotation_degrees.y, 45.0) and _live_decor_count([first_button, second_button]) == 1, "reselecting decor restores its saved live 3D yaw without adding another viewport")
	lifecycle_editor.call("_retire_live_decor_preview", "live_rug_a")
	await get_tree().process_frame
	lifecycle_host.queue_free()
	lifecycle_editor.free()
	if failures.is_empty():
		print("RUNTIME_REFACTOR_INTEGRATION_OK")
		get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		get_tree().quit(1)
