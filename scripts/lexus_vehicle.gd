extends CharacterBody3D

# Veículos 3D originais e estilizados: silhuetas X7/SW4/ambulância, não modelos licenciados.
const Visuals = preload("res://scripts/visuals.gd")
const REVERSE_SPEED = 9.0
const BRAKING = 18.0

var car_name: String = "Sedan Lexus"
var model_type: String = "sedan" # sedan, hatch, x7, sw4, samu
var organization: String = ""
var paint_color: Color = Color(0.14, 0.16, 0.20)
var plate: String = "LX-001"
var driver_inside := false
var throttle: float = 0.0
var steer: float = 0.0
var signed_speed: float = 0.0
var wheel_front_left: Node3D
var wheel_front_right: Node3D
var engine_on := false
var fuel: float = 100.0
var durability: float = 100.0
var engine_level: int = 0
var siren_active := false
var _siren_a: MeshInstance3D
var _siren_b: MeshInstance3D
var _paint_material: StandardMaterial3D
var _damage_cooldown := 0.0
var garage_owned := false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 4
	floor_snap_length = 0.35
	_build_car()

func _build_car() -> void:
	var suv := model_type == "x7" or model_type == "sw4"
	var ambulance := model_type == "samu"
	var length := 5.4 if ambulance else (4.9 if suv else 4.18)
	var width := 2.38 if ambulance or suv else 2.15
	var cabin_h := 2.55 if ambulance else (2.14 if suv else 1.85)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, cabin_h, length)
	col.shape = shape
	col.position = Vector3(0, cabin_h * 0.5, 0)
	add_child(col)

	var external_path := "res://assets/models/car_suv.glb" if suv else "res://assets/models/car_sedan.glb"
	# Somente usa GLB externo quando houver licença/autorização para distribuição.
	if ResourceLoader.exists(external_path) and not ambulance:
		var scene := load(external_path) as PackedScene
		if scene != null:
			add_child(scene.instantiate())
			return

	_paint_material = Visuals.material(paint_color, "", 1.0, 0.36)
	var dark := Visuals.material(Color(0.065, 0.08, 0.10))
	var glass := Visuals.material(Color(0.10, 0.22, 0.31), "", 1.0, 0.09)
	var steel := Visuals.material(Color(0.70, 0.73, 0.76), "", 1.0, 0.70)
	var headlight := Visuals.material(Color(0.95, 0.96, 0.86))
	var red := Visuals.material(Color(0.90, 0.10, 0.14))
	var blue := Visuals.material(Color(0.11, 0.42, 0.96))
	var roof_y := 2.05 if suv else 1.80
	if ambulance:
		roof_y = 2.65

	Visuals.box(self, Vector3(0, 0.92, 0), Vector3(width - 0.1, 0.72, length - 0.07), _paint_material)
	Visuals.box(self, Vector3(0, 1.47, -0.12), Vector3(width - 0.38, 0.62 if not ambulance else 1.26, length * 0.57), glass if not ambulance else _paint_material)
	Visuals.box(self, Vector3(0, roof_y, 0), Vector3(width - 0.32, 0.15, length * 0.63), _paint_material)
	Visuals.box(self, Vector3(0, 0.61, -length * 0.5), Vector3(width - 0.15, 0.22, 0.15), dark)
	Visuals.box(self, Vector3(0, 0.61, length * 0.5), Vector3(width - 0.15, 0.22, 0.15), dark)
	Visuals.box(self, Vector3(0, 0.94, -length * 0.51), Vector3(0.76, 0.25, 0.09), steel)

	for sx in [-1.0, 1.0]:
		Visuals.box(self, Vector3(sx * (width * 0.35), 0.98, -length * 0.51), Vector3(0.43, 0.19, 0.10), headlight)
		Visuals.box(self, Vector3(sx * (width * 0.35), 0.96, length * 0.51), Vector3(0.45, 0.21, 0.10), red)
		Visuals.box(self, Vector3(sx * (width * 0.5), 1.43, -0.9), Vector3(0.18, 0.13, 0.35), _paint_material)
		for sz in [-1.0, 1.0]:
			var wheel := Node3D.new()
			wheel.position = Vector3(sx * (width * 0.5), 0.45, sz * (length * 0.29))
			wheel.name = "Roda"
			add_child(wheel)
			var model := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.42 if suv or ambulance else 0.36
			cylinder.bottom_radius = cylinder.top_radius
			cylinder.height = 0.24
			model.mesh = cylinder
			model.rotation_degrees = Vector3(0, 0, 90)
			model.material_override = dark
			wheel.add_child(model)
			var hub := Visuals.cylinder(wheel, Vector3.ZERO, 0.13, 0.27, steel)
			hub.rotation_degrees.z = 90
			if sz < 0.0:
				if sx < 0.0:
					wheel_front_left = wheel
				else:
					wheel_front_right = wheel

	if ambulance:
		Visuals.box(self, Vector3(0, 2.05, 0.42), Vector3(width - 0.38, 1.0, length * 0.54), _paint_material)
		Visuals.box(self, Vector3(0, 2.06, -1.42), Vector3(1.58, 0.45, 0.08), glass)
		Visuals.box(self, Vector3(0, 2.22, length * 0.51), Vector3(0.20, 1.2, 0.10), red)
		Visuals.box(self, Vector3(0, 2.22, length * 0.52), Vector3(1.2, 0.20, 0.11), red)

	if organization != "":
		var decal := Visuals.label_3d(self, organization, Vector3(0, 1.45, length * 0.51 + 0.06), 44)
		decal.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		decal.pixel_size = 0.006
		decal.modulate = Color(1.0, 1.0, 1.0) if model_type != "samu" else Color(0.80, 0.10, 0.12)
		if organization == "BOPE" or organization == "POLICIA CIVIL" or organization == "SAMU":
			_siren_a = _light_bar(Vector3(-0.32, roof_y + 0.16, -0.1), blue)
			_siren_b = _light_bar(Vector3(0.32, roof_y + 0.16, -0.1), red)

	var plate_sign := Visuals.label_3d(self, plate, Vector3(0, 0.68, length * 0.52), 26)
	plate_sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	plate_sign.pixel_size = 0.005

