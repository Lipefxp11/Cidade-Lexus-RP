extends Node3D

enum AppState { LOADING_BOOT, MENU, LOADING_GAME, PLAYING }

const WALK_SPEED := 4.6
const RUN_SPEED := 8.2
const CROUCH_SPEED := 2.4
const JUMP_FORCE := 8.0
const GRAVITY := 24.0
const MAP_LIMIT := 120.0

var app_state: int = AppState.LOADING_BOOT
var loading_progress: float = 0.0
var loading_duration: float = 1.8
var selected_server: String = "Cidade Lexus • Servidor 01"
var current_quality: int = 1

var player: CharacterBody3D
var player_visual: Node3D
var head: Node3D
var torso: Node3D
var arm_left: Node3D
var arm_right: Node3D
var leg_left: Node3D
var leg_right: Node3D
var camera: Camera3D
var world_root: Node3D
var sun_light: DirectionalLight3D
var world_environment: WorldEnvironment

var ui_layer: CanvasLayer
var menu_root: Control
var loading_root: Control
var hud_root: Control
var config_popup: PopupPanel
var loading_bar: ProgressBar
var loading_status: Label
var server_button: OptionButton
var server_status_label: Label
var hud_status_label: Label
var location_label: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var speed_label: Label
var mini_map: ColorRect
var mini_map_dot: ColorRect
var action_hint: Label

var buttons: Dictionary = {}
var held := {
	"forward": false,
	"back": false,
	"left": false,
	"right": false,
	"run": false,
	"crouch": false,
	"cam_left": false,
	"cam_right": false
}
var jump_request: bool = false
var camera_yaw: float = PI
var camera_pitch: float = -0.22
var camera_distance: float = 7.0
var walk_cycle: float = 0.0
var stamina: float = 100.0
var health: float = 100.0
var player_height_offset: float = 1.6
var current_location: String = "Bairro Lexus Central"

func _ready() -> void:
	_build_world()
	_build_player()
	_build_ui()
	_set_gameplay_visible(false)
	_show_loading_screen("Iniciando Cidade Lexus RP...")

func _process(delta: float) -> void:
	if app_state == AppState.LOADING_BOOT or app_state == AppState.LOADING_GAME:
		loading_progress += delta / loading_duration
		loading_bar.value = clamp(loading_progress * 100.0, 0.0, 100.0)
		loading_status.text = "Carregando sistemas... %d%%" % int(loading_bar.value)
		if loading_progress >= 1.0:
			if app_state == AppState.LOADING_BOOT:
				_show_menu()
			else:
				_start_gameplay()
	if app_state == AppState.PLAYING:
		_update_hud(delta)
		_update_minimap()

func _physics_process(delta: float) -> void:
	if app_state != AppState.PLAYING:
		return

	if held["cam_left"]:
		camera_yaw += delta * 1.7
	if held["cam_right"]:
		camera_yaw -= delta * 1.7

	var input_vec := Vector2.ZERO
	input_vec.x = float(held["right"]) - float(held["left"]) + Input.get_axis("ui_left", "ui_right")
	input_vec.y = float(held["back"]) - float(held["forward"]) + Input.get_axis("ui_up", "ui_down")
	input_vec = input_vec.limit_length(1.0)

	var forward := Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	var direction := (right * input_vec.x + forward * input_vec.y)
	direction.y = 0.0
	if direction.length() > 1.0:
		direction = direction.normalized()

	var crouching := held["crouch"]
	player_height_offset = lerpf(player_height_offset, 1.15 if crouching else 1.6, min(1.0, delta * 8.0))

	var target_speed := WALK_SPEED
	if crouching:
		target_speed = CROUCH_SPEED
	elif held["run"] and stamina > 1.0:
		target_speed = RUN_SPEED

	player.velocity.x = direction.x * target_speed
	player.velocity.z = direction.z * target_speed

	if player.is_on_floor():
		if jump_request:
			player.velocity.y = JUMP_FORCE
			jump_request = false
	else:
		player.velocity.y -= GRAVITY * delta
		jump_request = false

	player.move_and_slide()

	if direction.length() > 0.05:
		var target_yaw := atan2(-direction.x, -direction.z)
		player.rotation.y = lerp_angle(player.rotation.y, target_yaw, min(1.0, delta * 10.0))
		walk_cycle += delta * (10.5 if target_speed >= RUN_SPEED else 7.0)
	else:
		walk_cycle = lerpf(walk_cycle, 0.0, min(1.0, delta * 5.0))

	if target_speed >= RUN_SPEED and direction.length() > 0.1:
		stamina = max(0.0, stamina - delta * 16.0)
	else:
		stamina = min(100.0, stamina + delta * (11.0 if not crouching else 7.0))

	_animate_player(direction.length(), crouching)
	_update_camera(delta)
	_update_location_name()

