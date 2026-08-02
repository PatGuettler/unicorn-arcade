extends SceneTree

const PreviewScene = preload("res://scripts/meta/room_item_preview_3d.gd")
const Catalog = preload("res://scripts/meta_catalog.gd")

const EXPECTED := {
	"lamp": "AuthoredFurniture_lamp",
	"rug": "AuthoredFurniture_rug",
	"plant": "AuthoredFurniture_plant",
	"chair": "AuthoredFurniture_chair",
	"arcade": "AuthoredFurniture_arcade",
	"trophy": "AuthoredFurniture_trophy",
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for item_id in EXPECTED:
		var preview := PreviewScene.new()
		root.add_child(preview)
		preview.setup(Catalog.furniture_item(item_id))
		await process_frame
		if not preview.uses_authored_furniture_model:
			failures.append("%s did not select the authored model" % item_id)
		if preview.source_furniture_model_id != "store1:%s" % item_id:
			failures.append("%s reported the wrong source model" % item_id)
		if preview.find_child(EXPECTED[item_id], true, false) == null:
			failures.append("%s did not expose its named runtime mesh" % item_id)
		if preview.mesh_count < 2:
			failures.append("%s did not render authored geometry plus its contact shadow" % item_id)
		preview.free()
	if failures.is_empty():
		print("STORE1_INTEGRATION_PASS: six authored catalog models loaded")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
