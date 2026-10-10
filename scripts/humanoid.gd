extends Node3D

# Official Cidade Lexus character: original GLB bundled in the APK, joint-driven procedural animation.
# Primitive fallback only if importing the packaged GLB fails.
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
var imported_model: Node3D
var imported_animation: AnimationPlayer
var last_imported_animation := ""
var imported_parts: Dictionary = {}
var imported_base: Dictionary = {}
var official_model_active: bool = false
var official_weapon: Node3D
var animation_time: float = 0.0
var dead_pose: bool = false

func _ready() -> void:
	# The official playable character is packaged with the APK; no external download.
	var model_path := "res://assets/models/character.glb"
	if ResourceLoader.exists(model_path):
		var packed: PackedScene = load(model_path) as PackedScene
		if packed != null:
			imported_model = packed.instantiate() as Node3D
			if imported_model != null:
				add_child(imported_model)
				imported_model.scale = Vector3.ONE * 0.935
				imported_model.position.y = 0.062
				var names := [
					"LexusRig", "LexusHips", "LexusChest", "LexusHead",
					"LexusLeftArm", "LexusRightArm", "LexusLeftForearm", "LexusRightForearm",
					"LexusLeftHand", "LexusRightHand", "LexusLeftLeg", "LexusRightLeg",
					"LexusLeftShin", "LexusRightShin", "LexusLeftFoot", "LexusRightFoot"
				]
				for part_name in names:
					var pivot := imported_model.find_child(part_name, true, false) as Node3D
					if pivot != null:
						imported_parts[part_name] = pivot
						imported_base[part_name] = pivot.transform
				if imported_parts.has("LexusLeftLeg") and imported_parts.has("LexusRightLeg") and imported_parts.has("LexusHead"):
					official_model_active = true
					_setup_official_sidearm()
					return
				# If import is incomplete, fall back instead of rendering a broken character.
				remove_child(imported_model)
				imported_model.queue_free()
				imported_model = null
				imported_parts.clear()
				imported_base.clear()
	build()

func _setup_official_sidearm() -> void:
	var right_hand := imported_parts.get("LexusRightHand") as Node3D
	if right_hand == null:
		return
	official_weapon = Node3D.new()
	official_weapon.name = "ArmaVisualLexus"
	official_weapon.position = Vector3(0.015, -0.10, -0.088)
	right_hand.add_child(official_weapon)
	var steel := Visuals.material(Color(0.075, 0.09, 0.11), "", 1.0, 0.35)
	var handle := Visuals.material(Color(0.15, 0.16, 0.18))
	Visuals.box(official_weapon, Vector3(0, 0.005, -0.08), Vector3(0.070, 0.067, 0.19), steel)
	Visuals.box(official_weapon, Vector3(0, -0.072, -0.020), Vector3(0.064, 0.12, 0.065), handle)
	official_weapon.visible = false

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

func update_pose(delta: float, speed_ratio: float, crouching: bool, aiming: bool, recoil: float = 0.0, airborne: bool = false, defeated: bool = false) -> void:
	if official_model_active:
		_animate_official(delta, speed_ratio, crouching, aiming, recoil, airborne, defeated)
		return
	if imported_model != null:
		if imported_animation != null:
			var wanted := "Idle"
			if defeated:
				wanted = "Death"
			elif airborne:
				wanted = "Jump"
			elif crouching:
				wanted = "Crouch"
			elif aiming:
				wanted = "Aim"
			elif speed_ratio > 1.05:
				wanted = "Run"
			elif speed_ratio > 0.05:
				wanted = "Walk"
			if wanted != last_imported_animation and imported_animation.has_animation(wanted):
				imported_animation.play(wanted, 0.15)
				last_imported_animation = wanted
		return
	# Legacy capsule fallback, used only if GLB import fails.
	if hips == null:
		return
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
		arm_r.rotation.x -= recoil * 0.42
	chest.rotation.x = recoil * 0.075

func _official_reset_part(part_name: String, delta: float) -> void:
	var part := imported_parts.get(part_name) as Node3D
	if part == null:
		return
	var base: Transform3D = imported_base[part_name]
	part.position = part.position.lerp(base.origin, minf(1.0, delta * 10.0))
	part.rotation = part.rotation.lerp(base.basis.get_euler(), minf(1.0, delta * 10.0))