func _build_world() -> void:
	world_root = Node3D.new()
	add_child(world_root)

	world_environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.63, 0.79, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.97, 1.0)
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.81, 0.91)
	env.fog_light_energy = 0.7
	env.fog_density = 0.0025
	world_environment.environment = env
	world_root.add_child(world_environment)

	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-42.0, -25.0, 0.0)
	sun_light.light_energy = 1.35
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_max_distance = 90.0
	world_root.add_child(sun_light)

	_add_box(world_root, Vector3(0, -0.5, 0), Vector3(260, 1, 260), Color(0.22, 0.54, 0.30), true)

	for x in [-48.0, 0.0, 48.0]:
		_add_box(world_root, Vector3(x, 0.02, 0), Vector3(14, 0.04, 240), Color(0.16, 0.17, 0.20), false)
		_build_lane_marks_vertical(x, 240.0)
		_build_sidewalks_vertical(x, 240.0)

	for z in [-72.0, -24.0, 24.0, 72.0]:
		_add_box(world_root, Vector3(0, 0.021, z), Vector3(240, 0.04, 14), Color(0.16, 0.17, 0.20), false)
		_build_lane_marks_horizontal(z, 240.0)
		_build_sidewalks_horizontal(z, 240.0)

	_build_blocks()
	_build_decorations()
	_apply_quality(1)

func _build_blocks() -> void:
	var lots := [
		Vector3(-90, 0, -100), Vector3(-66, 0, -100), Vector3(-20, 0, -100), Vector3(20, 0, -100), Vector3(66, 0, -100), Vector3(90, 0, -100),
		Vector3(-90, 0, -52), Vector3(-66, 0, -52), Vector3(-20, 0, -52), Vector3(20, 0, -52), Vector3(66, 0, -52), Vector3(90, 0, -52),
		Vector3(-90, 0, -4), Vector3(-66, 0, -4), Vector3(-20, 0, -4), Vector3(20, 0, -4), Vector3(66, 0, -4), Vector3(90, 0, -4),
		Vector3(-90, 0, 44), Vector3(-66, 0, 44), Vector3(-20, 0, 44), Vector3(20, 0, 44), Vector3(66, 0, 44), Vector3(90, 0, 44),
		Vector3(-90, 0, 92), Vector3(-66, 0, 92), Vector3(-20, 0, 92), Vector3(20, 0, 92), Vector3(66, 0, 92), Vector3(90, 0, 92)
	]
	for i in lots.size():
		_build_house_lot(lots[i], i)

func _build_house_lot(pos: Vector3, index: int) -> void:
	var body_color_a := [Color(0.83, 0.78, 0.69), Color(0.77, 0.74, 0.68), Color(0.78, 0.70, 0.63)]
	var roof_color_a := [Color(0.39, 0.15, 0.13), Color(0.31, 0.12, 0.11), Color(0.45, 0.21, 0.18)]
	var house_group := Node3D.new()
	house_group.position = pos
	world_root.add_child(house_group)

	var width := 12.0 + float(index % 2) * 2.0
	var depth := 10.0 + float(index % 3)
	var floors := 1 + int(index % 3 == 0)
	var height := 4.4 + floors * 2.2
	_add_box(house_group, Vector3(0, height * 0.5, 0), Vector3(width, height, depth), body_color_a[index % body_color_a.size()], true)
	_add_box(house_group, Vector3(0, height + 0.3, 0), Vector3(width + 0.8, 0.6, depth + 0.8), roof_color_a[index % roof_color_a.size()], false)
	_add_box(house_group, Vector3(0, 0.05, 0), Vector3(width + 4.0, 0.08, depth + 5.0), Color(0.54, 0.78, 0.56), false)

	for side in [-1, 1]:
		for row in range(floors + 1):
			var y := 1.5 + float(row) * 2.1
			_add_box(house_group, Vector3(side * (width * 0.22), y, depth * 0.51), Vector3(2.0, 1.2, 0.12), Color(0.40, 0.63, 0.84), false)
			_add_box(house_group, Vector3(side * (width * 0.22), y, -depth * 0.51), Vector3(2.0, 1.2, 0.12), Color(0.40, 0.63, 0.84), false)
	_add_box(house_group, Vector3(0, 1.2, depth * 0.515), Vector3(2.3, 2.4, 0.16), Color(0.32, 0.20, 0.10), false)

