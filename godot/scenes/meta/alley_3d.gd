extends Control

const HOUSE_POSITIONS := {
	"sparkle": Vector3(-4, 0, 0),
	"rainbow": Vector3(-2, 0, -2),
	"star": Vector3(0, 0, -3),
	"cloud": Vector3(2, 0, -2),
	"dream": Vector3(4, 0, 0),
	"mystic": Vector3(0, 0, 2),
}


func _ready() -> void:
	UiFactory.make_header(self, "Unicorn Alley", func(): SceneRouter.pop(), int(SaveManager.user_data.coins))

	var world: Node3D = $ViewportContainer/SubViewport/World
	var ground: MeshInstance3D = world.get_node("Ground")
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#1e1b4b")
	ground.material_override = mat

	for unicorn_id in HOUSE_POSITIONS.keys():
		_spawn_house(world, unicorn_id, HOUSE_POSITIONS[unicorn_id])


func _spawn_house(parent: Node3D, unicorn_id: String, pos: Vector3) -> void:
	var owned := unicorn_id in SaveManager.user_data.ownedUnicorns
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.2, 1.2, 1.2)
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = UiFactory.PINK if owned else Color("#334155")
	body.material_override = mat
	body.position = pos + Vector3(0, 0.6, 0)
	body.name = unicorn_id
	parent.add_child(body)

	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 1.5, 1.5)
	col.shape = shape
	area.add_child(col)
	area.position = body.position
	area.input_event.connect(func(_cam, event, _pos, _norm, _idx):
		if event is InputEventMouseButton and event.pressed:
			_on_house_tapped(unicorn_id, owned)
	)
	parent.add_child(area)


func _on_house_tapped(unicorn_id: String, owned: bool) -> void:
	if owned:
		SceneRouter.go_room(unicorn_id)
	else:
		SceneRouter.go_shop()
