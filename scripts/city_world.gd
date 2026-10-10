extends Node3D

# A streamed procedural city. The grid extends indefinitely in X/Z, but ONLY
# the nearby cells are instantiated. It is not an authored infinite map.
const Visuals = preload("res://scripts/visuals.gd")
const Districts = preload("res://scripts/lexus_districts.gd")
const Geo = preload("res://scripts/lexus_geography.gd")
const Water = preload("res://scripts/lexus_water.gd")
const T = "res://assets/textures/"
const CELL_SIZE = 80.0

var asphalt: StandardMaterial3D
var pavement: StandardMaterial3D
var plaster: StandardMaterial3D
var brick: StandardMaterial3D
var roof: StandardMaterial3D
var grass: StandardMaterial3D
var glass: StandardMaterial3D
var concrete: StandardMaterial3D
var yellow: StandardMaterial3D
var white: StandardMaterial3D
var metal: StandardMaterial3D
var foliage: StandardMaterial3D
var water_material: ShaderMaterial
var mud: StandardMaterial3D
var rain_fx: CPUParticles3D
var weather_type: int = 0 # 0 limpo, 1 nublado, 2 chuva
var day_light: DirectionalLight3D
var global_env: WorldEnvironment
var quality: int = 1
var loaded_chunks: Dictionary = {}
var pending_chunks: Array[Vector2i] = []
var interactables: Dictionary = {}
var discovered_favelas: Dictionary = {}
var current_cell := Vector2i(2147483647, 2147483647)
var center_point := Vector3.ZERO
var time_of_day := 12.0

func _ready() -> void:
	_make_materials()
	_make_atmosphere()
	# Spawn chunk first, to guarantee a physical floor before enabling the player.
	_build_chunk(Vector2i.ZERO)
	update_visibility(Vector3.ZERO)

func _process(_delta: float) -> void:
	# Instantiating 1 cell per frame avoids a large freeze on Android.
	if not pending_chunks.is_empty():
		var next_cell: Vector2i = pending_chunks.pop_front()
		if not loaded_chunks.has(next_cell) and _inside_stream_radius(next_cell):
			_build_chunk(next_cell)

func _make_materials() -> void:
	asphalt = Visuals.material(Color.WHITE, T + "asphalt.png", 4.0)
	pavement = Visuals.material(Color.WHITE, T + "sidewalk.png", 2.0)
	plaster = Visuals.material(Color.WHITE, T + "plaster.png", 2.0)
	brick = Visuals.material(Color.WHITE, T + "brick.png", 2.0)
	roof = Visuals.material(Color.WHITE, T + "roof.png", 2.0)
	grass = Visuals.material(Color.WHITE, T + "grass.png", 4.0)
	glass = Visuals.material(Color(0.61, 0.82, 0.93), T + "glass.png", 1.0, 0.1)
	concrete = Visuals.material(Color.WHITE, T + "concrete.png", 2.0)
	yellow = Visuals.material(Color(0.97, 0.81, 0.32))
	white = Visuals.material(Color(0.92, 0.92, 0.90))
	metal = Visuals.material(Color(0.29, 0.31, 0.35), "", 1.0, 0.5)
	foliage = Visuals.material(Color(0.20, 0.47, 0.22))
	mud = Visuals.material(Color(0.35, 0.28, 0.20), T + "grass.png", 5.0)
	water_material = Water.create_water_material()

func _make_atmosphere() -> void:
	global_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.57, 0.75, 0.93)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.92, 1.0)
	env.ambient_light_energy = 0.72
	env.fog_enabled = true
	env.fog_light_color = Color(0.67, 0.76, 0.9)
	env.fog_density = 0.0015
	global_env.environment = env
	add_child(global_env)
	day_light = DirectionalLight3D.new()
	day_light.rotation_degrees = Vector3(-52, -18, 0)
	day_light.light_energy = 1.35
	day_light.shadow_enabled = true
	day_light.directional_shadow_max_distance = 55.0
	add_child(day_light)
	_make_rain()
	set_time(time_of_day)