func _build_decorations() -> void:
	for x in [-60.0, -12.0, 36.0, 84.0]:
		for z in [-96.0, -48.0, 0.0, 48.0, 96.0]:
			_build_tree(Vector3(x, 0, z + 14.0))
	for x in [-54.0, -6.0, 42.0]:
		for z in [-84.0, -36.0, 12.0, 60.0]:
			_build_streetlight(Vector3(x, 0, z))
	for z in [-110.0, 110.0]:
		_add_box(world_root, Vector3(0, 0.15, z), Vector3(24, 0.3, 10), Color(0.18, 0.20, 0.24), false)

func _build_tree(pos: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = pos
	world_root.add_child(tree)
	_add_box(tree, Vector3(0, 1.8, 0), Vector3(0.5, 3.6, 0.5), Color(0.38, 0.23, 0.13), false)
	_add_box(tree, Vector3(0, 4.5, 0), Vector3(2.4, 1.6, 2.4), Color(0.17, 0.53, 0.20), false)
	_add_box(tree, Vector3(0, 5.6, 0), Vector3(1.8, 1.2, 1.8), Color(0.13, 0.42, 0.17), false)

func _build_streetlight(pos: Vector3) -> void:
	var pole := Node3D.new()
	pole.position = pos
	world_root.add_child(pole)
	_add_box(pole, Vector3(0, 3.0, 0), Vector3(0.18, 6.0, 0.18), Color(0.34, 0.34, 0.36), false)
	_add_box(pole, Vector3(0.5, 5.8, 0), Vector3(1.1, 0.14, 0.14), Color(0.34, 0.34, 0.36), false)
	_add_box(pole, Vector3(1.0, 5.55, 0), Vector3(0.4, 0.35, 0.4), Color(1.0, 0.94, 0.62), false)

func _build_lane_marks_vertical(x: float, road_length: float) -> void:
	for i in range(32):
		_add_box(world_root, Vector3(x, 0.05, -road_length * 0.45 + i * 7.0), Vector3(0.25, 0.02, 3.0), Color(0.96, 0.86, 0.44), false)

func _build_lane_marks_horizontal(z: float, road_length: float) -> void:
	for i in range(32):
		_add_box(world_root, Vector3(-road_length * 0.45 + i * 7.0, 0.05, z), Vector3(3.0, 0.02, 0.25), Color(0.96, 0.86, 0.44), false)

func _build_sidewalks_vertical(x: float, road_length: float) -> void:
	for side in [-1, 1]:
		_add_box(world_root, Vector3(x + side * 8.6, 0.09, 0), Vector3(3.0, 0.18, road_length), Color(0.72, 0.72, 0.70), false)

func _build_sidewalks_horizontal(z: float, road_length: float) -> void:
	for side in [-1, 1]:
		_add_box(world_root, Vector3(0, 0.09, z + side * 8.6), Vector3(road_length, 0.18, 3.0), Color(0.72, 0.72, 0.70), false)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1.4, 8)
	add_child(player)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.35
	collision.shape = capsule
	collision.position = Vector3(0, 0.95, 0)
	player.add_child(collision)

	player_visual = Node3D.new()
	player.add_child(player_visual)

	torso = Node3D.new()
	player_visual.add_child(torso)
	_add_box(torso, Vector3(0, 1.15, 0), Vector3(0.72, 1.0, 0.38), Color(0.11, 0.12, 0.14), false)
	_add_box(torso, Vector3(0, 0.45, 0), Vector3(0.64, 0.46, 0.34), Color(0.10, 0.10, 0.12), false)

	head = Node3D.new()
	player_visual.add_child(head)
	_add_box(head, Vector3(0, 1.95, 0), Vector3(0.48, 0.55, 0.42), Color(0.85, 0.74, 0.62), false)
	_add_box(head, Vector3(0, 2.28, 0), Vector3(0.52, 0.16, 0.44), Color(0.89, 0.91, 0.93), false)

	arm_left = Node3D.new()
	arm_left.position = Vector3(-0.5, 1.55, 0)
	player_visual.add_child(arm_left)
	_add_box(arm_left, Vector3(0, -0.45, 0), Vector3(0.20, 0.92, 0.20), Color(0.85, 0.74, 0.62), false)

	arm_right = Node3D.new()
	arm_right.position = Vector3(0.5, 1.55, 0)
	player_visual.add_child(arm_right)
	_add_box(arm_right, Vector3(0, -0.45, 0), Vector3(0.20, 0.92, 0.20), Color(0.85, 0.74, 0.62), false)

	leg_left = Node3D.new()
	leg_left.position = Vector3(-0.18, 0.86, 0)
	player_visual.add_child(leg_left)
	_add_box(leg_left, Vector3(0, -0.58, 0), Vector3(0.24, 1.12, 0.26), Color(0.08, 0.10, 0.15), false)

	leg_right = Node3D.new()
	leg_right.position = Vector3(0.18, 0.86, 0)
	player_visual.add_child(leg_right)
	_add_box(leg_right, Vector3(0, -0.58, 0), Vector3(0.24, 1.12, 0.26), Color(0.08, 0.10, 0.15), false)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 74.0
	add_child(camera)
	_update_camera(1.0)

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	menu_root = _create_menu_root()
	loading_root = _create_loading_root()
	hud_root = _create_hud_root()
	config_popup = _create_config_popup()
	ui_layer.add_child(menu_root)
	ui_layer.add_child(loading_root)
	ui_layer.add_child(hud_root)
	ui_layer.add_child(config_popup)
	get_viewport().size_changed.connect(_layout_game_buttons)
	_layout_game_buttons()

