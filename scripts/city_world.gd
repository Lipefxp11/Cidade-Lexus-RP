extends Node3D

# A streamed procedural city. The grid extends indefinitely in X/Z, but ONLY
# the nearby cells are instantiated. It is not an authored infinite map.
const Visuals = preload("res://scripts/visuals.gd")
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
var day_light: DirectionalLight3D
var global_env: WorldEnvironment
var quality: int = 1
var loaded_chunks: Dictionary = {}
var pending_chunks: Array[Vector2i] = []
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

func _build_chunk(cell: Vector2i) -> void:
	if loaded_chunks.has(cell):
		return
	var holder := Node3D.new()
	holder.name = "Quadra_%d_%d" % [cell.x, cell.y]
	holder.position = Vector3(cell.x * CELL_SIZE, 0, cell.y * CELL_SIZE)
	add_child(holder)
	loaded_chunks[cell] = holder
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

	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var serial := absi(cell.x * 103 + cell.y * 71 + sx * 17 + sz * 23)
			_build_house(holder, Vector3(sx * 24.0, 0, sz * 23.0), serial)
			if serial % 3 == 0:
				_build_tree(holder, Vector3(sx * 33, 0, sz * 34))
	if (cell.x + cell.y) % 2 == 0:
		_build_lamp(holder, Vector3(10, 0, 11))

	# Tutorial activity points only in their authored cells.
	if cell == Vector2i.ZERO:
		Visuals.label_3d(holder, "GARAGEM • USAR", Vector3(15, 3.0, 11), 38)
		Visuals.label_3d(holder, "CENTRAL DE ENTREGAS", Vector3(12, 3.0, -16), 40)
		Visuals.box(holder, Vector3(9, 0.58, -15), Vector3(2.3, 1.15, 1.8), brick)
	if cell == Vector2i(2, 1):
		Visuals.label_3d(holder, "DESTINO ENTREGA", Vector3(-40, 3.0, -20), 38)
		Visuals.box(holder, Vector3(-40, 0.15, -20), Vector3(5, 0.25, 5), yellow)

func _build_house(parent: Node3D, local_position: Vector3, serial: int) -> void:
	var house := Node3D.new()
	house.position = local_position
	parent.add_child(house)
	var floors := 1 + serial % 3
	var height := 3.9 + floors * 2.0
	var width := 10.0 + float(serial % 2)
	var wall: Material = brick if serial % 4 == 0 else plaster
	Visuals.box(house, Vector3(0, height * 0.5, 0), Vector3(width, height, 10.5), wall, true)
	Visuals.box(house, Vector3(0, height + 0.2, 0), Vector3(width + 0.7, 0.4, 11), roof)
	Visuals.box(house, Vector3(0, 1.24, 5.31), Vector3(1.6, 2.4, 0.11), metal)
	for floor_index in range(floors):
		for sx in [-2.7, 2.7]:
			Visuals.box(house, Vector3(sx, 2.15 + floor_index * 1.95, 5.32), Vector3(1.7, 1.2, 0.11), glass)
			Visuals.box(house, Vector3(sx, 2.15 + floor_index * 1.95, -5.32), Vector3(1.7, 1.2, 0.11), glass)

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

func _inside_stream_radius(cell: Vector2i) -> bool:
	var radius := 1 if quality < 2 else 2
	return absi(cell.x - current_cell.x) <= radius and absi(cell.y - current_cell.y) <= radius

func update_visibility(focus_position: Vector3) -> void:
	center_point = focus_position
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
		old.queue_free()

func set_quality(level: int) -> void:
	quality = clampi(level, 0, 2)
	day_light.shadow_enabled = quality > 0
	day_light.directional_shadow_max_distance = 55.0 if quality == 1 else 95.0
	global_env.environment.fog_density = 0.0023 if quality == 0 else 0.0015
	# Reevaluate stream radius if graphics quality changed.
	current_cell = Vector2i(2147483647, 2147483647)
	update_visibility(center_point)

func set_time(hour: float) -> void:
	time_of_day = fposmod(hour, 24.0)
	var daylight := clampf(sin((time_of_day - 6.0) / 12.0 * PI), 0.10, 1.0)
	day_light.light_energy = lerpf(0.12, 1.45, daylight)
	global_env.environment.ambient_light_energy = lerpf(0.30, 0.75, daylight)

func ensure_chunk_at(position_world: Vector3) -> void:
	var cell := Vector2i(roundi(position_world.x / CELL_SIZE), roundi(position_world.z / CELL_SIZE))
	if not loaded_chunks.has(cell):
		_build_chunk(cell)
	update_visibility(position_world)