func _light_bar(where: Vector3, mat: Material) -> MeshInstance3D:
	var pivot := Visuals.box(self, where, Vector3(0.52, 0.18, 0.35), mat)
	return pivot.get_child(0) as MeshInstance3D

func _process(_delta: float) -> void:
	if _siren_a != null and _siren_b != null:
		var blink := int(Time.get_ticks_msec() / 180) % 2 == 0
		_siren_a.visible = siren_active and blink
		_siren_b.visible = siren_active and not blink

func _physics_process(delta: float) -> void:
	_damage_cooldown = maxf(0.0, _damage_cooldown - delta)
	var target := 0.0
	if driver_inside and engine_on and fuel > 0.0 and durability > 0.0:
		var top_speed := 30.0 + float(engine_level) * 4.0
		target = top_speed if throttle > 0.08 else (-REVERSE_SPEED if throttle < -0.08 else 0.0)
		fuel = maxf(0.0, fuel - absf(throttle) * delta * 0.09)
	var acceleration := 9.0 + float(engine_level) * 2.2
	var change := BRAKING if absf(target) < absf(signed_speed) else acceleration
	signed_speed = move_toward(signed_speed, target, delta * change)
	if absf(signed_speed) > 0.5:
		rotation.y -= steer * delta * 1.0 * clampf(absf(signed_speed) / 11.0, 0.3, 1.6) * signf(signed_speed)
	if wheel_front_left != null:
		wheel_front_left.rotation.y = steer * 0.36
	if wheel_front_right != null:
		wheel_front_right.rotation.y = steer * 0.36
	velocity.x = -basis.z.x * signed_speed
	velocity.z = -basis.z.z * signed_speed
	if is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= 25.0 * delta
	move_and_slide()
	if get_slide_collision_count() > 0 and absf(signed_speed) > 8.0 and _damage_cooldown <= 0.0:
		_damage_cooldown = 1.1
		durability = maxf(0.0, durability - minf(17.0, absf(signed_speed) * 0.45))
		signed_speed *= 0.35

func set_paint(value: Color) -> void:
	paint_color = value
	if _paint_material != null:
		_paint_material.albedo_color = value

func upgrade_engine() -> bool:
	if engine_level >= 3:
		return false
	engine_level += 1
	return true

func refuel() -> void:
	fuel = 100.0

func repair() -> void:
	durability = 100.0

func toggle_siren() -> void:
	if organization == "BOPE" or organization == "POLICIA CIVIL" or organization == "SAMU":
		siren_active = not siren_active

func speed_kmh() -> int:
	return int(round(absf(signed_speed) * 3.6))

func occupied() -> bool:
	return driver_inside