func _create_menu_root() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := _create_background_rect()
	root.add_child(bg)

	var left_panel := PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left_panel.position = Vector2(48, 54)
	left_panel.size = Vector2(500, 580)
	left_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.08, 0.16, 0.78), 24))
	root.add_child(left_panel)

	var left_content := VBoxContainer.new()
	left_content.position = Vector2(20, 18)
	left_content.size = Vector2(460, 540)
	left_panel.add_child(left_content)

	var brand := Label.new()
	brand.text = "CIDADE LEXUS RP"
	brand.add_theme_font_size_override("font_size", 18)
	left_content.add_child(brand)

	var title := Label.new()
	title.text = "ENTRAR NO JOGO"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 38)
	left_content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Launcher horizontal futurista. Escolha seu servidor, ajuste as configurações e toque em Jogar para entrar no mapa aberto."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 20)
	left_content.add_child(subtitle)

	left_content.add_spacer(false)

	var server_title := Label.new()
	server_title.text = "Servidor"
	server_title.add_theme_font_size_override("font_size", 18)
	left_content.add_child(server_title)

	server_button = OptionButton.new()
	server_button.custom_minimum_size = Vector2(420, 54)
	server_button.add_item("Cidade Lexus • Servidor 01")
	server_button.add_item("Cidade Lexus • Servidor 02")
	server_button.add_item("Cidade Lexus • Servidor Vip")
	server_button.item_selected.connect(_on_server_selected)
	left_content.add_child(server_button)

	var config_btn := Button.new()
	config_btn.text = "Configurações"
	config_btn.custom_minimum_size = Vector2(420, 58)
	config_btn.pressed.connect(_on_open_config)
	left_content.add_child(config_btn)

	var play_btn := Button.new()
	play_btn.text = "JOGAR"
	play_btn.custom_minimum_size = Vector2(420, 72)
	play_btn.add_theme_font_size_override("font_size", 28)
	play_btn.pressed.connect(_on_play_pressed)
	left_content.add_child(play_btn)

	server_status_label = Label.new()
	server_status_label.text = "Servidor selecionado: %s" % selected_server
	server_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_content.add_child(server_status_label)

	left_content.add_spacer(true)

	var footer := Label.new()
	footer.text = "Cidade Lexus RP • Protótipo V12\nTela de carregamento, escolha de servidor, HUD completo e mapa expandido."
	footer.add_theme_font_size_override("font_size", 15)
	left_content.add_child(footer)

	return root