func _make_rain() -> void:
	rain_fx = CPUParticles3D.new()
	rain_fx.name = "ChuvaLocal"
	rain_fx.amount = 86
	rain_fx.lifetime = 0.8
	rain_fx.emitting = false
	rain_fx.direction = Vector3(0.0, -1.0, 0.0)
	rain_fx.spread = 8.0
	rain_fx.initial_velocity_min = 6.0
	rain_fx.initial_velocity_max = 10.0
	rain_fx.gravity = Vector3(0.0, -20.0, 0.0)
	rain_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain_fx.emission_box_extents = Vector3(13.0, 1.5, 13.0)
	var drop := QuadMesh.new()
	drop.size = Vector2(0.026, 0.35)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.65, 0.77, 0.92, 0.35)
	drop.material = mat
	rain_fx.mesh = drop
	add_child(rain_fx)

func _build_chunk(cell: Vector2i) -> void:
	if loaded_chunks.has(cell):
		return
	var holder := Node3D.new()
	holder.name = "Quadra_%d_%d" % [cell.x, cell.y]
	holder.position = Vector3(cell.x * CELL_SIZE, 0, cell.y * CELL_SIZE)
	add_child(holder)
	loaded_chunks[cell] = holder
	if Geo.is_river_cell(cell):
		_build_river_cell(holder, cell)
		return
	Visuals.box(holder, Vector3(0, -0.5, 0), Vector3(CELL_SIZE + 0.5, 1.0, CELL_SIZE + 0.5), grass, true)
	# Two avenues on the chunk axes. Same layout at each boundary.
	Visuals.box(holder, Vector3(0, 0.027, 0), Vector3(13.5, 0.06, CELL_SIZE), asphalt)
	Visuals.box(holder, Vector3(0, 0.029, 0), Vector3(CELL_SIZE, 0.06, 13.5), asphalt)
	for side in [-1.0, 1.0]:
		Visuals.box(holder, Vector3(side * 8.15, 0.12, 0), Vector3(2.7, 0.22, CELL_SIZE), pavement)
		Visuals.box(holder, Vector3(0, 0.12, side * 8.15), Vector3(CELL_SIZE, 0.22, 2.7), pavement)
	for n in range(-4, 5):
		Visuals.box(holder, Vector3(0, 0.068, n * 9.0), Vector3(0.22, 0.012, 2.8), yellow)
		Visuals.box(holder, Vector3(n * 9.0, 0.069, 0), Vector3(2.8, 0.012, 0.22), yellow)

	if Geo.is_tunnel_cell(cell):
		_build_tunnel_section(holder, cell)
		return
	# Land: a softly undulating mesh between level, driveable roads.
	_build_rolling_land(holder, cell)
	if cell.y == 3 or cell.y == 6:
		_build_riverbank(holder, cell)
	if Geo.is_bridge_approach(cell):
		_build_bridge_approach(holder, cell)
	var favela := Districts.is_favela(cell)
	var mats := _district_materials()
	if favela:
		Districts.add_hill_terrain(holder, grass)
		if quality > 0 and abs(cell.x + cell.y) % 2 == 0:
			Districts.add_smoke(holder, Vector3(30, 7, 30), quality)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var serial := absi(cell.x * 103 + cell.y * 71 + sx * 17 + sz * 23)
			var spot := Vector3(sx * 24.0, 0, sz * 23.0)
			if not favela:
				spot.y = Geo.rolling_height(cell, Vector2(spot.x, spot.z))
			var service: Dictionary = Districts.service_for(cell, sx, sz)
			if not service.is_empty():
				var entrance := Districts.add_service(holder, spot, service, mats)
				_register_interaction(cell, holder, str(service["id"]), str(service["type"]), str(service["title"]), entrance, str(service.get("team", "")))
			elif favela:
				var wall_name := "COMANDO VERMELHO" if serial % 2 == 0 else "PRIMEIRO COMANDO"
				var entrance := Districts.add_favela_house(holder, spot, serial, mats, wall_name)
				_register_interaction(cell, holder, "casa_%d_%d_%d_%d" % [cell.x, cell.y, sx, sz], "house", "CASA NO MORRO", entrance)
			else:
				_build_house(holder, spot, serial, cell)
				_register_interaction(cell, holder, "casa_%d_%d_%d_%d" % [cell.x, cell.y, sx, sz], "house", "CASA RESIDENCIAL", spot + Vector3(0, 0, 6.3))
			if serial % 3 == 0 and not favela:
				var tx := float(sx * 33)
				var tz := float(sz * 34)
				_build_tree(holder, Vector3(tx, Geo.rolling_height(cell, Vector2(tx, tz)), tz))
	if (cell.x + cell.y) % 2 == 0:
		_build_lamp(holder, Vector3(10, 0, 11))
	if (absi(cell.x * 13 + cell.y * 7) % 3) == 0 and not Geo.is_bridge_approach(cell):
		_build_speed_bump(holder, cell)
	if favela:
		Districts.add_barricades(holder, Vector3(4.5, 0, -28.0), mats)
		Visuals.label_3d(holder, "MORRO DO LEXUS | COMUNIDADE", Vector3(0, 4, -37), 47)
	elif cell == Vector2i(0, -2) or cell == Vector2i(2, 0):
		Districts.add_tunnel(holder, mats)

	# Tutorial activity points only in their authored cells.
	if cell == Vector2i.ZERO:
		Visuals.label_3d(holder, "DUQUE DE CAXIAS  •  CENTRO", Vector3(0, 6.0, -30), 44)
		Visuals.label_3d(holder, "GARAGEM • USAR", Vector3(15, 3.0, 11), 38)
		Visuals.label_3d(holder, "CENTRAL DE ENTREGAS", Vector3(12, 3.0, -16), 40)
		Visuals.box(holder, Vector3(9, 0.58, -15), Vector3(2.3, 1.15, 1.8), brick)
	if cell == Vector2i(0, 7):
		Visuals.label_3d(holder, "CIDADE DE DEUS  •  NOVA REGIAO", Vector3(0, 6.0, -27), 43)
	if cell == Vector2i(10, 7):
		Visuals.label_3d(holder, "ZONA NORTE  •  NOVA CIDADE", Vector3(0, 6.0, -27), 44)
	if cell == Vector2i(2, 1):
		Visuals.label_3d(holder, "DESTINO ENTREGA", Vector3(-40, 3.0, -20), 38)
		Visuals.box(holder, Vector3(-40, 0.15, -20), Vector3(5, 0.25, 5), yellow)

