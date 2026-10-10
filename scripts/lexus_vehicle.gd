extends CharacterBody3D

const Visuals = preload("res://scripts/visuals.gd")
const MAX_SPEED = 25.0
const REVERSE_SPEED = 8.0
const ACCELERATION = 14.0
const BRAKING = 22.0

var car_name: String = "Sedan Lexus"
var paint_color: Color = Color(0.14, 0.16, 0.20)
var driver_inside := false
var throttle: float = 0.0
var steer: float = 0.0
var signed_speed: float = 0.0
var wheel_front_left: Node3D
var wheel_front_right: Node3D
var engine_on := false
var fuel: float = 100.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 4
	floor_snap_length = 0.26
	_build_car()

func _build_car() -> void:
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(2.3, 1.25, 4.2)
	collision.shape = box_shape
	collision.position = Vector3(0, 0.78, 0)
	add_child(collision)
	var paint := Visuals.material(paint_color, "", 1.0, 0.5)
	var glass := Visuals.material(Color(0.13, 0.22, 0.32), "", 1.0, 0.1)
	var tires := Visuals.material(Color(0.06, 0.065, 0.075))
	var metal := Visuals.material(Color(0.75, 0.78, 0.82), "", 1.0, 0.65)
	Visuals.box(self, Vector3(0, 0.84, 0), Vector3(2.22, 0.65, 4.1), paint)
	Visuals.box(self, Vector3(0, 1.42, -0.15), Vector3(1.76, 0.7, 2.17), glass)
	Visuals.box(self, Vector3(0, 1.85, -0.15), Vector3(1.78, 0.17, 2.15), paint)
	Visuals.box(self, Vector3(0, 0.76, -2.08), Vector3(1.77, 0.20, 0.12), metal)
	Visuals.box(self, Vector3(0, 0.76, 2.08), Vector3(1.77, 0.20, 0.12), metal)
	for sign_x in [-1.0, 1.0]:
		for sign_z in [-1.0, 1.0]:
			var wheel := Node3D.new()
			wheel.position = Vector3(sign_x * 1.08, 0.43, sign_z * 1.27)
			add_child(wheel)
			var model := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.38
			cylinder.bottom_radius = 0.38
			cylinder.height = 0.20
			model.mesh = cylinder
			model.rotation_degrees = Vector3(0, 0, 90)
			model.material_override = tires
			wheel.add_child(model)
			if sign_z < 0:
				if sign_x < 0:
					wheel_front_left = wheel
				else:
					wheel_front_right = wheel

func _physics_process(delta: float) -> void:
	var target := 0.0
	if driver_inside and engine_on and fuel > 0:
		target = MAX_SPEED if throttle > 0.1 else (-REVERSE_SPEED if throttle < -0.1 else 0.0)
		if throttle > 0.1:
			fuel = maxf(0.0, fuel - delta * 0.10)
		elif throttle < -0.1:
			fuel = maxf(0.0, fuel - delta * 0.05)
	var adjust := BRAKING if absf(target) < absf(signed_speed) else ACCELERATION
	signed_speed = move_toward(signed_speed, target, delta * adjust)
	if absf(signed_speed) > 0.35:
		rotation.y -= steer * delta * 1.0 * clampf(absf(signed_speed) / 11.0, 0.3, 1.7) * signf(signed_speed)
		wheel_front_left.rotation.y = steer * 0.3
		wheel_front_right.rotation.y = steer * 0.3
	velocity.x = -basis.z.x * signed_speed
	velocity.z = -basis.z.z * signed_speed
	if is_on_floor():
		velocity.y = -0.04
	else:
		velocity.y -= 25.0 * delta
	move_and_slide()
	global_position.x = clampf(global_position.x, -183.0, 183.0)
	global_position.z = clampf(global_position.z, -183.0, 183.0)

func speed_kmh() -> int:
	return int(round(absf(signed_speed) * 3.6))

func occupied() -> bool:
	return driver_inside