func _create_loading_root() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := _create_background_rect()
	root.add_child(bg)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.04, 0.08, 0.62)
	root.add_child(overlay)

	var center_panel := PanelContainer.new()
	center_panel.custom_minimum_size = Vector2(620, 250)
	center_panel.position = Vector2(330, 220)
	center_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.06, 0.12, 0.84), 26))
	root.add_child(center_panel)

	var vb := VBoxContainer.new()
	vb.position = Vector2(24, 22)
	vb.size = Vector2(572, 196)
	center_panel.add_child(vb)

	var title := Label.new()
	title.text = "CIDADE LEXUS RP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vb.add_child(title)

	loading_status = Label.new()
	loading_status.text = "Carregando..."
	loading_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_status.add_theme_font_size_override("font_size", 20)
	vb.add_child(loading_status)

	loading_bar = ProgressBar.new()
	loading_bar.min_value = 0.0
	loading_bar.max_value = 100.0
	loading_bar.value = 0.0
	loading_bar.custom_minimum_size = Vector2(540, 34)
	vb.add_child(loading_bar)

	var hint := Label.new()
	hint.text = "Aguarde a preparação do servidor, do mapa e do HUD futurista."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)

	return root

func _create_hud_root() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var top_card := PanelContainer.new()
	top_card.position = Vector2(22, 18)
	top_card.size = Vector2(350, 150)
	top_card.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.06, 0.12, 0.76), 22))
	root.add_child(top_card)

	var top_vb := VBoxContainer.new()
	top_vb.position = Vector2(16, 12)
	top_vb.size = Vector2(320, 124)
	top_card.add_child(top_vb)

	var title := Label.new()
	title.text = "CIDADE LEXUS RP"
	title.add_theme_font_size_override("font_size", 22)
	top_vb.add_child(title)

	hud_status_label = Label.new()
	hud_status_label.text = selected_server
	top_vb.add_child(hud_status_label)

	location_label = Label.new()
	location_label.text = current_location
	location_label.add_theme_font_size_override("font_size", 16)
	top_vb.add_child(location_label)

	var bars_row := HBoxContainer.new()
	top_vb.add_child(bars_row)

	var health_box := VBoxContainer.new()
	bars_row.add_child(health_box)
	var health_label := Label.new()
	health_label.text = "VIDA"
	health_box.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(145, 18)
	health_bar.max_value = 100
	health_bar.value = health
	health_box.add_child(health_bar)

	var stamina_box := VBoxContainer.new()
	bars_row.add_child(stamina_box)
	var stamina_label := Label.new()
	stamina_label.text = "STAMINA"
	stamina_box.add_child(stamina_label)
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(145, 18)
	stamina_bar.max_value = 100
	stamina_bar.value = stamina
	stamina_box.add_child(stamina_bar)

	speed_label = Label.new()
	speed_label.text = "Modo: Andando"
	top_vb.add_child(speed_label)

	mini_map = ColorRect.new()
	mini_map.position = Vector2(1110, 18)
	mini_map.custom_minimum_size = Vector2(170, 170)
	mini_map.size = Vector2(170, 170)
	mini_map.color = Color(0.05, 0.10, 0.16, 0.85)
	root.add_child(mini_map)
	var map_label := Label.new()
	map_label.text = "MINI MAPA"
	map_label.position = Vector2(18, 10)
	mini_map.add_child(map_label)
	var map_streets := ColorRect.new()
	map_streets.position = Vector2(16, 34)
	map_streets.size = Vector2(138, 118)
	map_streets.color = Color(0.17, 0.25, 0.18, 1.0)
	mini_map.add_child(map_streets)
	for line_data in [Rect2(66, 0, 8, 118), Rect2(0, 55, 138, 8), Rect2(24, 0, 8, 118), Rect2(106, 0, 8, 118), Rect2(0, 23, 138, 8), Rect2(0, 87, 138, 8)]:
		var road := ColorRect.new()
		road.position = Vector2(line_data.position.x, line_data.position.y) + map_streets.position
		road.size = line_data.size
		road.color = Color(0.52, 0.52, 0.55, 1.0)
		mini_map.add_child(road)
	mini_map_dot = ColorRect.new()
	mini_map_dot.size = Vector2(8, 8)
	mini_map_dot.color = Color(1.0, 0.18, 0.18, 1.0)
	mini_map.add_child(mini_map_dot)

	action_hint = Label.new()
	action_hint.position = Vector2(950, 195)
	action_hint.size = Vector2(330, 36)
	action_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	action_hint.text = "Câmera: girar | Movimento: correr, pular e agachar"
	root.add_child(action_hint)

	var keys := {
		"forward": {"text": "▲", "size": Vector2(74, 68)},
		"back": {"text": "▼", "size": Vector2(74, 68)},
		"left": {"text": "◀", "size": Vector2(74, 68)},
		"right": {"text": "▶", "size": Vector2(74, 68)},
		"run": {"text": "CORRER", "size": Vector2(110, 68)},
		"jump": {"text": "PULAR", "size": Vector2(110, 68)},
		"crouch": {"text": "AGACHAR", "size": Vector2(120, 68)},
		"cam_left": {"text": "CAM ◀", "size": Vector2(98, 60)},
		"cam_right": {"text": "CAM ▶", "size": Vector2(98, 60)}
	}
	for key in keys.keys():
		var btn := Button.new()
		btn.text = keys[key]["text"]
		btn.custom_minimum_size = keys[key]["size"]
		btn.add_theme_font_size_override("font_size", 17)
		root.add_child(btn)
		buttons[key] = btn
		if key == "jump":
			btn.button_down.connect(_on_jump_button)
		elif key in ["forward", "back", "left", "right", "run", "crouch", "cam_left", "cam_right"]:
			btn.button_down.connect(_set_hold.bind(key, true))
			btn.button_up.connect(_set_hold.bind(key, false))

	return root

