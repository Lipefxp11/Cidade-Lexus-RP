extends CharacterBody3D

const Humanoid = preload("res://scripts/humanoid.gd")
const Visuals = preload("res://scripts/visuals.gd")

var max_health := 100.0
var health := 100.0
var active := true
var hostile := false
var attack_timer := 0.0
var respawn_timer := 0.0
var spawn_point := Vector3.ZERO
var visual
var collider: CollisionShape3D
var label: Label3D

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	floor_snap_length = 0.25
	spawn_point = global_position
	collider = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	visual = Humanoid.new()
	visual.scale = Vector3(0.96, 0.96, 0.96)
	add_child(visual)
	label = Visuals.label_3d(self, "NPC • PATRULHA", Vector3(0, 2.7, 0), 32)

func simulate(delta: float, player_pos: Vector3, player_alive: bool, player_in_car: bool) -> float:
	if not active:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_revive_npc()
		return 0.0
	if not is_on_floor():
		velocity.y -= 22.0 * delta
		move_and_slide()
	attack_timer -= delta
	if hostile and player_alive:
		var dist := global_position.distance_to(player_pos)
		if dist <= 23.0 and not player_in_car:
			look_at(Vector3(player_pos.x, global_position.y, player_pos.z), Vector3.UP)
			if attack_timer <= 0.0:
				attack_timer = 1.25
				return 7.0
	visual.update_pose(delta, 0.0, false, hostile)
	return 0.0

func take_hit(damage: float) -> bool:
	if not active:
		return false
	hostile = true
	health = maxf(0.0, health - damage)
	label.text = "NPC • VIDA %d" % int(health)
	if health <= 0.0:
		active = false
		visual.visible = false
		label.text = "NPC CAÍDO • RETORNO EM 20S"
		collider.set_deferred("disabled", true)
		respawn_timer = 20.0
		return true
	return false

func _revive_npc() -> void:
	health = max_health
	active = true
	hostile = false
	attack_timer = 0.0
	global_position = spawn_point
	visual.visible = true
	label.text = "NPC • PATRULHA"
	collider.set_deferred("disabled", false)