func _build_house(parent: Node3D, local_position: Vector3, serial: int, cell: Vector2i) -> void:
	var house := Node3D.new()
	house.position = local_position
	parent.add_child(house)
	var city_name := Geo.city_name(Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE))
	var floors := 1 + serial % 3
	if city_name == "DUQUE DE CAXIAS":
		floors = 2 + serial % 3
	elif city_name == "CIDADE DE DEUS":
		floors = 1 + serial % 2
	elif city_name == "ZONA NORTE":
		floors = 3 + serial % 3
	var height := 3.0 + floors * 2.0
	var width := 10.0 + float(serial % 2)
	var wall: Material = brick if serial % 4 == 0 else plaster
	Visuals.box(house, Vector3(0, height * 0.5, 0), Vector3(width, height, 10.5), wall, true)
	Visuals.box(house, Vector3(0, height + 0.2, 0), Vector3(width + 0.7, 0.4, 11), roof)
	Visuals.box(house, Vector3(0, 1.24, 5.31), Vector3(1.6, 2.4, 0.11), metal)
	for floor_index in range(floors):
		for sx in [-2.7, 2.7]:
			Visuals.box(house, Vector3(sx, 2.15 + floor_index * 1.95, 5.32), Vector3(1.7, 1.2, 0.11), glass)
			Visuals.box(house, Vector3(sx, 2.15 + floor_index * 1.95, -5.32), Vector3(1.7, 1.2, 0.11), glass)
			if floor_index > 0 and serial % 3 == 0:
				Visuals.box(house, Vector3(sx, 1.35 + floor_index * 1.95, 5.82), Vector3(2.4, 0.19, 1.40), concrete)
				Visuals.box(house, Vector3(sx, 1.84 + floor_index * 1.95, 6.45), Vector3(2.4, 0.68, 0.11), metal)

