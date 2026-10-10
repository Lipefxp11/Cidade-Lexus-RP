extends Node3D

const Visuals = preload("res://scripts/visuals.gd")
const T = "res://assets/textures/"
const ROAD_AXIS = [-120.0, -60.0, 0.0, 60.0, 120.0]
const WORLD_HALF = 190.0
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
var trees_root: Node3D
var quality: int = 1
var buildings: Array = []

func _ready() -> void:
	_make_materials()
	_create_city()

func _make_materials() -> void:
	asphalt = Visuals.material(Color.WHITE, T + "asphalt.png", 9.0)
	pavement = Visuals.material(Color.WHITE, T + "sidewalk.png", 5.0)
	plaster = Visuals.material(Color.WHITE, T + "plaster.png", 3.0)
	brick = Visuals.material(Color.WHITE, T + "brick.png", 2.0)
	roof = Visuals.material(Color.WHITE, T + "roof.png", 2.0)
	grass = Visuals.material(Color.WHITE, T + "grass.png", 18.0)
	glass = Visuals.material(Color(0.65, 0.80, 0.92), T + "glass.png", 1.0, 0.15)
	concrete = Visuals.material(Color.WHITE, T + "concrete.png", 3.0)
	yellow = Visuals.material(Color(1.0, 0.83, 0.34))
	white = Visuals.material(Color(0.87, 0.88, 0.84))
	metal = Visuals.material(Color(0.27, 0.29, 0.32), "", 1.0, 0.45)
	foliage = Visuals.material(Color(0.18, 0.45, 0.22))

func _create_city() -> void:
	global_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.57, 0.75, 0.93)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.92, 1.00)
	env.ambient_light_energy = 0.70
	env.fog_enabled = true
	env.fog_light_color = Color(0.67, 0.76, 0.90)
	env.fog_density = 0.002
	global_env.environment = env
	add_child(global_env)

	day_light = DirectionalLight3D.new()
	day_light.rotation_degrees = Vector3(-52, -18, 0)
	day_light.light_energy = 1.45
	day_light.shadow_enabled = true
	day_light.directional_shadow_max_distance = 75.0
	add_child(day_light)

	# One collision plane for the entire playable neighborhood.
	Visuals.box(self, Vector3(0, -0.5, 0), Vector3(380, 1.0, 380), grass, true)

	# Five north/south avenues and five east/west avenues.
	for axis in ROAD_AXIS:
		Visuals.box(self, Vector3(axis, 0.025, 0), Vector3(13.0, 0.07, 365), asphalt)
		Visuals.box(self, Vector3(0, 0.028, axis), Vector3(365, 0.07, 13.0), asphalt)
		for side in [-1.0, 1.0]:
			Visuals.box(self, Vector3(axis + 8.1 * side, 0.14, 0), Vector3(3.0, 0.25, 365), pavement)
			Visuals.box(self, Vector3(0, 0.14, axis + 8.1 * side), Vector3(365, 0.25, 3.0), pavement)
		for n in range(-16, 17):
			Visuals.box(self, Vector3(axis, 0.070, n * 10.2), Vector3(0.23, 0.01, 3.5), yellow)
			Visuals.box(self, Vector3(n * 10.2, 0.070, axis), Vector3(3.5, 0.01, 0.23), yellow)

	# 6x6 lots. Houses are collidable; props are decorative and cheap.
	for ix in range(6):
		for iz in range(6):
			var x := -150.0 + 60.0 * ix
			var z := -150.0 + 60.0 * iz
			for k in range(3):
				var dx := float(k - 1) * 14.0
				_build_house(Vector3(x + dx, 0, z), ix * 19 + iz * 7 + k)

	# Central social space and garage.
	Visuals.box(self, Vector3(17, 0.045, 17), Vector3(16, 0.05, 16), concrete)
	Visuals.label_3d(self, "GARAGEM • ENTRAR NO CARRO", Vector3(15, 3.0, 11), 45)
	Visuals.label_3d(self, "CENTRAL DE ENTREGAS", Vector3(12, 3.0, -16), 48)
	Visuals.box(self, Vector3(9, 0.55, -15), Vector3(2.3, 1.1, 1.8), brick)
	Visuals.label_3d(self, "ENTREGA • TOQUE EM USAR", Vector3(120, 3.0, 60), 42)
	Visuals.box(self, Vector3(120, 0.18, 60), Vector3(5.0, 0.25, 5.0), yellow)

	trees_root = Node3D.new()
	add_child(trees_root)
	for ix in range(-3, 4):
		for iz in range(-3, 4):
			var tx := float(ix) * 47.5 + 23.0
			var tz := float(iz) * 47.5 + 22.0
			if abs(tx) > 170.0 or abs(tz) > 170.0:
				continue
			_build_tree(Vector3(tx, 0, tz))
			if (ix + iz) % 2 == 0:
				_build_lamp(Vector3(tx + 5.5, 0, tz + 7.5))

	# Crosswalks near the central avenue.
	for z in [-60.0, 0.0, 60.0]:
		for stripe in range(6):
			Visuals.box(self, Vector3(-5.8 + stripe * 2.1, 0.077, z + 13.5), Vector3(1.0, 0.01, 2.6), white)

