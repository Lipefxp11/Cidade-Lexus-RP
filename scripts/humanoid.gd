extends Node3D

# Mobile-friendly articulated humanoid. Primitive placeholder until a rigged GLB is imported.
const Visuals = preload("res://scripts/visuals.gd")
var hips: Node3D
var chest: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var forearm_l: Node3D
var forearm_r: Node3D
var head: Node3D
var animation_phase: float = 0.0
var crouched: float = 0.0
var body_skin: Color = Color(0.74, 0.51, 0.37)

func _ready() -> void:
	build()

func build() -> void:
	var skin := Visuals.material(body_skin)
	var shirt := Visuals.material(Color(0.08, 0.10, 0.13))
	var jean := Visuals.material(Color(0.08, 0.13, 0.23))
	var shoe := Visuals.material(Color(0.09, 0.09, 0.10))
	var hair := Visuals.material(Color(0.09, 0.07, 0.06))

	hips = Node3D.new()
	add_child(hips)
	Visuals.sphere(hips, Vector3(0, 1.04, 0), Vector3(0.78, 0.43, 0.44), jean)

	chest = Node3D.new()
	chest.position.y = 1.08
	add_child(chest)
	Visuals.sphere(chest, Vector3(0, 0.30, 0), Vector3(0.98, 0.98, 0.56), shirt)
	Visuals.cylinder(chest, Vector3(0, 0.81, 0), 0.105, 0.16, skin)

	head = Node3D.new()
	head.position.y = 1.85
	add_child(head)
	Visuals.sphere(head, Vector3.ZERO, Vector3(0.49, 0.60, 0.47), skin)
	Visuals.sphere(head, Vector3(0, 0.23, 0), Vector3(0.50, 0.18, 0.48), hair)
	Visuals.sphere(head, Vector3(-0.13, 0.03, -0.23), Vector3(0.07, 0.06, 0.06), hair)
	Visuals.sphere(head, Vector3(0.13, 0.03, -0.23), Vector3(0.07, 0.06, 0.06), hair)
	Visuals.sphere(head, Vector3(0, -0.10, -0.24), Vector3(0.14, 0.11, 0.13), skin)

	arm_l = Node3D.new()
	arm_l.position = Vector3(-0.54, 1.62, 0)
	add_child(arm_l)
	Visuals.sphere(arm_l, Vector3(0, -0.24, 0), Vector3(0.29, 0.62, 0.31), shirt)
	forearm_l = Node3D.new()
	forearm_l.position = Vector3(0, -0.52, 0)
	arm_l.add_child(forearm_l)
	Visuals.sphere(forearm_l, Vector3(0, -0.22, 0), Vector3(0.22, 0.53, 0.24), skin)
	Visuals.sphere(forearm_l, Vector3(0, -0.50, 0), Vector3(0.22, 0.22, 0.21), skin)

	arm_r = Node3D.new()
	arm_r.position = Vector3(0.54, 1.62, 0)
	add_child(arm_r)
	Visuals.sphere(arm_r, Vector3(0, -0.24, 0), Vector3(0.29, 0.62, 0.31), shirt)
	forearm_r = Node3D.new()
	forearm_r.position = Vector3(0, -0.52, 0)
	arm_r.add_child(forearm_r)
	Visuals.sphere(forearm_r, Vector3(0, -0.22, 0), Vector3(0.22, 0.53, 0.24), skin)
	Visuals.sphere(forearm_r, Vector3(0, -0.50, 0), Vector3(0.22, 0.22, 0.21), skin)
	var gunmetal := Visuals.material(Color(0.13, 0.14, 0.16), "", 1.0, 0.55)
	Visuals.box(forearm_r, Vector3(0, -0.54, -0.18), Vector3(0.11, 0.18, 0.42), gunmetal)
	Visuals.box(forearm_r, Vector3(0, -0.62, -0.14), Vector3(0.10, 0.21, 0.10), gunmetal)

	leg_l = Node3D.new()
	leg_l.position = Vector3(-0.23, 0.99, 0)
	add_child(leg_l)
	Visuals.sphere(leg_l, Vector3(0, -0.39, 0), Vector3(0.35, 0.85, 0.33), jean)
	Visuals.sphere(leg_l, Vector3(0, -0.81, -0.05), Vector3(0.38, 0.18, 0.54), shoe)

	leg_r = Node3D.new()
	leg_r.position = Vector3(0.23, 0.99, 0)
	add_child(leg_r)
	Visuals.sphere(leg_r, Vector3(0, -0.39, 0), Vector3(0.35, 0.85, 0.33), jean)
	Visuals.sphere(leg_r, Vector3(0, -0.81, -0.05), Vector3(0.38, 0.18, 0.54), shoe)

func update_pose(delta: float, speed_ratio: float, crouching: bool, aiming: bool) -> void:
	var target_crouch := 1.0 if crouching else 0.0
	crouched = move_toward(crouched, target_crouch, delta * 5.5)
	hips.position.y = -0.26 * crouched
	chest.position.y = 1.08 - 0.23 * crouched
	head.position.y = 1.85 - 0.42 * crouched
	arm_l.position.y = 1.62 - 0.25 * crouched
	arm_r.position.y = 1.62 - 0.25 * crouched
	animation_phase += delta * (5.2 + speed_ratio * 6.0) * speed_ratio
	var swing := sin(animation_phase) * 0.48 * speed_ratio
	leg_l.rotation.x = swing
	leg_r.rotation.x = -swing
	arm_l.rotation.x = -swing * 0.8
	arm_r.rotation.x = swing * 0.8
	if aiming:
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -1.0, 0.4)
		arm_l.rotation.x = lerpf(arm_l.rotation.x, -0.85, 0.4)

func set_skin(color: Color) -> void:
	body_skin = color
