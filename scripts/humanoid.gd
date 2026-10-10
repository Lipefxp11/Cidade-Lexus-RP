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
var realistic_model_active: bool = false
var realistic_anim_state: String = ""
var realistic_height_offset: float = 0.0
var official_weapon: Node3D
var animation_time: float = 0.0
var dead_pose: bool = false
var skin_tone_index: int = 1
var hair_style_index: int = 0
var outfit_index: int = 0
const SKIN_TONES = [
	Color(0.42, 0.27, 0.20),
	Color(0.67, 0.45, 0.32),
	Color(0.83, 0.62, 0.46),
	Color(0.96, 0.78, 0.65)
]
const HAIR_TONES = [
	Color(0.12, 0.09, 0.07),
	Color(0.29, 0.17, 0.11),
	Color(0.76, 0.70, 0.59),
	Color(0.10, 0.10, 0.13)
]

func _ready() -> void:
	# V20: skinned model is OPTIONAL. The APK always bundles the original Lexus GLB.
	# A user-owned, correctly licensed animated GLB can be added at this path.
	if _try_realistic_character():
		return
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
					apply_appearance(outfit_index, skin_tone_index, hair_style_index)
					return
				# If import is incomplete, fall back instead of rendering a broken character.
				remove_child(imported_model)
				imported_model.queue_free()
				imported_model = null
				imported_parts.clear()
				imported_base.clear()
	build()

func _try_realistic_character() -> bool:
	# The CI workflow supplies this CC BY 4.0 model before the Godot import.
	# When working offline without that asset, the V17 original remains usable.
	var path := "res://assets/models/hero_realistic.glb"
	if not ResourceLoader.exists(path):
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("V19: personagem realista existe mas não é uma cena GLB válida")
		return false
	var instance := packed.instantiate() as Node3D
	if instance == null:
		push_warning("V19: arquivo 3D não gerou Node3D")
		return false

	var skeletons: Array[Node] = instance.find_children("*", "Skeleton3D", true, false)
	var anim_players: Array[Node] = instance.find_children("*", "AnimationPlayer", true, false)
	if skeletons.is_empty() or anim_players.is_empty():
		push_warning("V19: GLB sem Skeleton3D/AnimationPlayer; usando o boneco V17")
		instance.free()
		return false
	var anim := anim_players[0] as AnimationPlayer
	if anim.get_animation_list().is_empty():
		push_warning("V19: GLB sem animações importadas; usando o boneco V17")
		instance.free()
		return false

	imported_model = instance
	imported_animation = anim
	imported_model.name = "LexusHumanoRealista"
	# +Z visual front convention for the external sample; game forward is -Z.
	imported_model.rotation.y = PI
	add_child(imported_model)
	realistic_model_active = true
	_play_realistic_clip(["idle", "look"], 1.0)
	print("V19: personagem humano GLB com esqueleto e animações carregado")
	return true

func _select_realistic_clip(search_terms: Array) -> String:
	if imported_animation == null:
		return ""
	var clips := imported_animation.get_animation_list()
	for term in search_terms:
		for clip in clips:
			if term in String(clip).to_lower():
				return String(clip)
	# Prefer an idle over a random attack/intro loop.
	if clips.size() > 0:
		return String(clips[0])
	return ""

func _play_realistic_clip(terms: Array, speed_factor: float) -> void:
	var wanted := _select_realistic_clip(terms)
	if wanted == "" or imported_animation == null:
		return
	imported_animation.speed_scale = speed_factor
	if realistic_anim_state != wanted or not imported_animation.is_playing():
		imported_animation.play(wanted, 0.16)
		realistic_anim_state = wanted