func _build_house(p: Vector3, house_id: int) -> void:
	var house := Node3D.new()
	house.position = p
	add_child(house)
	buildings.append(house)
	var h := 4.8 + float(house_id % 3) * 2.5
	var w := 10.0 + float(house_id % 2)
	var d := 11.0
	var is_brick := house_id % 4 == 0
	var wall: Material = brick if is_brick else plaster
	Visuals.box(house, Vector3(0, h * 0.5, 0), Vector3(w, h, d), wall, true)
	Visuals.box(house, Vector3(0, h + 0.25, 0), Vector3(w + 0.8, 0.48, d + 0.8), roof)
	var dark_door := Visuals.material(Color(0.30, 0.19, 0.13))
	Visuals.box(house, Vector3(0, 1.3, d * 0.505), Vector3(1.6, 2.55, 0.12), dark_door)
	var count := 2 if h > 6.2 else 1
	for yid in range(count):
		for sx in [-2.9, 2.9]:
			Visuals.box(house, Vector3(sx, 2.0 + yid * 2.8, d * 0.507), Vector3(1.9, 1.3, 0.08), glass)
			Visuals.box(house, Vector3(sx, 2.0 + yid * 2.8, -d * 0.507), Vector3(1.9, 1.3, 0.08), glass)
	if house_id % 5 == 0:
		Visuals.box(house, Vector3(0, h + 0.6, 0), Vector3(3.2, 0.28, 2.0), metal)

func _build_tree(pos: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = pos
	trees_root.add_child(tree)
	var trunk := Visuals.material(Color(0.43, 0.27, 0.16))
	Visuals.cylinder(tree, Vector3(0, 1.8, 0), 0.22, 3.6, trunk)
	Visuals.sphere(tree, Vector3(0, 4.5, 0), Vector3(3.3, 2.8, 3.2), foliage)

func _build_lamp(pos: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	add_child(lamp)
	Visuals.cylinder(lamp, Vector3(0, 3.4, 0), 0.085, 6.8, metal)
	Visuals.box(lamp, Vector3(0.8, 6.55, 0), Vector3(1.7, 0.13, 0.15), metal)
	Visuals.box(lamp, Vector3(1.55, 6.37, 0), Vector3(0.48, 0.20, 0.45), Visuals.material(Color(1.0, 0.93, 0.7)))

func set_quality(level: int) -> void:
	quality = clampi(level, 0, 2)
	day_light.shadow_enabled = quality > 0
	day_light.directional_shadow_max_distance = 45.0 if quality == 1 else 110.0
	global_env.environment.fog_density = 0.0 if quality == 0 else 0.0018
	if trees_root:
		trees_root.visible = quality > 0

func update_visibility(focus_position: Vector3) -> void:
	# Keep render cost lower on Android without removing nearby collisions.
	var visible_distance := 94.0 if quality == 0 else (145.0 if quality == 1 else 205.0)
	var max_sq := visible_distance * visible_distance
	for house in buildings:
		var dx: float = house.global_position.x - focus_position.x
		var dz: float = house.global_position.z - focus_position.z
		house.visible = dx * dx + dz * dz <= max_sq
