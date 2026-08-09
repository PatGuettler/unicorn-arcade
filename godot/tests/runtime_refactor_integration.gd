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
	if failures.is_empty():
		print("RUNTIME_REFACTOR_INTEGRATION_OK")
		get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		get_tree().quit(1)
