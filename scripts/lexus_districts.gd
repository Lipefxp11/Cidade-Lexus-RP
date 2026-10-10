extends RefCounted

# Cenários originais e procedurais. Os nomes são elementos de ficção RP;
# não representam veículos/licenças oficiais nem uma reprodução exata do Rio.
const Visuals = preload("res://scripts/visuals.gd")

static func is_favela(cell: Vector2i) -> bool:
	if cell == Vector2i(-1, 0) or cell == Vector2i(0, -1) or cell == Vector2i(-1, -1):
		return true
	return absi(cell.x) + absi(cell.y) >= 3 and (absi(cell.x * 7 + cell.y * 11) % 4) == 0

static func service_for(cell: Vector2i, side_x: int, side_z: int) -> Dictionary:
	if cell == Vector2i.ZERO:
		if side_x == -1 and side_z == -1:
			return {"id": "skins", "title": "LEXUS STORE | ROUPAS", "type": "skins", "team": "", "color": Color(0.14, 0.20, 0.27)}
		if side_x == 1 and side_z == -1:
			return {"id": "dealer", "title": "LEXUS MOTORS | CARROS", "type": "dealer", "team": "", "color": Color(0.17, 0.23, 0.27)}
		if side_x == 1 and side_z == 1:
			return {"id": "tuning", "title": "LEXUS CUSTOM | TUNAGEM", "type": "tuning", "team": "", "color": Color(0.32, 0.18, 0.16)}
		if side_x == -1 and side_z == 1:
			return {"id": "workshop", "title": "OFICINA MECANICA", "type": "workshop", "team": "", "color": Color(0.27, 0.31, 0.27)}
	if cell == Vector2i(1, 0):
		if side_x == 1 and side_z == -1:
			return {"id": "bope", "title": "BATALHAO BOPE", "type": "org", "team": "BOPE", "color": Color(0.10, 0.14, 0.18)}
		if side_x == -1 and side_z == 1:
			return {"id": "civil", "title": "POLICIA CIVIL", "type": "org", "team": "POLICIA CIVIL", "color": Color(0.16, 0.19, 0.32)}
	if cell == Vector2i(0, 1):
		if side_x == 1 and side_z == 1:
			return {"id": "cv", "title": "COMANDO VERMELHO", "type": "org", "team": "COMANDO VERMELHO", "color": Color(0.40, 0.11, 0.12)}
		if side_x == -1 and side_z == -1:
			return {"id": "pc", "title": "PRIMEIRO COMANDO", "type": "org", "team": "PRIMEIRO COMANDO", "color": Color(0.24, 0.26, 0.30)}
	if cell == Vector2i(1, 1):
		if side_x == -1 and side_z == 1:
			return {"id": "samu", "title": "SAMU | HOSPITAL", "type": "hospital", "team": "SAMU", "color": Color(0.77, 0.79, 0.78)}
		if side_x == 1 and side_z == -1:
			return {"id": "market", "title": "MERCADO LEXUS", "type": "market", "team": "", "color": Color(0.23, 0.30, 0.25)}
	return {}

static func hill_height(pos: Vector2) -> float:
	var ax := clampf((absf(pos.x) - 9.0) / 31.0, 0.0, 1.0)
	var az := clampf((absf(pos.y) - 9.0) / 31.0, 0.0, 1.0)
	var ripple := 0.92 + 0.08 * sin(pos.x * 0.23 + pos.y * 0.18)
	return pow(ax, 1.08) * pow(az, 0.78) * 12.0 * ripple