func _animate_realistic(delta: float, speed_ratio: float, crouching: bool, aiming: bool, recoil: float, airborne: bool, defeated: bool) -> void:
	if imported_model == null:
		return
	if defeated:
		_play_realistic_clip(["death", "fall", "idle"], 1.0)
	elif airborne:
		_play_realistic_clip(["jump", "idle"], 1.0)
	elif crouching:
		_play_realistic_clip(["crouch", "walk", "idle"], 0.55)
	elif speed_ratio > 1.12:
		_play_realistic_clip(["run", "sprint", "walk"], 1.0)
	elif speed_ratio > 0.08:
		_play_realistic_clip(["walk", "run"], 1.0)
	else:
		_play_realistic_clip(["idle", "look", "walk"], 1.0)
	# Aiming and firing remain supported by gameplay, but a proper weapon-specific
	# skeletal animation is NOT available in the demo asset. Avoid deforming it.
	var target_drop := -0.22 if crouching else 0.0
	realistic_height_offset = lerpf(realistic_height_offset, target_drop, minf(1.0, delta * 9.0))
	imported_model.position.y = realistic_height_offset

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
	if realistic_model_active:
		_animate_realistic(delta, speed_ratio, crouching, aiming, recoil, airborne, defeated)
		return
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

# Loja de skins: altera apenas roupas do modelo original, sem recolorir rosto/pele.
func set_outfit(style: int) -> void:
	var selected := clampi(style, 0, 2)
	var shirt_color := Color(0.08, 0.10, 0.13)
	var trousers_color := Color(0.08, 0.13, 0.23)
	match selected:
		1:
			shirt_color = Color(0.58, 0.065, 0.10)
			trousers_color = Color(0.10, 0.11, 0.13)
		2:
			shirt_color = Color(0.12, 0.20, 0.26)
			trousers_color = Color(0.11, 0.15, 0.19)
	if realistic_model_active:
		# Do not overwrite high-resolution cloth/skin maps in the demo GLB.
		# A matching wardrobe rig is necessary for genuine outfit replacement.
		return
	if official_model_active and imported_model != null:
		for node in imported_model.find_children("*", "MeshInstance3D", true, false):
			var mesh_node := node as MeshInstance3D
			if mesh_node == null:
				continue
			var node_name := mesh_node.name.to_lower()
			var chosen_color: Color
			if "urban_shirt" in node_name or "upper_chest" in node_name:
				chosen_color = shirt_color
			elif "tailored_hips" in node_name or "thigh" in node_name or "_shin" in node_name or "cargo_pocket" in node_name:
				chosen_color = trousers_color
			else:
				continue
			var replacement := StandardMaterial3D.new()
			replacement.albedo_color = chosen_color
			replacement.roughness = 0.82
			mesh_node.material_override = replacement
	elif chest != null and hips != null:
		# Fallback: mantém roupa diferente mesmo se a importação GLB falhar.
		for visual in chest.find_children("*", "MeshInstance3D", true, false):
			var mesh_node := visual as MeshInstance3D
			if mesh_node != null and mesh_node.material_override != null:
				var mat := mesh_node.material_override.duplicate() as StandardMaterial3D
				if mat != null:
					mat.albedo_color = shirt_color
					mesh_node.material_override = mat

# V20 — visual customization in the built-in GLB. Does not modify eyes/teeth/clothing accessories.
# A third-party skinned model keeps its own PBR textures until it has a compatible wardrobe.
func apply_appearance(outfit: int, skin_tone: int, hair_tone: int) -> void:
	outfit_index = clampi(outfit, 0, 2)
	skin_tone_index = clampi(skin_tone, 0, SKIN_TONES.size() - 1)
	hair_style_index = clampi(hair_tone, 0, HAIR_TONES.size() - 1)
	if realistic_model_active:
		return
	set_outfit(outfit_index)
	if official_model_active and imported_model != null:
		for item in imported_model.find_children("*", "MeshInstance3D", true, false):
			var part := item as MeshInstance3D
			if part == null:
				continue
			var nm := part.name.to_lower()
			var color := Color.WHITE
			var tint := false
			if "hair" in nm or "curl_" in nm or "brow_" in nm:
				color = HAIR_TONES[hair_style_index]
				tint = true
			elif "face_" in nm or "jaw" in nm or "nose_" in nm or "cheek_" in nm or "neck" in nm or "ear_" in nm or "upper_arm" in nm or "forearm" in nm or "hand_shape" in nm or "finger_" in nm:
				# Avoid recoloring tattoos and shirt geometry.
				if "tattoo" not in nm and "seam" not in nm:
					color = SKIN_TONES[skin_tone_index]
					tint = true
			if tint:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = color
				mat.roughness = 0.86
				part.material_override = mat
	elif head != null:
		body_skin = SKIN_TONES[skin_tone_index]

func has_skinned_human() -> bool:
	return realistic_model_active