func _official_pose_part(part_name: String, desired: Vector3, delta: float) -> void:
	var part := imported_parts.get(part_name) as Node3D
	if part == null:
		return
	var base: Transform3D = imported_base[part_name]
	part.rotation = part.rotation.lerp(base.basis.get_euler() + desired, minf(1.0, delta * 12.0))

func _animate_official(delta: float, speed_ratio: float, crouching: bool, aiming: bool, recoil: float, airborne: bool, defeated: bool) -> void:
	dead_pose = defeated
	var pace := clampf(speed_ratio, 0.0, 1.55)
	var moving := pace > 0.08
	animation_time += delta * (4.0 + pace * 5.5) if moving else delta * 1.1
	var stride := sin(animation_time) * minf(0.8, pace * 0.54)
	var knee_forward := maxf(0.0, sin(animation_time)) * pace * 0.55
	var knee_backward := maxf(0.0, -sin(animation_time)) * pace * 0.55
	var sway := sin(animation_time * 0.48) * 0.015
	var breathing := sin(animation_time * 0.70) * 0.012
	var speed := minf(1.0, delta * 9.0)
	var rig := imported_parts.get("LexusRig") as Node3D
	if rig != null:
		var base: Transform3D = imported_base["LexusRig"]
		var lower := -0.24 if crouching else 0.0
		rig.position = rig.position.lerp(base.origin + Vector3(0, lower, 0), speed)
	var head_part := imported_parts.get("LexusHead") as Node3D
	var chest_part := imported_parts.get("LexusChest") as Node3D
	if chest_part != null:
		chest_part.position.y = lerpf(chest_part.position.y, 1.03 + breathing - (0.07 if crouching else 0.0), speed)
	if head_part != null:
		head_part.position.y = lerpf(head_part.position.y, 0.58 - (0.06 if crouching else 0.0), speed)
	_official_pose_part("LexusHips", Vector3(0, 0, sway if moving else 0.0), delta)
	_official_pose_part("LexusChest", Vector3((0.18 if crouching else 0.0) - recoil * 0.04, sin(animation_time) * pace * 0.015, -sway), delta)
	_official_pose_part("LexusHead", Vector3(-0.06 if crouching else 0.0, 0, 0), delta)
	if defeated:
		_official_pose_part("LexusRig", Vector3(0, 0, PI * 0.44), delta)
		return
	_official_pose_part("LexusRig", Vector3.ZERO, delta)
	if airborne:
		stride = 0.0
		knee_forward = 0.35
		knee_backward = 0.35
	_official_pose_part("LexusLeftLeg", Vector3(stride + (0.54 if crouching else 0.0), 0, 0.025), delta)
	_official_pose_part("LexusRightLeg", Vector3(-stride + (0.54 if crouching else 0.0), 0, -0.025), delta)
	_official_pose_part("LexusLeftShin", Vector3(-knee_forward - (0.78 if crouching else 0.0), 0, 0), delta)
	_official_pose_part("LexusRightShin", Vector3(-knee_backward - (0.78 if crouching else 0.0), 0, 0), delta)
	_official_pose_part("LexusLeftFoot", Vector3(0.08 + (0.25 if airborne else 0.0), 0, 0), delta)
	_official_pose_part("LexusRightFoot", Vector3(0.08 + (0.25 if airborne else 0.0), 0, 0), delta)
	var left_arm := -stride * 0.7
	var right_arm := stride * 0.7
	if aiming:
		left_arm = 1.08
		right_arm = 1.16 - recoil * 0.18
	_official_pose_part("LexusLeftArm", Vector3(left_arm, 0, -0.07), delta)
	_official_pose_part("LexusRightArm", Vector3(right_arm, 0, 0.07), delta)
	_official_pose_part("LexusLeftForearm", Vector3(0.42 if aiming else 0.07, 0, 0), delta)
	_official_pose_part("LexusRightForearm", Vector3(0.28 if aiming else 0.06, 0, 0), delta)
	if official_weapon != null:
		official_weapon.visible = aiming

func set_skin(color: Color) -> void:
	body_skin = color