func _create_config_popup() -> PopupPanel:
	var popup := PopupPanel.new()
	popup.title = "Configurações"
	popup.size = Vector2i(440, 310)
	var root := VBoxContainer.new()
	root.position = Vector2(18, 18)
	root.size = Vector2(400, 260)
	popup.add_child(root)

	var title := Label.new()
	title.text = "Configurações do APK"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Selecione a qualidade gráfica e deixe o jogo mais leve ou mais bonito."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subtitle)

	var quality_title := Label.new()
	quality_title.text = "Qualidade gráfica"
	root.add_child(quality_title)

	var quality_option := OptionButton.new()
	quality_option.add_item("Baixa")
	quality_option.add_item("Média")
	quality_option.add_item("Alta")
	quality_option.selected = current_quality
	quality_option.item_selected.connect(_on_quality_selected)
	root.add_child(quality_option)

	var info := Label.new()
	info.text = "Servidor, carregamento futurista, botão Jogar e HUD completo já estão ativos nesta build."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(info)

	var close_btn := Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(180, 46)
	close_btn.pressed.connect(func(): config_popup.hide())
	root.add_child(close_btn)

	return popup

func _create_background_rect() -> TextureRect:
	var tex_rect := TextureRect.new()
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/background_ui_v12.png"):
		tex_rect.texture = load("res://assets/background_ui_v12.png")
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.04, 0.08, 0.22)
	tex_rect.add_child(overlay)
	return tex_rect

func _panel_style(color: Color, radius: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.38, 0.59, 1.0, 0.24)
	return style

func _show_loading_screen(text: String) -> void:
	menu_root.visible = false
	hud_root.visible = false
	loading_root.visible = true
	loading_status.text = text
	loading_progress = 0.0
	loading_bar.value = 0.0

func _show_menu() -> void:
	app_state = AppState.MENU
	loading_root.visible = false
	hud_root.visible = false
	menu_root.visible = true
	_set_gameplay_visible(false)

func _start_gameplay() -> void:
	app_state = AppState.PLAYING
	loading_root.visible = false
	menu_root.visible = false
	hud_root.visible = true
	_set_gameplay_visible(true)
	player.position = Vector3(0, 1.4, 8)
	camera_yaw = PI
	stamina = 100.0
	health = 100.0
	hud_status_label.text = selected_server

func _set_gameplay_visible(value: bool) -> void:
	world_root.visible = value
	player.visible = value
	camera.current = value

func _layout_game_buttons() -> void:
	if buttons.is_empty():
		return
	var size := get_viewport().get_visible_rect().size
	buttons["forward"].position = Vector2(118, size.y - 208)
	buttons["back"].position = Vector2(118, size.y - 100)
	buttons["left"].position = Vector2(32, size.y - 154)
	buttons["right"].position = Vector2(204, size.y - 154)
	buttons["run"].position = Vector2(size.x - 376, size.y - 110)
	buttons["jump"].position = Vector2(size.x - 254, size.y - 188)
	buttons["crouch"].position = Vector2(size.x - 136, size.y - 110)
	buttons["cam_left"].position = Vector2(size.x - 276, size.y - 286)
	buttons["cam_right"].position = Vector2(size.x - 164, size.y - 286)
	mini_map.position = Vector2(size.x - 190, 18)
	action_hint.position = Vector2(size.x - 420, 194)