static func add_hill_terrain(holder: Node3D, dirt: Material) -> void:
	# Malha inclinada com colisão trimesh. As avenidas continuam planas.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for ix in range(9):
				for iz in range(9):
					var a := Vector2(sx * (9.0 + ix * 3.4), sz * (9.0 + iz * 3.4))
					var b := Vector2(sx * (9.0 + (ix + 1) * 3.4), sz * (9.0 + iz * 3.4))
					var c := Vector2(sx * (9.0 + ix * 3.4), sz * (9.0 + (iz + 1) * 3.4))
					var d := Vector2(sx * (9.0 + (ix + 1) * 3.4), sz * (9.0 + (iz + 1) * 3.4))
					# Arrays de loops são Variant no GDScript 4.4: conversão explícita
					# impede falha de inferência em exportação headless.
					var is_ccw: bool = float(sx) * float(sz) > 0.0
					if is_ccw:
						_add_terrain_tri(surface, a, c, b)
						_add_terrain_tri(surface, b, c, d)
					else:
						_add_terrain_tri(surface, a, b, c)
						_add_terrain_tri(surface, b, d, c)
			surface.generate_normals()
			var mesh: ArrayMesh = surface.commit()
			if mesh == null:
				continue
			var body := StaticBody3D.new()
			body.name = "Morro_Colisao"
			var visual := MeshInstance3D.new()
			visual.mesh = mesh
			visual.material_override = dirt
			body.add_child(visual)
			var col := CollisionShape3D.new()
			col.shape = mesh.create_trimesh_shape()
			body.add_child(col)
			holder.add_child(body)

static func _add_terrain_tri(surface: SurfaceTool, a: Vector2, b: Vector2, c: Vector2) -> void:
	for p in [a, b, c]:
		surface.set_uv(p * 0.07)
		surface.add_vertex(Vector3(p.x, hill_height(p), p.y))

static func add_favela_house(holder: Node3D, spot: Vector3, serial: int, materials: Dictionary, label_text: String) -> Vector3:
	var height := hill_height(Vector2(spot.x, spot.z))
	var house := Node3D.new()
	house.name = "ResidenciaFavela_%d" % serial
	house.position = Vector3(spot.x, height, spot.z)
	holder.add_child(house)
	var floors := 1 + (serial % 3)
	var wall_height := 3.3 + (floors - 1) * 2.35
	var wall_mat: Material = materials["brick"] if serial % 3 == 0 else materials["plaster"]
	Visuals.box(house, Vector3(0, wall_height * 0.5, 0), Vector3(9.4, wall_height, 9.5), wall_mat, true)
	Visuals.box(house, Vector3(0, wall_height + 0.18, 0), Vector3(10.0, 0.36, 10.0), materials["roof"], true)
	Visuals.box(house, Vector3(0, 1.1, 4.82), Vector3(1.3, 2.2, 0.12), materials["metal"], false)
	for n in range(floors):
		Visuals.box(house, Vector3(-2.65, 1.65 + n * 2.3, 4.82), Vector3(1.15, 1.0, 0.11), materials["glass"])
		Visuals.box(house, Vector3(2.65, 1.65 + n * 2.3, 4.82), Vector3(1.15, 1.0, 0.11), materials["glass"])
	var graffiti := Visuals.label_3d(house, label_text, Vector3(0, minf(2.55, wall_height - 0.3), 4.90), 74)
	graffiti.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	graffiti.modulate = Color(0.84, 0.09, 0.12) if serial % 2 == 0 else Color(0.13, 0.14, 0.17)
	graffiti.outline_modulate = Color(0.88, 0.86, 0.78)
	graffiti.pixel_size = 0.007
	# Rampa física da avenida até a altura do lote; acessível a pé.
	var start_x := signf(spot.x) * 10.2
	var end_x := spot.x
	var delta_x := end_x - start_x
	var ramp_len := sqrt(delta_x * delta_x + height * height)
	var ramp := Visuals.box(holder, Vector3((start_x + end_x) * 0.5, height * 0.5 - 0.13, spot.z + 6.0), Vector3(ramp_len, 0.30, 2.3), materials["pavement"], true)
	ramp.rotation.z = atan2(height, delta_x)
	return Vector3(spot.x, height, spot.z + 5.65)

