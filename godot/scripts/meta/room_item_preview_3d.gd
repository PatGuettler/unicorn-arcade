class_name RoomItemPreview3D
extends SubViewportContainer

const CHARACTER_SCENE = preload("res://assets/characters/sparkle/sparkle_v1.glb")
const UnicornIdleAnimatorScene = preload("res://scripts/meta/unicorn_idle_animator.gd")

var item_id := ""
var category := "cozy"
var mesh_count := 0
var uses_character_model := false


func setup(definition: Dictionary) -> void:
	item_id = str(definition.get("id", definition.get("item_id", "decor")))
	category = str(definition.get("category", "cozy"))
	uses_character_model = item_id.begins_with("companion_") or category == "companions"
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_viewport()


func _build_viewport() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(448, 320) if uses_character_model else Vector2i(192, 192)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if uses_character_model else SubViewport.UPDATE_ONCE
	add_child(viewport)
	var stage := Node3D.new()
	stage.name = "PreviewStage"
	viewport.add_child(stage)
	if uses_character_model:
		_build_companion(stage)
	else:
		_build_furniture(stage)
	_build_lighting(stage)


func _build_companion(stage: Node3D) -> void:
	var model: Node = CHARACTER_SCENE.instantiate()
	model.name = "LiveUnicornModel"
	model.position.y = -0.25
	stage.add_child(model)
	_tint_companion(model, item_id.trim_prefix("companion_"))
	mesh_count = _count_meshes(model)
	_add_companion_shadow(stage)
	var animator := UnicornIdleAnimatorScene.new()
	animator.name = "IdleAnimator"
	stage.add_child(animator)
	animator.setup(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.55
	stage.add_child(camera)
	camera.look_at_from_position(Vector3(4.6, 2.8, 6.5), Vector3(0.0, 1.48, -0.35), Vector3.UP)
	camera.current = true


func _add_companion_shadow(stage: Node3D) -> void:
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.88
	shadow_mesh.bottom_radius = 0.88
	shadow_mesh.height = 0.025
	shadow_mesh.material = _material(Color(0.12, 0.10, 0.24, 0.20), false)
	var shadow := MeshInstance3D.new()
	shadow.name = "MeadowContactShadow"
	shadow.mesh = shadow_mesh
	shadow.position = Vector3(0.0, 0.02, -0.05)
	shadow.scale.z = 0.58
	stage.add_child(shadow)


func _build_furniture(stage: Node3D) -> void:
	var model := Node3D.new()
	model.name = "FurnitureModel"
	model.rotation_degrees.y = -18.0
	stage.add_child(model)
	var palette := _palette()
	_add_shadow(model)
	if item_id == "lamp":
		_build_lava_lamp(model, palette)
	elif item_id == "rug" or category == "rugs":
		_build_rug(model, palette)
	elif item_id == "plant" or category == "nature":
		_build_plant(model, palette)
	elif category == "beds":
		_build_bed(model, palette)
	elif category == "tables":
		_build_table(model, palette)
	elif category == "lighting":
		_build_lamp(model, palette)
	elif category == "pets":
		_build_pet(model, palette)
	elif category == "toys":
		_build_toy(model, palette)
	elif category == "electronics":
		_build_electronics(model, palette)
	elif category == "seasonal":
		_build_seasonal(model, palette)
	elif category == "kitchen":
		_build_kitchen(model, palette)
	elif category == "wall":
		_build_wall_art(model, palette)
	elif category == "luxury":
		_build_luxury(model, palette)
	elif category == "unicorn":
		_build_unicorn_decor(model, palette)
	else:
		_build_chair(model, palette)
	mesh_count = _count_meshes(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.85
	stage.add_child(camera)
	camera.look_at_from_position(Vector3(3.7, 2.75, 4.8), Vector3(0.0, 0.62, 0.0), Vector3.UP)
	camera.current = true


func _build_lighting(stage: Node3D) -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -32, -18)
	key.light_energy = 0.82
	key.shadow_enabled = true
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(30, 140, 12)
	fill.light_color = Color("8bdff0")
	fill.light_energy = 0.32
	stage.add_child(fill)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e6dcff")
	environment.ambient_light_energy = 0.48
	environment_node.environment = environment
	stage.add_child(environment_node)


func _build_lava_lamp(parent: Node3D, palette: Dictionary) -> void:
	_cylinder(parent, "Base", 0.34, 0.24, 0.14, Vector3(0, 0.1, 0), palette.dark)
	_cylinder(parent, "Glass", 0.22, 0.34, 1.05, Vector3(0, 0.68, 0), Color(palette.accent, 0.78), true)
	_cylinder(parent, "Cap", 0.24, 0.34, 0.14, Vector3(0, 1.28, 0), palette.dark)
	for bubble in [[-0.08, 0.5, 0.03, 0.10], [0.09, 0.82, -0.03, 0.13], [-0.04, 1.03, 0.02, 0.08]]:
		_sphere(parent, "LavaBubble", float(bubble[3]), Vector3(bubble[0], bubble[1], bubble[2]), palette.light)


func _build_rug(parent: Node3D, palette: Dictionary) -> void:
	_box(parent, "Rug", Vector3(1.75, 0.08, 1.18), Vector3(0, 0.08, 0), palette.accent)
	for x in [-0.55, 0.0, 0.55]:
		_box(parent, "RugInlay", Vector3(0.18, 0.035, 1.05), Vector3(x, 0.135, 0), palette.light)


func _build_plant(parent: Node3D, palette: Dictionary) -> void:
	_cylinder(parent, "Planter", 0.35, 0.48, 0.55, Vector3(0, 0.3, 0), palette.accent)
	for index in 7:
		var angle := TAU * float(index) / 7.0
		var tip := Vector3(cos(angle) * 0.38, 1.05 + (index % 2) * 0.18, sin(angle) * 0.38)
		_cylinder(parent, "Stem", 0.035, 0.035, 0.72, Vector3(tip.x * 0.45, 0.75, tip.z * 0.45), Color("397756"))
		var leaf := _sphere(parent, "Leaf", 0.27, tip, Color("5bc881"))
		leaf.scale = Vector3(0.58, 1.0, 0.34)


func _build_bed(parent: Node3D, palette: Dictionary) -> void:
	_box(parent, "BedFrame", Vector3(1.85, 0.25, 1.2), Vector3(0, 0.25, 0), palette.dark)
	_box(parent, "Mattress", Vector3(1.68, 0.28, 1.05), Vector3(0, 0.5, 0), palette.light)
	_box(parent, "Blanket", Vector3(0.98, 0.08, 1.06), Vector3(0.32, 0.69, 0), palette.accent)
	_box(parent, "Pillow", Vector3(0.52, 0.16, 0.72), Vector3(-0.55, 0.73, 0), Color("f7f1ff"))
	_box(parent, "Headboard", Vector3(0.16, 1.12, 1.28), Vector3(-0.91, 0.72, 0), palette.dark)


func _build_table(parent: Node3D, palette: Dictionary) -> void:
	_box(parent, "TableTop", Vector3(1.75, 0.18, 1.05), Vector3(0, 0.9, 0), palette.accent)
	for x in [-0.68, 0.68]:
		for z in [-0.34, 0.34]:
			_cylinder(parent, "TableLeg", 0.09, 0.09, 0.85, Vector3(x, 0.44, z), palette.dark)


func _build_lamp(parent: Node3D, palette: Dictionary) -> void:
	_cylinder(parent, "LampBase", 0.42, 0.32, 0.12, Vector3(0, 0.08, 0), palette.dark)
	_cylinder(parent, "LampStem", 0.07, 0.07, 1.05, Vector3(0, 0.65, 0), palette.dark)
	_cylinder(parent, "LampShade", 0.28, 0.58, 0.62, Vector3(0, 1.35, 0), palette.accent)
	_sphere(parent, "LampGlow", 0.2, Vector3(0, 1.25, 0), Color("fff0a8"), true)


func _build_pet(parent: Node3D, palette: Dictionary) -> void:
	var body := _sphere(parent, "PetBody", 0.5, Vector3(0, 0.55, 0), palette.accent)
	body.scale = Vector3(1.18, 0.82, 0.72)
	_sphere(parent, "PetHead", 0.4, Vector3(0.48, 0.92, 0), palette.light)
	for z in [-0.21, 0.21]:
		_box(parent, "Ear", Vector3(0.16, 0.34, 0.12), Vector3(0.49, 1.31, z), palette.dark, Vector3(0, 0, -18 if z < 0 else 18))
	for x in [-0.34, 0.34]:
		for z in [-0.22, 0.22]:
			_cylinder(parent, "Paw", 0.09, 0.1, 0.42, Vector3(x, 0.23, z), palette.dark)


func _build_toy(parent: Node3D, palette: Dictionary) -> void:
	if "robot" in item_id:
		_box(parent, "RobotBody", Vector3(0.85, 0.72, 0.58), Vector3(0, 0.55, 0), palette.accent)
		_box(parent, "RobotHead", Vector3(0.68, 0.5, 0.52), Vector3(0, 1.17, 0), palette.light)
		for z in [-0.18, 0.18]: _sphere(parent, "RobotEye", 0.07, Vector3(0.35, 1.2, z), Color("6ef3ff"), true)
		return
	for index in 4:
		var x := -0.55 + float(index % 2) * 0.72
		var z := -0.28 + float(index / 2) * 0.62
		_box(parent, "ToyBlock", Vector3(0.56, 0.56, 0.56), Vector3(x, 0.3 + (index % 2) * 0.25, z), Color.from_hsv(fmod(float(index) * 0.21 + palette.hue, 1.0), 0.56, 0.95))


func _build_electronics(parent: Node3D, palette: Dictionary) -> void:
	_box(parent, "Cabinet", Vector3(1.28, 1.35, 0.72), Vector3(0, 0.72, 0), palette.dark)
	_box(parent, "Screen", Vector3(1.02, 0.7, 0.08), Vector3(0, 0.94, 0.4), Color("55cce7"), Vector3.ZERO, true)
	_box(parent, "ControlPanel", Vector3(0.86, 0.2, 0.44), Vector3(0, 0.42, 0.48), palette.accent, Vector3(-12, 0, 0))


func _build_seasonal(parent: Node3D, palette: Dictionary) -> void:
	if "tree" in item_id:
		_cylinder(parent, "Trunk", 0.13, 0.15, 0.55, Vector3(0, 0.3, 0), Color("79533d"))
		for y in [0.55, 0.92, 1.25]: _cylinder(parent, "Evergreen", 0.05, 0.72 - y * 0.18, 0.58, Vector3(0, y, 0), Color("3b9b68"))
		return
	if "gift" in item_id:
		_box(parent, "Gift", Vector3(1.2, 0.88, 1.0), Vector3(0, 0.46, 0), palette.accent)
		_box(parent, "Ribbon", Vector3(0.18, 0.94, 1.05), Vector3(0, 0.5, 0), palette.light)
		return
	for x in [-0.24, 0.0, 0.24]: _sphere(parent, "Pumpkin", 0.42, Vector3(x, 0.46, 0), Color("ef8b35"))
	_cylinder(parent, "PumpkinStem", 0.07, 0.08, 0.28, Vector3(0, 0.93, 0), Color("4f7845"))


func _build_kitchen(parent: Node3D, palette: Dictionary) -> void:
	_box(parent, "KitchenCabinet", Vector3(1.55, 1.0, 0.78), Vector3(0, 0.53, 0), palette.accent)
	_box(parent, "Counter", Vector3(1.72, 0.16, 0.92), Vector3(0, 1.08, 0), palette.light)
	for x in [-0.38, 0.38]: _box(parent, "CabinetDoor", Vector3(0.62, 0.65, 0.05), Vector3(x, 0.55, 0.42), palette.dark)


func _build_wall_art(parent: Node3D, palette: Dictionary) -> void:
	_box(parent, "Frame", Vector3(1.48, 1.35, 0.12), Vector3(0, 0.82, 0), palette.dark)
	_box(parent, "Painting", Vector3(1.22, 1.08, 0.08), Vector3(0, 0.82, 0.1), palette.light)
	_box(parent, "Landscape", Vector3(0.95, 0.38, 0.06), Vector3(0, 0.57, 0.16), palette.accent, Vector3(0, 0, 12))


func _build_luxury(parent: Node3D, palette: Dictionary) -> void:
	if "trophy" in item_id or "crown" in item_id:
		_cylinder(parent, "TrophyBase", 0.5, 0.58, 0.18, Vector3(0, 0.12, 0), Color("e0a82e"), true)
		_cylinder(parent, "TrophyStem", 0.11, 0.16, 0.62, Vector3(0, 0.48, 0), Color("ffd166"), true)
		_sphere(parent, "TrophyCup", 0.43, Vector3(0, 1.05, 0), Color("ffd166"), true)
		return
	var crystal := _cylinder(parent, "Crystal", 0.08, 0.5, 1.45, Vector3(0, 0.78, 0), palette.accent, true)
	crystal.rotation_degrees.z = 8


func _build_unicorn_decor(parent: Node3D, palette: Dictionary) -> void:
	_cylinder(parent, "FountainBasin", 0.72, 0.9, 0.22, Vector3(0, 0.14, 0), Color("70dbe8"), true)
	_cylinder(parent, "Pedestal", 0.22, 0.34, 0.72, Vector3(0, 0.55, 0), palette.light)
	var horn := _cylinder(parent, "Horn", 0.04, 0.25, 0.9, Vector3(0, 1.25, 0), Color("ffd166"), true)
	horn.rotation_degrees.z = -12


func _build_chair(parent: Node3D, palette: Dictionary) -> void:
	_box(parent, "Seat", Vector3(1.18, 0.28, 1.0), Vector3(0, 0.62, 0), palette.accent)
	_box(parent, "Back", Vector3(0.24, 1.18, 1.08), Vector3(-0.48, 1.14, 0), palette.dark, Vector3(0, 0, -8))
	for x in [-0.42, 0.42]:
		for z in [-0.34, 0.34]: _cylinder(parent, "ChairLeg", 0.07, 0.08, 0.58, Vector3(x, 0.3, z), palette.dark)


func _add_shadow(parent: Node3D) -> void:
	var shadow := _cylinder(parent, "ContactShadow", 0.92, 0.92, 0.025, Vector3(0, 0.015, 0), Color(0.04, 0.03, 0.12, 0.2))
	shadow.scale.z = 0.58


func _box(parent: Node3D, node_name: String, dimensions: Vector3, location: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO, emission := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.material = _material(color, emission)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = location
	instance.rotation_degrees = rotation
	parent.add_child(instance)
	return instance


func _sphere(parent: Node3D, node_name: String, radius: float, location: Vector3, color: Color, emission := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 12
	mesh.material = _material(color, emission)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = location
	parent.add_child(instance)
	return instance


func _cylinder(parent: Node3D, node_name: String, top_radius: float, bottom_radius: float, height: float, location: Vector3, color: Color, emission := false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.material = _material(color, emission)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = location
	parent.add_child(instance)
	return instance


func _material(color: Color, emission := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = 0.55
	return material


func _palette() -> Dictionary:
	var hue := float(abs(item_id.hash()) % 360) / 360.0
	var accent := Color.from_hsv(hue, 0.5, 0.92)
	return {"hue": hue, "accent": accent, "dark": accent.darkened(0.58), "light": accent.lightened(0.42)}


func _tint_companion(node: Node, companion_id: String) -> void:
	var palettes := {
		"rainbow": {"coat": Color("f3f0ff"), "hoof": Color("7654a8"), "mane": [Color("ef699f"), Color("55cfe0"), Color("ffd166"), Color("8f73dc")]},
		"star": {"coat": Color("ded8f6"), "hoof": Color("45356f"), "mane": [Color("ffe077"), Color("6678d7"), Color("68d4e7"), Color("b57bd8")]},
		"cloud": {"coat": Color("eef6ff"), "hoof": Color("758bbd"), "mane": [Color("bcdfff"), Color("d9bdf4"), Color("f6c8df"), Color("91d6de")]},
		"dream": {"coat": Color("d7d5ec"), "hoof": Color("30325d"), "mane": [Color("303b75"), Color("7f59a8"), Color("d49ad8"), Color("e7bd66")]},
		"mystic": {"coat": Color("d9d4ef"), "hoof": Color("3e285d"), "mane": [Color("35c9bd"), Color("8257cb"), Color("d65faa"), Color("5aa7d8")]},
	}
	if not palettes.has(companion_id):
		return
	var palette: Dictionary = palettes[companion_id]
	for child in node.get_children():
		_tint_companion(child, companion_id)
	if not node is MeshInstance3D:
		return
	var mesh_instance := node as MeshInstance3D
	for surface in mesh_instance.mesh.get_surface_count():
		var source := mesh_instance.get_active_material(surface)
		if not source is BaseMaterial3D:
			continue
		var material := source.duplicate() as BaseMaterial3D
		var label := "%s %s" % [source.resource_name, mesh_instance.name]
		if "Coat" in label or "Muzzle" in label or "InnerEar" in label:
			material.albedo_color = palette.coat
		elif "Hoof" in label:
			material.albedo_color = palette.hoof
		elif "ManeCyan" in label:
			material.albedo_color = palette.mane[0]
		elif "ManePink" in label:
			material.albedo_color = palette.mane[1]
		elif "ManeYellow" in label:
			material.albedo_color = palette.mane[2]
		elif "ManePurple" in label:
			material.albedo_color = palette.mane[3]
		mesh_instance.set_surface_override_material(surface, material)


func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count