func _build_tree(parent: Node3D, local_position: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = local_position
	parent.add_child(tree)
	Visuals.cylinder(tree, Vector3(0, 1.8, 0), 0.24, 3.6, metal)
	Visuals.sphere(tree, Vector3(0, 4.4, 0), Vector3(3, 2.5, 3), foliage)

func _build_lamp(parent: Node3D, local_position: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.position = local_position
	parent.add_child(lamp)
	Visuals.cylinder(lamp, Vector3(0, 3, 0), 0.09, 6.0, metal)
	Visuals.box(lamp, Vector3(0.7, 5.85, 0), Vector3(1.5, 0.14, 0.14), metal)
	Visuals.box(lamp, Vector3(1.4, 5.7, 0), Vector3(0.45, 0.21, 0.40), yellow)
	if quality > 0:
		var glow := OmniLight3D.new()
		glow.position = Vector3(1.4, 5.5, 0)
		glow.light_color = Color(1.0, 0.83, 0.56)
		glow.light_energy = 0.85
		glow.omni_range = 15.0
		glow.shadow_enabled = false
		glow.add_to_group("lexus_street_lamps")
		glow.visible = time_of_day < 6.0 or time_of_day >= 18.0
		lamp.add_child(glow)

func _inside_stream_radius(cell: Vector2i) -> bool:
	var radius := 1 if quality < 2 else 2
	return absi(cell.x - current_cell.x) <= radius and absi(cell.y - current_cell.y) <= radius

func update_visibility(focus_position: Vector3) -> void:
	center_point = focus_position
	if rain_fx != null:
		rain_fx.global_position = focus_position + Vector3(0.0, 13.0, 0.0)
	var next_cell := Vector2i(roundi(focus_position.x / CELL_SIZE), roundi(focus_position.z / CELL_SIZE))
	if next_cell == current_cell:
		return
	current_cell = next_cell
	var radius := 1 if quality < 2 else 2
	pending_chunks.clear()
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var coord := current_cell + Vector2i(x, y)
			if not loaded_chunks.has(coord):
				pending_chunks.append(coord)
	# Unload distant chunks, preserving live vehicles/NPCs (owned by game_root).
	var to_remove: Array = []
	for key in loaded_chunks.keys():
		var coord: Vector2i = key
		if absi(coord.x - current_cell.x) > radius + 1 or absi(coord.y - current_cell.y) > radius + 1:
			to_remove.append(coord)
	for key in to_remove:
		var old: Node3D = loaded_chunks[key]
		loaded_chunks.erase(key)
		for item_id in interactables.keys():
			if interactables[item_id]["cell"] == key:
				interactables.erase(item_id)
		old.queue_free()

func set_quality(level: int) -> void:
	quality = clampi(level, 0, 2)
	day_light.shadow_enabled = quality > 0
	day_light.directional_shadow_max_distance = 55.0 if quality == 1 else 95.0
	set_weather(weather_type)
	# Reevaluate stream radius if graphics quality changed.
	current_cell = Vector2i(2147483647, 2147483647)
	update_visibility(center_point)


func _build_river_cell(holder: Node3D, cell: Vector2i) -> void:
	# No ordinary roads/houses over water. The riverbed has collision; bridge is driveable.
	Visuals.box(holder, Vector3(0, -5.3, 0), Vector3(80.5, 0.6, 80.5), mud, true)
	var surface := MeshInstance3D.new()
	surface.name = "AguaComOndas"
	var plane := PlaneMesh.new()
	plane.size = Vector2(80.5, 80.5)
	plane.subdivide_width = 10
	plane.subdivide_depth = 10
	surface.mesh = plane
	surface.material_override = water_material
	surface.position.y = -0.42
	holder.add_child(surface)
	if Geo.is_bridge_cell(cell):
		_build_bridge_deck(holder, cell)

func _build_bridge_deck(holder: Node3D, cell: Vector2i) -> void:
	var deck := Visuals.box(holder, Vector3(0.0, 1.34, 0.0), Vector3(15.6, 0.44, 80.0), asphalt, true)
	deck.name = "PonteColisao"
	for side in [-1.0, 1.0]:
		Visuals.box(holder, Vector3(side * 8.1, 1.88, 0), Vector3(0.42, 0.70, 80.0), concrete, true)
		Visuals.box(holder, Vector3(side * 8.1, 2.35, 0), Vector3(0.48, 0.16, 80.0), metal)
		for z in [-28.0, 0.0, 28.0]:
			Visuals.box(holder, Vector3(side * 7.55, -1.8, z), Vector3(1.4, 6.1, 1.4), concrete, true)
	for z in range(-3, 4):
		Visuals.box(holder, Vector3(0, 1.57, float(z) * 11.0), Vector3(0.18, 0.025, 4.1), yellow)
	if cell.y == 4:
		Visuals.label_3d(holder, "PONTE LEXUS | ACESSO CIDADE DE DEUS", Vector3(0, 4.8, -33), 38)

func _build_riverbank(holder: Node3D, cell: Vector2i) -> void:
	var edge_z := 39.55 if cell.y == 3 else -39.55
	Visuals.box(holder, Vector3(0, -1.38, edge_z), Vector3(79.8, 2.55, 0.72), concrete, true)
	if cell.x == 0:
		var sign_pos := -27.0 if cell.y == 3 else 27.0
		Visuals.label_3d(holder, "CIDADE DE DEUS  |  PONTE" if cell.y == 3 else "DUQUE DE CAXIAS  |  PONTE", Vector3(0, 5.0, sign_pos), 43)

func _build_bridge_approach(holder: Node3D, cell: Vector2i) -> void:
	var z0 := 10.0 if cell.y == 3 else -40.0
	var z1 := 40.0 if cell.y == 3 else -10.0
	var y0 := 0.065 if cell.y == 3 else 1.56
	var y1 := 1.56 if cell.y == 3 else 0.065
	var ramp_surface := SurfaceTool.new()
	ramp_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-7.75, y0, z0)
	var b := Vector3(7.75, y0, z0)
	var c := Vector3(-7.75, y1, z1)
	var d := Vector3(7.75, y1, z1)
	for v in [a, c, b, b, c, d]:
		ramp_surface.set_uv(Vector2(v.x * 0.10, v.z * 0.10))
		ramp_surface.add_vertex(v)
	ramp_surface.generate_normals()
	var ramp_mesh: ArrayMesh = ramp_surface.commit()
	var bridge_ramp := StaticBody3D.new()
	bridge_ramp.name = "RampaPonte"
	var visual := MeshInstance3D.new()
	visual.mesh = ramp_mesh
	visual.material_override = asphalt
	bridge_ramp.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = ramp_mesh.create_trimesh_shape()
	bridge_ramp.add_child(collision)
	holder.add_child(bridge_ramp)

func _build_rolling_land(holder: Node3D, cell: Vector2i) -> void:
	# Terrain within city blocks: 4 modest meshes per chunk, roads remain level.
	if Districts.is_favela(cell):
		return # Existing favela terrain already has steep hills and collision.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			var edge := 11.0
			var step := 5.75
			for ix in range(5):
				for iz in range(5):
					var ax := sx * (edge + ix * step)
					var bx := sx * (edge + (ix + 1) * step)
					var az := sz * (edge + iz * step)
					var bz := sz * (edge + (iz + 1) * step)
					var a := Vector3(ax, Geo.rolling_height(cell, Vector2(ax, az)), az)
					var b := Vector3(bx, Geo.rolling_height(cell, Vector2(bx, az)), az)
					var c := Vector3(ax, Geo.rolling_height(cell, Vector2(ax, bz)), bz)
					var d := Vector3(bx, Geo.rolling_height(cell, Vector2(bx, bz)), bz)
					var vertices: Array = [a, c, b, b, c, d] if sx * sz > 0 else [a, b, c, b, d, c]
					for pt in vertices:
						tool.set_uv(Vector2(pt.x * 0.08, pt.z * 0.08))
						tool.add_vertex(pt)
			tool.generate_normals()
			var mesh: ArrayMesh = tool.commit()
			var body := StaticBody3D.new()
			body.name = "TerrenoOndulado"
			var model := MeshInstance3D.new()
			model.mesh = mesh
			model.material_override = grass
			body.add_child(model)
			var col := CollisionShape3D.new()
			col.shape = mesh.create_trimesh_shape()
			body.add_child(col)
			holder.add_child(body)

func _build_speed_bump(holder: Node3D, cell: Vector2i) -> void:
	# Low-profile triangular road hump with sloped triangle collision (not a blocking box).
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for offset in range(2):
		var za := -17.4 + float(offset) * 1.5
		var zb := za + 1.5
		var ya := 0.06 if offset == 0 else 0.19
		var yb := 0.19 if offset == 0 else 0.06
		var a := Vector3(-6.3, ya, za)
		var b := Vector3(6.3, ya, za)
		var c := Vector3(-6.3, yb, zb)
		var d := Vector3(6.3, yb, zb)
		for pt in [a, c, b, b, c, d]:
			surface.set_uv(Vector2(pt.x * 0.3, pt.z * 0.3))
			surface.add_vertex(pt)
	surface.generate_normals()
	var bump: ArrayMesh = surface.commit()
	var body := StaticBody3D.new()
	body.name = "QuebraMolas_%d_%d" % [cell.x, cell.y]
	var model := MeshInstance3D.new()
	model.mesh = bump
	model.material_override = yellow
	body.add_child(model)
	var shape := CollisionShape3D.new()
	shape.shape = bump.create_trimesh_shape()
	body.add_child(shape)
	holder.add_child(body)

func _build_tunnel_section(holder: Node3D, cell: Vector2i) -> void:
	# Continuous east-west paved tunnel, on the route to Zona Norte.
	for side in [-1.0, 1.0]:
		Visuals.box(holder, Vector3(0, 4.3, side * 9.75), Vector3(80.0, 8.6, 1.25), concrete, true)
		Visuals.box(holder, Vector3(0, 7.9, side * 13.5), Vector3(80, 16.0, 6.7), mud, true)
		for x in [-25.0, 0.0, 25.0]:
			Visuals.box(holder, Vector3(x, 7.0, side * 8.85), Vector3(1.1, 0.18, 0.15), yellow)
	if quality > 0:
		for x in [-18.0, 18.0]:
			var tunnel_light := OmniLight3D.new()
			tunnel_light.position = Vector3(x, 7.1, 0.0)
			tunnel_light.light_color = Color(1.0, 0.86, 0.63)
			tunnel_light.light_energy = 0.9
			tunnel_light.omni_range = 24.0
			tunnel_light.shadow_enabled = false
			holder.add_child(tunnel_light)
	Visuals.box(holder, Vector3(0, 9.0, 0), Vector3(80.0, 1.2, 21.0), concrete, true)
	if cell.x == 7:
		Visuals.label_3d(holder, "TÚNEL DA ZONA NORTE", Vector3(-35, 6.8, -0.1), 45)
	if cell.x == 9:
		Visuals.label_3d(holder, "ZONA NORTE  •  BEM-VINDO", Vector3(30, 6.8, 0), 40)
	for i in range(-3, 4):
		Visuals.box(holder, Vector3(float(i) * 11, 0.074, 0.0), Vector3(4.0, 0.02, 0.2), yellow)

func set_time(hour: float) -> void:
	time_of_day = fposmod(hour, 24.0)
	var daylight := clampf(sin((time_of_day - 6.0) / 12.0 * PI), 0.0, 1.0)
	var night := daylight <= 0.055
	var env := global_env.environment
	day_light.light_energy = 0.07 + daylight * (1.40 if weather_type == 0 else 0.80)
	if water_material != null:
		water_material.set_shader_parameter("illumination", daylight)
	day_light.rotation_degrees = Vector3(-12.0 - daylight * 55.0, -18.0 + time_of_day * 4.0, 0.0)
	day_light.shadow_enabled = quality > 0 and not night
	var sun_color := Color(0.61, 0.79, 0.97)
	var night_color := Color(0.018, 0.029, 0.07)
	var overcast_color := Color(0.36, 0.42, 0.48)
	var sky := night_color.lerp(sun_color, daylight)
	if weather_type > 0:
		sky = sky.lerp(overcast_color, 0.32 if weather_type == 1 else 0.60)
	env.background_color = sky
	env.ambient_light_color = Color(0.50, 0.61, 0.82).lerp(Color(0.94, 0.96, 1.0), daylight)
	env.ambient_light_energy = lerpf(0.14, 0.78, daylight) * (1.0 if weather_type == 0 else 0.77)
	env.fog_light_color = sky.lerp(Color(0.56, 0.63, 0.69), 0.50)
	env.fog_density = (0.0011 if quality == 2 else 0.0019) + (0.0032 if weather_type == 2 else (0.0013 if weather_type == 1 else 0.0))
	for lamp in get_tree().get_nodes_in_group("lexus_street_lamps"):
		if is_instance_valid(lamp):
			lamp.visible = night and quality > 0

func set_weather(mode: int) -> void:
	weather_type = clampi(mode, 0, 2)
	if water_material != null:
		water_material.set_shader_parameter("wave_strength", 0.16 if weather_type == 2 else 0.095)
	if rain_fx != null:
		rain_fx.emitting = weather_type == 2 and quality > 0
	set_time(time_of_day)

func weather_label() -> String:
	match weather_type:
		1:
			return "NUBLADO"
		2:
			return "CHUVA"
	return "LIMPO"

func ensure_chunk_at(position_world: Vector3) -> void:
	var cell := Vector2i(roundi(position_world.x / CELL_SIZE), roundi(position_world.z / CELL_SIZE))
	if not loaded_chunks.has(cell):
		_build_chunk(cell)
	update_visibility(position_world)

func _district_materials() -> Dictionary:
	return {
		"asphalt": asphalt, "pavement": pavement, "plaster": plaster,
		"brick": brick, "roof": roof, "grass": grass,
		"glass": glass, "concrete": concrete, "yellow": yellow, "metal": metal
	}

func _register_interaction(cell: Vector2i, holder: Node3D, item_id: String, item_type: String, title: String, local_position: Vector3, team: String = "") -> void:
	interactables[item_id] = {
		"id": item_id, "type": item_type, "title": title, "team": team,
		"position": holder.position + local_position,
		"cell": cell
	}

func nearest_interactable(position_world: Vector3, radius: float = 6.2) -> Dictionary:
	var nearest: Dictionary = {}
	var max_d := radius
	for key in interactables.keys():
		var item: Dictionary = interactables[key]
		var p: Vector3 = item["position"]
		var distance := position_world.distance_to(p)
		if distance <= max_d:
			max_d = distance
			nearest = item
	return nearest

func all_map_points() -> Array:
	var result: Array = Geo.landmark_points()
	for key in interactables.keys():
		var item: Dictionary = interactables[key]
		if item["type"] != "house":
			result.append(item)
	return result

func district_name(position_world: Vector3) -> String:
	var place := Geo.district_label(position_world)
	if place != Geo.city_name(position_world):
		return place
	var cell := Vector2i(roundi(position_world.x / CELL_SIZE), roundi(position_world.z / CELL_SIZE))
	if Districts.is_favela(cell):
		return "%s • MORRO DA COMUNIDADE" % place
	if cell == Vector2i(1, 0):
		return "%s • BASES POLICIAIS" % place
	if cell == Vector2i(0, 1):
		return "%s • SETOR DAS ORGANIZACOES" % place
	if cell == Vector2i(1, 1):
		return "%s • DISTRITO HOSPITALAR" % place
	return "%s • AVENIDAS" % place
