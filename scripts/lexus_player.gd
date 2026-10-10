extends CharacterBody3D

const Humanoid = preload("res://scripts/humanoid.gd")
const WALK_SPEED = 4.7
const RUN_SPEED = 8.8
const CROUCH_SPEED = 2.2
const GRAVITY = 25.0

var visual
var shape_node: CollisionShape3D
var health: float = 100.0
var stamina: float = 100.0
var is_dead := false
var is_crouching := false
var is_running := false
var in_vehicle := false
var run_held := false
var crouch_held := false
var aim_held := false
var jump_request := false
var input_direction := Vector2.ZERO
var facing_yaw: float = PI
var walk_intensity: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	floor_snap_length = 0.30
	shape_node = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.85
	shape_node.shape = shape
	shape_node.position.y = 0.93
	add_child(shape_node)
	visual = Humanoid.new()
	add_child(visual)

func _physics_process(delta: float) -> void:
	if is_dead or in_vehicle:
		velocity = Vector3.ZERO
		return
	is_crouching = crouch_held
	is_running = run_held and not crouch_held and stamina > 2.0 and input_direction.length() > 0.2
	var speed := CROUCH_SPEED if is_crouching else (RUN_SPEED if is_running else WALK_SPEED)
	var front := Vector3(-sin(facing_yaw), 0, -cos(facing_yaw))
	var side := Vector3(cos(facing_yaw), 0, -sin(facing_yaw))
	var move_dir := (side * input_direction.x + front * -input_direction.y)
	move_dir = move_dir.limit_length(1.0)
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.05
		if jump_request and not is_crouching:
			velocity.y = 8.0
	jump_request = false
	move_and_slide()
	global_position.x = clampf(global_position.x, -182.0, 182.0)
	global_position.z = clampf(global_position.z, -182.0, 182.0)

	if move_dir.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-move_dir.x, -move_dir.z), minf(1.0, delta * 12.0))
	walk_intensity = lerpf(walk_intensity, move_dir.length() * (1.45 if is_running else 1.0), minf(1.0, delta * 10))
	if is_running:
		stamina = maxf(0.0, stamina - delta * 15.0)
	else:
		stamina = minf(100.0, stamina + delta * 10.0)
	if visual:
		visual.update_pose(delta, walk_intensity, is_crouching, aim_held)

func set_look_yaw(value: float) -> void:
	facing_yaw = value

func receive_damage(amount: float) -> bool:
	if is_dead or in_vehicle:
		return false
	health = maxf(0.0, health - amount)
	if health <= 0:
		is_dead = true
		return true
	return false

func heal(amount: float) -> void:
	if not is_dead:
		health = minf(100.0, health + amount)

func revive() -> void:
	is_dead = false
	health = 100.0
	stamina = 100.0
	global_position = Vector3(0, 0.15, 12)
	velocity = Vector3.ZERO
	visible = true
	shape_node.set_deferred("disabled", false)

func enter_vehicle() -> void:
	in_vehicle = true
	visible = false
	shape_node.set_deferred("disabled", true)

func exit_vehicle(exit_pos: Vector3) -> void:
	in_vehicle = false
	global_position = exit_pos
	velocity = Vector3.ZERO
	visible = true
	shape_node.set_deferred("disabled", false)
