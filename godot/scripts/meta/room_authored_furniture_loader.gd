class_name RoomAuthoredFurnitureLoader
extends RefCounted

const STORE_MODEL_CATALOG_PATH := "res://data/store_model_catalog.json"

static var _store_model_catalog: Dictionary = {}
static var _store_scene_cache: Dictionary = {}


static func build(item_id: String, parent: Node3D) -> Dictionary:
	var definition: Dictionary = _store_catalog_items().get(item_id, {})
	if definition.is_empty():
		return {"built": false, "source_model_id": ""}
	var scene_path := str(definition.get("scene", ""))
	var packed_scene := _load_store_scene(scene_path)
	if packed_scene == null:
		return {"built": false, "source_model_id": ""}
	var source_root := packed_scene.instantiate() as Node3D
	var node_name := str(definition.get("node", item_id))
	var source_node := source_root.find_child(node_name, true, false) as Node3D if source_root != null else null
	if source_node == null:
		if source_root != null:
			source_root.free()
		return {"built": false, "source_model_id": ""}
	var source_parent := source_node.get_parent()
	if source_parent != null:
		source_parent.remove_child(source_node)
	source_node.owner = null
	parent.add_child(source_node)
	source_node.name = "AuthoredFurniture_%s" % item_id
	source_node.transform = Transform3D.IDENTITY
	source_node.scale = Vector3.ONE * float(definition.get("scale", 1.0))
	source_root.free()
	return {"built": true, "source_model_id": "%s:%s" % [scene_path.get_file().get_basename().trim_suffix("_mobile"), item_id]}


static func _store_catalog_items() -> Dictionary:
	if not _store_model_catalog.is_empty():
		return _store_model_catalog
	var file := FileAccess.open(STORE_MODEL_CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_store_model_catalog = parsed.get("items", {})
	return _store_model_catalog


static func _load_store_scene(scene_path: String) -> PackedScene:
	if scene_path.is_empty():
		return null
	if _store_scene_cache.has(scene_path):
		return _store_scene_cache[scene_path] as PackedScene
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene != null:
		_store_scene_cache[scene_path] = packed_scene
	return packed_scene
