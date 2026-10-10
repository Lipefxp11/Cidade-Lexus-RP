extends Node3D

const SPEED := 5.0
const RUN_SPEED := 8.0
var player: CharacterBody3D
var camera: Camera3D
var buttons := {}
var held := {"forward": false, "back": false, "left": false, "right": false, "run": false}
var status_label: Label

func _ready() -> void:
	_build_world()
	_build_player()
	_build_ui()

func _box(pos: Vector3, size: Vector3, color: Color, collision: bool = true) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	body.add_child(mesh)
	if collision:
		var col := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = size
		col.shape = cs
		body.add_child(col)
	add_child(body)

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.58, 0.77, 0.93)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.88, 1.0)
	e.ambient_light_energy = 0.65
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 1.2
	add_child(sun)
	_box(Vector3(0, -0.5, 0), Vector3(150, 1, 150), Color(0.30, 0.53, 0.32))
	_box(Vector3(0, 0.01, 0), Vector3(12, 0.04, 140), Color(0.14, 0.15, 0.17), false)
	_box(Vector3(0, 0.02, 0), Vector3(140, 0.04, 12), Color(0.14, 0.15, 0.17), false)
	for side in [-1, 1]:
		_box(Vector3(side * 7.4, 0.08, 0), Vector3(2.8, 0.16, 140), Color(0.65, 0.65, 0.62))
		for i in range(8):
			var z := -56.0 + i * 16.0
			var height := 5.0 + float(i % 4) * 2.0
			_box(Vector3(side * 17.0, height / 2.0, z), Vector3(11, height, 11), Color(0.79 - i * 0.025, 0.69, 0.56))
			_box(Vector3(side * 17.0, height + 0.25, z), Vector3(12, 0.5, 12), Color(0.45, 0.17, 0.13))
	for i in range(18):
		_box(Vector3(0, 0.055, -64 + i * 7.5), Vector3(0.18, 0.01, 3.0), Color(0.96, 0.86, 0.44), false)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1.2, 8)
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	col.shape = capsule
	player.add_child(col)
	var model := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.8
	model.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.12, 0.12)
	model.material_override = mat
	player.add_child(model)
	add_child(player)
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var title := Label.new()
	title.text = "CIDADE LEXUS RP  |  PROTÓTIPO 0.0.1"
	title.position = Vector2(25, 18)
	title.add_theme_font_size_override("font_size", 25)
	root.add_child(title)
	status_label = Label.new()
	status_label.text = "Bairro inicial • Offline"
	status_label.position = Vector2(25, 56)
	root.add_child(status_label)
	var positions := {"forward": Vector2(130, -195), "back": Vector2(130, -85), "left": Vector2(20, -140), "right": Vector2(240, -140), "run": Vector2(-150, -110)}
	var labels := {"forward": "▲", "back": "▼", "left": "◀", "right": "▶", "run": "CORRER"}
	for key in positions:
		var b := Button.new()
		b.text = labels[key]
		b.custom_minimum_size = Vector2(90, 80)
		b.set_anchors_preset(Control.PRESET_TOP_LEFT)
		b.position = positions[key]
		if key == "run":
			b.position = Vector2(-155, -110)
		b.button_down.connect(_press.bind(key, true))
		b.button_up.connect(_press.bind(key, false))
		root.add_child(b)
		buttons[key] = b
	# Reposition controls from viewport dimensions so they stay visible on mobile.
	get_viewport().size_changed.connect(_layout_controls)
	_layout_controls()

func _layout_controls() -> void:
	var size := get_viewport().get_visible_rect().size
	var offsets := {"forward": Vector2(125, -215), "back": Vector2(125, -105), "left": Vector2(20, -160), "right": Vector2(230, -160), "run": Vector2(-135, -135)}
	for key in buttons:
		var b: Button = buttons[key]
		b.position = Vector2(0 if key != "run" else size.x, size.y) + offsets[key]

func _press(key: String, value: bool) -> void:
	held[key] = value

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	input.x = float(held["right"]) - float(held["left"]) + Input.get_axis("ui_left", "ui_right")
	input.y = float(held["back"]) - float(held["forward"]) + Input.get_axis("ui_up", "ui_down")
	input = input.limit_length(1.0)
	var direction := Vector3(input.x, 0, input.y)
	var speed := RUN_SPEED if held["run"] or Input.is_key_pressed(KEY_SHIFT) else SPEED
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed
	player.velocity.y -= 22.0 * delta if not player.is_on_floor() else player.velocity.y
	player.move_and_slide()
	if direction.length() > 0.05:
		player.rotation.y = atan2(-direction.x, -direction.z)
	camera.global_position = camera.global_position.lerp(player.global_position + Vector3(0, 4.0, 7.5), min(1.0, delta * 7.0))
	camera.look_at(player.global_position + Vector3(0, 0.6, 0), Vector3.UP)
