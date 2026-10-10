extends Node3D

# Interior local compacto, independente do mapa exterior. Godot 4.4/Android.
const Visuals = preload("res://scripts/visuals.gd")
var current_home_id: String = ""
var interior_origin := Vector3(0, -2000, 0)
var door_position := Vector3(0, 0, 6.0)
var entry_position := Vector3(0, 0.25, 1.2)
var wallpaper: StandardMaterial3D

func _ready() -> void:
	position = interior_origin
	_build_room()
	visible = false

func _build_room() -> void:
	var parquet := Visuals.material(Color(0.42, 0.27, 0.16), "res://assets/textures/roof.png", 2.0)
	wallpaper = Visuals.material(Color(0.83, 0.80, 0.72), "res://assets/textures/plaster.png", 2.0)
	var tile := Visuals.material(Color(0.73, 0.73, 0.74), "res://assets/textures/concrete.png", 2.0)
	var furniture := Visuals.material(Color(0.24, 0.24, 0.26))
	var fabric := Visuals.material(Color(0.35, 0.13, 0.15))
	var glass := Visuals.material(Color(0.39, 0.63, 0.76))
	Visuals.box(self, Vector3(0, -0.20, 0), Vector3(15.0, 0.4, 14.0), parquet, true)
	Visuals.box(self, Vector3(0, 5.0, 0), Vector3(15.0, 0.3, 14.0), tile, true)
	Visuals.box(self, Vector3(-7.5, 2.5, 0), Vector3(0.4, 5.0, 14.0), wallpaper, true)
	Visuals.box(self, Vector3(7.5, 2.5, 0), Vector3(0.4, 5.0, 14.0), wallpaper, true)
	Visuals.box(self, Vector3(0, 2.5, -7.0), Vector3(15.0, 5.0, 0.4), wallpaper, true)
	# Parede com abertura no centro para a saída, com duas colunas laterais.
	Visuals.box(self, Vector3(-4.75, 2.5, 7.0), Vector3(5.5, 5.0, 0.4), wallpaper, true)
	Visuals.box(self, Vector3(4.75, 2.5, 7.0), Vector3(5.5, 5.0, 0.4), wallpaper, true)
	Visuals.box(self, Vector3(0, 4.2, 7.0), Vector3(4.0, 1.6, 0.4), wallpaper, true)
	Visuals.box(self, Vector3(0, 1.6, 7.04), Vector3(2.2, 3.2, 0.12), furniture)
	Visuals.label_3d(self, "SAIDA | F", Vector3(0, 3.65, 6.77), 53)
	# Sofá, mesa, estante, cama e cozinha (objetos com colisão).
	Visuals.box(self, Vector3(-4.1, 0.62, -3.1), Vector3(3.5, 1.2, 1.4), fabric, true)
	Visuals.box(self, Vector3(-4.1, 1.12, -3.7), Vector3(3.5, 1.2, 0.45), fabric, true)
	Visuals.box(self, Vector3(-4.1, 0.43, -0.85), Vector3(2.0, 0.85, 1.25), furniture, true)
	Visuals.box(self, Vector3(4.1, 0.47, -3.3), Vector3(3.5, 0.90, 2.5), furniture, true)
	Visuals.box(self, Vector3(4.1, 0.9, -3.3), Vector3(3.3, 0.25, 2.3), fabric)
	Visuals.box(self, Vector3(5.0, 1.2, 3.6), Vector3(3.4, 2.4, 1.4), tile, true)
	Visuals.box(self, Vector3(5.0, 2.5, 4.25), Vector3(3.0, 1.8, 0.1), glass)
	var point_light := OmniLight3D.new()
	point_light.position = Vector3(0, 4.3, 0)
	point_light.light_color = Color(1.0, 0.91, 0.78)
	point_light.light_energy = 2.3
	point_light.omni_range = 20.0
	add_child(point_light)

func open_house(home_id: String) -> void:
	current_home_id = home_id
	visible = true
	if wallpaper != null:
		var seed_value := absi(home_id.hash())
		wallpaper.albedo_color = Color(0.78 + (seed_value % 8) * 0.01, 0.76, 0.70)

func close_house() -> void:
	current_home_id = ""
	visible = false

func spawn_location() -> Vector3:
	return interior_origin + entry_position

func near_exit(global_pos: Vector3) -> bool:
	return global_pos.distance_to(interior_origin + door_position) < 5.2
