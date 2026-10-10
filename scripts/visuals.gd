extends RefCounted

# Helpers: shared meshes and materials; geometry is self-contained (no paid assets).
static func material(color: Color, texture_path: String = "", tiling: float = 1.0, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.83
	mat.metallic = metallic
	if texture_path != "" and ResourceLoader.exists(texture_path):
		mat.albedo_texture = load(texture_path)
		mat.uv1_scale = Vector3(tiling, tiling, 1.0)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat

static func box(parent: Node3D, position: Vector3, size: Vector3, mat: Material, collidable: bool = false) -> Node3D:
	var holder: Node3D
	if collidable:
		holder = StaticBody3D.new()
	else:
		holder = Node3D.new()
	holder.position = position
	var visible_mesh := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visible_mesh.mesh = mesh
	visible_mesh.material_override = mat
	holder.add_child(visible_mesh)
	if collidable:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		holder.add_child(collision)
	parent.add_child(holder)
	return holder

static func sphere(parent: Node3D, position: Vector3, scale_xyz: Vector3, mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = position
	var model := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	model.mesh = shape
	model.scale = scale_xyz
	model.material_override = mat
	pivot.add_child(model)
	parent.add_child(pivot)
	return pivot

static func cylinder(parent: Node3D, position: Vector3, radius: float, length: float, mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = position
	var model := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = length
	model.mesh = shape
	model.material_override = mat
	pivot.add_child(model)
	parent.add_child(pivot)
	return pivot

static func label_3d(parent: Node3D, text_value: String, position: Vector3, size: int = 45) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.position = position
	label.font_size = size
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	label.outline_modulate = Color(0.02, 0.02, 0.02)
	parent.add_child(label)
	return label