static func add_smoke(holder: Node3D, pos: Vector3, quality: int) -> void:
	if quality <= 0:
		return
	var particle := CPUParticles3D.new()
	particle.position = pos
	particle.amount = 10
	particle.lifetime = 3.6
	particle.emitting = true
	particle.direction = Vector3(0, 1, 0)
	particle.spread = 18.0
	particle.initial_velocity_min = 0.4
	particle.initial_velocity_max = 1.2
	particle.gravity = Vector3(0, 0.13, 0)
	particle.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particle.emission_sphere_radius = 0.4
	particle.color = Color(0.60, 0.60, 0.61, 0.18)
	var puff := SphereMesh.new()
	puff.radius = 0.4
	puff.height = 0.8
	var smoke_material := StandardMaterial3D.new()
	smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.albedo_color = Color(0.60, 0.61, 0.62, 0.20)
	puff.material = smoke_material
	particle.mesh = puff
	holder.add_child(particle)

static func add_barricades(holder: Node3D, where: Vector3, materials: Dictionary) -> void:
	var hard := materials["concrete"] as Material
	var signal_material := Visuals.material(Color(0.86, 0.17, 0.11))
	for i in range(3):
		var block_pos := where + Vector3(float(i - 1) * 1.7, 0, 0)
		Visuals.box(holder, block_pos + Vector3(0, 0.43, 0), Vector3(1.52, 0.86, 0.65), hard, true)
		Visuals.box(holder, block_pos + Vector3(0, 0.70, 0.335), Vector3(1.2, 0.12, 0.05), signal_material)

static func add_tunnel(holder: Node3D, materials: Dictionary) -> void:
	# Túnel transitável numa via central; pilares, teto e proteção têm colisão.
	var concrete := materials["concrete"] as Material
	var metal := materials["metal"] as Material
	for side in [-1.0, 1.0]:
		Visuals.box(holder, Vector3(side * 7.75, 3.25, -15), Vector3(1.2, 6.5, 22.0), concrete, true)
		for z in [-24.0, -5.0]:
			Visuals.box(holder, Vector3(side * 7.75, 6.8, z), Vector3(1.2, 0.5, 1.0), metal)
	Visuals.box(holder, Vector3(0, 7.1, -15), Vector3(17.0, 0.9, 22.0), concrete, true)
	Visuals.label_3d(holder, "TUNEL LEXUS", Vector3(0, 6.25, -3.85), 44)

static func add_service(holder: Node3D, spot: Vector3, data: Dictionary, materials: Dictionary) -> Vector3:
	var center := Node3D.new()
	center.name = "Servico_%s" % str(data["id"])
	center.position = spot
	holder.add_child(center)
	var style: Material = Visuals.material(data["color"] as Color)
	Visuals.box(center, Vector3(0, 3.6, 0), Vector3(18, 7.2, 14.5), style, true)
	Visuals.box(center, Vector3(0, 7.35, 0), Vector3(19, 0.5, 15.2), materials["roof"], true)
	Visuals.box(center, Vector3(0, 1.4, 7.30), Vector3(2.2, 2.8, 0.16), materials["metal"])
	for x in [-5.5, 5.5]:
		Visuals.box(center, Vector3(x, 3.7, 7.35), Vector3(3.7, 1.8, 0.12), materials["glass"])
	var front_label := Visuals.label_3d(center, str(data["title"]), Vector3(0, 6.0, 7.47), 50)
	front_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	front_label.pixel_size = 0.007
	front_label.modulate = Color(0.93, 0.93, 0.93)
	if str(data["type"]) == "org":
		add_barricades(holder, spot + Vector3(0, 0, 11.6), materials)
	if str(data["type"]) == "hospital":
		var red := Visuals.material(Color(0.85, 0.10, 0.16))
		Visuals.box(center, Vector3(0, 4.2, 7.46), Vector3(0.28, 1.5, 0.07), red)
		Visuals.box(center, Vector3(0, 4.2, 7.47), Vector3(1.5, 0.28, 0.07), red)
	return spot + Vector3(0, 0, 8.3)
