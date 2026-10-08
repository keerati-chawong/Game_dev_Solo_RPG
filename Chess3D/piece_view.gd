class_name PieceView
extends Node3D
## Low-poly 3D model of one piece, built from primitive meshes.

const SEGMENTS := 12

static var _materials := {}

var data: PieceData
var body: Node3D
var _bubble: MeshInstance3D
var _label: Label3D


func setup(p: PieceData) -> void:
	data = p
	p.view = self

	body = Node3D.new()
	add_child(body)

	_bubble = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.46
	sphere.height = 0.92
	sphere.radial_segments = 16
	sphere.rings = 8
	_bubble.mesh = sphere
	_bubble.scale = Vector3(1, 1.35, 1)
	_bubble.position.y = 0.6
	_bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bubble)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 44
	_label.outline_size = 12
	_label.pixel_size = 0.005
	_label.position.y = 1.6
	_label.modulate = Color(1, 0.86, 0.35) if p.side == Rules.WHITE else Color(1, 0.5, 0.45)
	add_child(_label)

	rebuild()


## Rebuilds the mesh, e.g. after a pawn promotes.
func rebuild() -> void:
	for child in body.get_children():
		child.queue_free()
	body.rotation.y = PI if data.side == Rules.BLACK else 0.0
	var m := _material(data.side, false)
	var a := _material(data.side, true)
	match data.type:
		Rules.PAWN:
			_cyl(0.3, 0.26, 0.1, 0.0, m)
			_cyl(0.22, 0.12, 0.38, 0.1, m)
			_ball(0.17, 0.62, m)
		Rules.ROOK:
			_cyl(0.34, 0.3, 0.12, 0.0, m)
			_cyl(0.25, 0.22, 0.5, 0.12, m)
			_cyl(0.3, 0.3, 0.16, 0.62, m)
			for x in [-0.17, 0.17]:
				for z in [-0.17, 0.17]:
					_box(Vector3(0.14, 0.12, 0.14), Vector3(x, 0.84, z), a)
		Rules.KNIGHT:
			_cyl(0.34, 0.3, 0.12, 0.0, m)
			_cyl(0.24, 0.17, 0.28, 0.12, m)
			_box(Vector3(0.2, 0.5, 0.26), Vector3(0, 0.62, 0.03), m, Vector3(-0.25, 0, 0))
			_box(Vector3(0.18, 0.2, 0.42), Vector3(0, 0.88, -0.12), m, Vector3(0.3, 0, 0))
			for x in [-0.06, 0.06]:
				_box(Vector3(0.05, 0.12, 0.05), Vector3(x, 1.03, 0.04), a)
		Rules.BISHOP:
			_cyl(0.34, 0.3, 0.12, 0.0, m)
			_cyl(0.24, 0.1, 0.55, 0.12, m)
			_ball(0.17, 0.82, m, 1.35)
			_ball(0.06, 1.08, a)
		Rules.QUEEN:
			_cyl(0.36, 0.32, 0.12, 0.0, m)
			_cyl(0.26, 0.12, 0.7, 0.12, m)
			_cyl(0.14, 0.25, 0.14, 0.82, a)
			_ball(0.1, 1.04, a)
		Rules.KING:
			_cyl(0.36, 0.32, 0.12, 0.0, m)
			_cyl(0.27, 0.14, 0.75, 0.12, m)
			_cyl(0.15, 0.26, 0.14, 0.87, a)
			_box(Vector3(0.07, 0.3, 0.07), Vector3(0, 1.16, 0), a)
			_box(Vector3(0.22, 0.07, 0.07), Vector3(0, 1.2, 0), a)
	refresh()


## Updates the level tag and the shield bubble.
func refresh() -> void:
	var text := ""
	if data.level > 1:
		text = "Lv%d" % data.level
	if data.ability_count > 0:
		text += (" " if text != "" else "") + "*".repeat(data.ability_count)
	_label.text = text

	_bubble.visible = data.shield > 0
	if data.shield > 0:
		_bubble.material_override = _shield_material(data.shield)


func _cyl(bottom: float, top: float, height: float, y: float, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = SEGMENTS
	mesh.rings = 1
	_add(mesh, Vector3(0, y + height / 2.0, 0), mat)


func _ball(radius: float, y: float, mat: Material, stretch := 1.0) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = SEGMENTS
	mesh.rings = 6
	var node := _add(mesh, Vector3(0, y, 0), mat)
	node.scale.y = stretch


func _box(size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := _add(mesh, pos, mat)
	node.rotation = rot


func _add(mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	body.add_child(node)
	return node


static func _material(side: int, accent: bool) -> StandardMaterial3D:
	var key := side * 2 + int(accent)
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.roughness = 0.45
		if accent:
			mat.albedo_color = Color(0.95, 0.75, 0.25) if side == Rules.WHITE else Color(0.8, 0.2, 0.25)
			mat.metallic = 0.4
		else:
			mat.albedo_color = Color(0.86, 0.82, 0.72) if side == Rules.WHITE else Color(0.17, 0.16, 0.22)
		_materials[key] = mat
	return _materials[key]


static func _shield_material(count: int) -> StandardMaterial3D:
	var key := 100 + count
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.4, 0.8, 1.0, 0.14 + 0.1 * count)
		_materials[key] = mat
	return _materials[key]