func _on_play_pressed() -> void:
	app_state = AppState.LOADING_GAME
	_show_loading_screen("Conectando ao servidor e carregando o mapa...")

func _on_open_config() -> void:
	config_popup.popup_centered(Vector2i(440, 310))

func _on_server_selected(index: int) -> void:
	selected_server = server_button.get_item_text(index)
	server_status_label.text = "Servidor selecionado: %s" % selected_server
	if hud_status_label:
		hud_status_label.text = selected_server

func _on_quality_selected(index: int) -> void:
	current_quality = index
	_apply_quality(index)

func _apply_quality(index: int) -> void:
	if world_environment == null or world_environment.environment == null or sun_light == null:
		return
	var env := world_environment.environment
	match index:
		0:
			sun_light.light_energy = 1.10
			sun_light.shadow_enabled = false
			env.fog_density = 0.002
		1:
			sun_light.light_energy = 1.25
			sun_light.shadow_enabled = true
			sun_light.directional_shadow_max_distance = 70.0
			env.fog_density = 0.0025
		2:
			sun_light.light_energy = 1.45
			sun_light.shadow_enabled = true
			sun_light.directional_shadow_max_distance = 110.0
			env.fog_density = 0.0019

func _set_hold(key: String, value: bool) -> void:
	held[key] = value

func _on_jump_button() -> void:
	jump_request = true

func _animate_player(move_amount: float, crouching: bool) -> void:
	var swing := sin(walk_cycle) * 0.75 * move_amount
	arm_left.rotation.x = swing
	arm_right.rotation.x = -swing
	leg_left.rotation.x = -swing
	leg_right.rotation.x = swing
	player_visual.position.y = lerpf(player_visual.position.y, -0.32 if crouching else 0.0, 0.25)
	head.position.y = lerpf(head.position.y, 1.72 if crouching else 0.0, 0.18)

func _update_camera(delta: float) -> void:
	var target := player.global_position + Vector3(0, player_height_offset, 0)
	var cam_dir := Vector3(sin(camera_yaw) * cos(camera_pitch), sin(camera_pitch), cos(camera_yaw) * cos(camera_pitch))
	var desired := target + cam_dir * camera_distance
	camera.global_position = camera.global_position.lerp(desired, min(1.0, delta * 8.0))
	camera.look_at(target, Vector3.UP)

func _update_hud(delta: float) -> void:
	health_bar.value = health
	stamina_bar.value = stamina
	location_label.text = current_location
	var mode := "Andando"
	if held["crouch"]:
		mode = "Agachado"
	elif held["run"] and stamina > 1.0:
		mode = "Correndo"
	speed_label.text = "Modo: %s | X: %.0f  Z: %.0f" % [mode, player.global_position.x, player.global_position.z]
	action_hint.modulate.a = 0.78 + sin(Time.get_ticks_msec() / 350.0) * 0.08

func _update_minimap() -> void:
	var panel_pos := Vector2(16, 34)
	var panel_size := Vector2(138, 118)
	var nx := clamp((player.global_position.x / MAP_LIMIT) * 0.5 + 0.5, 0.0, 1.0)
	var nz := clamp((player.global_position.z / MAP_LIMIT) * 0.5 + 0.5, 0.0, 1.0)
	mini_map_dot.position = panel_pos + Vector2(nx * (panel_size.x - 8.0), nz * (panel_size.y - 8.0))

func _update_location_name() -> void:
	var x := player.global_position.x
	var z := player.global_position.z
	if z < -60.0:
		current_location = "Avenida Norte"
	elif z > 60.0:
		current_location = "Bairro Sul Aberto"
	elif abs(x) < 18.0:
		current_location = "Centro Lexus"
	elif x < 0.0:
		current_location = "Vilas do Oeste"
	else:
		current_location = "Zona Leste"

func _add_box(parent: Node, pos: Vector3, size: Vector3, color: Color, collision: bool = true) -> Node3D:
	var holder: Node3D
	if collision:
		holder = StaticBody3D.new()
	else:
		holder = Node3D.new()
	holder.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh_instance.material_override = material
	holder.add_child(mesh_instance)
	if collision:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		holder.add_child(col)
	parent.add_child(holder)
	return holder
