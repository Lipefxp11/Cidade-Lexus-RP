extends Node3D

# CIDADE LEXUS RP V16 — gameplay e input revisados / demo offline.
# Gameplay remains local until an authoritative multiplayer backend exists.
const WorldScript = preload("res://scripts/city_world.gd")
const PlayerScript = preload("res://scripts/lexus_player.gd")
const VehicleScript = preload("res://scripts/lexus_vehicle.gd")
const NPCScript = preload("res://scripts/lexus_npc.gd")
const UIScript = preload("res://scripts/lexus_ui.gd")
const ConfigPath = "user://lexus_v13.cfg"
const VoiceScript = preload("res://scripts/lexus_voice.gd")
const VOICE_SERVER_URL = "" # ex.: wss://seu-servidor-de-voz.example"

enum GameState { BOOT, MENU, LOADING, PLAYING, DEAD }

var state: int = GameState.BOOT
var game_root: Node3D
var world_built := false
var world_build_queued := false
var ready_for_play := false
var city
var player
var ui
var camera: Camera3D
var cars: Array = []
var npcs: Array = []
var active_car
var camera_yaw: float = 0.0
var camera_pitch: float = 0.0
var camera_distance: float = 3.55
var camera_shoulder: float = 0.50
var camera_collision_query: PhysicsRayQueryParameters3D
var fire_held := false
var weapon_recoil := 0.0
var session_hour := 12.0
var voice
var staff_demo := false
var voice_server_url := VOICE_SERVER_URL
var shot_player: AudioStreamPlayer
var reload_player: AudioStreamPlayer
var camera_sensitivity: float = 1.0
var free_camera_touch_id: int = -1
var mouse_look := false
var joystick_vector := Vector2.ZERO
var is_crouched := false
var run_enabled := false
var shoot_cooldown := 0.0
var shot_requested := false
var reload_time := 0.0
var ammo_in_clip: int = 12
var reserve_ammo: int = 60
var money: int = 500
var bank_money: int = 0
var medkits: int = 2
var armour: float = 25.0
var points: int = 0
var eliminations: int = 0
var deaths: int = 0
var job_active := false
var job_status: String = "TRABALHO DISPONÍVEL"
var quality_level := 1
var loading_progress := 0.0
var status_label := "Iniciando sistemas"
var hud_tick := 0.0
var setting_save_timer := 0.0

func _ready() -> void:
	# Android UI buttons depend on mouse-from-touch input emulation.
	Input.emulate_mouse_from_touch = true
	# Force portrait-locked Android phones to use landscape while our APK is active.
	if OS.get_name() == "Android":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	_load_profile()
	ui = UIScript.new()
	add_child(ui)
	ui.play_pressed.connect(_on_play_pressed)
	ui.action_pressed.connect(_on_ui_action)
	ui.move_changed.connect(_on_move_changed)
	ui.command_entered.connect(_on_chat_command)
	ui.quality_changed.connect(_on_quality_changed)
	ui.sensitivity_changed.connect(_on_sensitivity_changed)
	ui.voice_url_changed.connect(_on_voice_url_changed)
	ui.update_settings(quality_level, camera_sensitivity)
	ui.update_voice_url(voice_server_url)
	ui.set_screen("loading")
	voice = VoiceScript.new()
	voice.name = "VozExperimental"
	add_child(voice)
	voice.status_changed.connect(_on_voice_status)
	state = GameState.BOOT
	loading_progress = 0.0
	status_label = "Preparando Cidade Lexus RP"
	ui.set_loading(0, status_label)

func _make_game_world() -> void:
	game_root = Node3D.new()
	game_root.name = "MundoLexus"
	add_child(game_root)
	city = WorldScript.new()
	city.name = "CidadeAberta"
	game_root.add_child(city)

	player = PlayerScript.new()
	player.name = "PersonagemLocal"
	player.position = Vector3(0, 0.15, 12)
	game_root.add_child(player)

	var car_spawns := [
		{ "name": "Sedan Preto", "pos": Vector3(14, 0.12, 17), "color": Color(0.13, 0.15, 0.19)},
		{ "name": "Hatch Vermelho", "pos": Vector3(-10, 0.12, 22), "color": Color(0.65, 0.08, 0.10)},
		{ "name": "SUV Cinza", "pos": Vector3(71, 0.12, 17), "color": Color(0.37, 0.40, 0.44)}
	]
	for entry in car_spawns:
		var car = VehicleScript.new()
		car.car_name = entry["name"]
		car.paint_color = entry["color"]
		car.position = entry["pos"]
		game_root.add_child(car)
		cars.append(car)

	for pos in [Vector3(0, 0.2, -44), Vector3(60, 0.2, -70), Vector3(-60, 0.2, 74), Vector3(120, 0.2, 105)]:
		var bot = NPCScript.new()
		bot.position = pos
		game_root.add_child(bot)
		npcs.append(bot)

	camera = Camera3D.new()
	camera.fov = 67.0
	camera.current = true
	game_root.add_child(camera)
	camera.global_position = Vector3(0.5, 2.6, 15.0)
	camera.look_at(player.global_position + Vector3(0, 1.45, 0), Vector3.UP)
	city.set_quality(quality_level)
	city.set_time(session_hour)
	shot_player = AudioStreamPlayer.new()
	shot_player.stream = load("res://assets/audio/disparo_demo.wav")
	shot_player.volume_db = -7.0
	game_root.add_child(shot_player)
	reload_player = AudioStreamPlayer.new()
	reload_player.stream = load("res://assets/audio/recarga_demo.wav")
	reload_player.volume_db = -8.0
	game_root.add_child(reload_player)


func _finish_world_load() -> void:
	if state != GameState.LOADING or ready_for_play:
		return
	if not world_built:
		_make_game_world()
		world_built = true
		_set_game_world_visible(false)
	ready_for_play = true

func _process(delta: float) -> void:
	# The menu is always shown first. Never build the 3D city during app startup.
	if state == GameState.BOOT:
		loading_progress = minf(100.0, loading_progress + delta * 115.0)
		ui.set_loading(loading_progress, "Preparando menu e controles")
		if loading_progress >= 100.0:
			state = GameState.MENU
			ui.set_screen("menu")
		return
	if state == GameState.LOADING:
		loading_progress = minf(90.0, loading_progress + delta * 25.0)
		ui.set_loading(loading_progress, status_label)
		if loading_progress >= 30.0 and not world_build_queued:
			world_build_queued = true
			status_label = "Carregando cidade e veículos..."
			# Deferred so the loading screen can render before the heavy scene is built.
			call_deferred("_finish_world_load")
		if ready_for_play and loading_progress >= 90.0:
			ui.set_loading(100.0, "Pronto para jogar")
			_start_playing()
		return

	if state != GameState.PLAYING:
		return

	weapon_recoil = maxf(0.0, weapon_recoil - delta * 5.0)
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	if reload_time > 0:
		reload_time -= delta
		if reload_time <= 0:
			_finish_reload()

	if active_car != null:
		player.global_position = active_car.global_position
	else:
		player.set_look_yaw(camera_yaw)
		player.input_direction = _get_move_input()
		player.run_held = run_enabled
		player.crouch_held = is_crouched
		player.aim_held = fire_held or weapon_recoil > 0.05

	if player.is_dead:
		return
	for npc in npcs:
		var npc_damage: float = npc.simulate(delta, player.global_position, not player.is_dead, active_car != null)
		if npc_damage > 0.0:
			_damage_player(npc_damage)
	_update_camera(delta)

	hud_tick -= delta
	if hud_tick <= 0:
		hud_tick = 0.10
		_refresh_hud()

	setting_save_timer += delta
	if setting_save_timer >= 20.0:
		setting_save_timer = 0.0
		_save_profile()

func _physics_process(delta: float) -> void:
	if state != GameState.PLAYING:
		return
	if active_car != null:
		var move := _get_move_input()
		active_car.throttle = -move.y
		active_car.steer = move.x
		player.global_position = active_car.global_position
		if active_car.fuel <= 0:
			active_car.engine_on = false
	elif (fire_held or shot_requested) and shoot_cooldown <= 0.0:
		_fire_weapon()
	shot_requested = false

func _unhandled_input(event: InputEvent) -> void:
	if state != GameState.PLAYING:
		return

	# RIGHT SIDE SWIPE = GTA-style 360 degree free camera, no camera buttons.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and free_camera_touch_id == -1 and touch.position.x > get_viewport().get_visible_rect().size.x * 0.42:
			free_camera_touch_id = touch.index
		elif not touch.pressed and touch.index == free_camera_touch_id:
			free_camera_touch_id = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == free_camera_touch_id:
			_move_camera(drag.relative)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			mouse_look = mb.pressed
	elif event is InputEventMouseMotion and mouse_look:
		var mm := event as InputEventMouseMotion
		_move_camera(mm.relative)

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed and key_event.keycode == KEY_Q:
			fire_held = false
		if key_event.pressed and not key_event.echo:
			match key_event.keycode:
				KEY_SPACE:
					if active_car == null:
						player.jump_request = true
				KEY_SHIFT:
					run_enabled = not run_enabled
				KEY_C:
					is_crouched = not is_crouched
				KEY_F:
					_interact()
				KEY_R:
					_start_reload()
				KEY_M:
					_show_inventory()
				KEY_T:
					ui.open_chat()
				KEY_ESCAPE:
					_open_menu()
				KEY_Q:
					fire_held = true

func _move_camera(relative: Vector2) -> void:
	camera_yaw -= relative.x * camera_sensitivity * 0.0048
	camera_pitch = clampf(camera_pitch + relative.y * camera_sensitivity * 0.0038, -0.63, 0.68)

func _get_move_input() -> Vector2:
	var keyboard := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		keyboard.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		keyboard.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard.x += 1.0
	return (keyboard + joystick_vector).limit_length(1.0)

func _update_camera(delta: float) -> void:
	var target: Vector3
	if active_car != null:
		target = active_car.global_position + Vector3(0, 1.55, 0)
	else:
		target = player.global_position + Vector3(0, 1.45 if not is_crouched else 1.12, 0)
	# Camera like GTA SA: shoulder slightly right, 3.55m behind player.
	var d := 5.05 if active_car != null else camera_distance
	var behind := Vector3(sin(camera_yaw), 0.0, cos(camera_yaw))
	var shoulder := Vector3(cos(camera_yaw), 0, -sin(camera_yaw)) * (0.0 if active_car != null else camera_shoulder)
	var desired := target + behind * d + shoulder + Vector3(0, 0.55 + camera_pitch * 2.6 + weapon_recoil * 0.14, 0)
	# Camera collision prevents walls from hiding the character.
	var space := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.from = target
	ray.to = desired
	ray.collision_mask = 1 | 4
	var hit := space.intersect_ray(ray)
	if not hit.is_empty():
		desired = (hit["position"] as Vector3) + (target - (hit["position"] as Vector3)).normalized() * 0.35
	var t := clampf(delta * 9.0, 0.0, 1.0)
	camera.global_position = camera.global_position.lerp(desired, t)
	if camera.global_position.distance_to(target) > 0.05:
		var forward := Vector3(-sin(camera_yaw), 0, -cos(camera_yaw))
		var aim_point := target + forward * 26.0 + Vector3(0, camera_pitch * -7.0, 0)
		camera.look_at(aim_point, Vector3.UP)

func _on_play_pressed() -> void:
	if state != GameState.MENU:
		return
	loading_progress = 0.0
	world_build_queued = false
	ready_for_play = world_built
	status_label = "Carregando bairro e sistemas offline"
	ui.set_screen("loading")
	state = GameState.LOADING

func _start_playing() -> void:
	if game_root == null:
		push_error("Cidade Lexus: mundo indisponível. Retornando ao menu.")
		state = GameState.MENU
		ui.set_screen("menu")
		return
	state = GameState.PLAYING
	_set_game_world_visible(true)
	ui.set_screen("game")
	ui.show_toast("Cidade Lexus RP V16 • DEMO OFFLINE")
	_refresh_hud()

func _set_game_world_visible(value: bool) -> void:
	game_root.visible = value
	if camera != null:
		camera.current = value

func _on_move_changed(value: Vector2) -> void:
	joystick_vector = value

func _on_ui_action(action: String) -> void:
	match action:
		"PLAY":
			_on_play_pressed()
		"SETTINGS":
			ui.open_settings()
		"CLOSE_SETTINGS":
			ui.close_settings()
		"MENU":
			_open_menu()
		"RUN":
			if active_car == null:
				run_enabled = not run_enabled
				ui.show_toast("Corrida %s" % ("ativada" if run_enabled else "desativada"))
		"JUMP":
			if active_car == null:
				player.jump_request = true
		"CROUCH":
			if active_car == null:
				is_crouched = not is_crouched
		"FIRE":
			shot_requested = true
		"FIRE_DOWN":
			fire_held = true
			shot_requested = true
		"FIRE_UP":
			fire_held = false
		"VOICE_DOWN":
			voice.start_transmission()
		"VOICE_UP":
			voice.stop_transmission()
		"VOICE_CONNECT":
			_toggle_voice()
		"RELOAD":
			_start_reload()
		"INTERACT":
			_interact()
		"ITEMS":
			_show_inventory()
		"CLOSE_INFO":
			ui.close_info()
		"CHAT":
			ui.open_chat()
		"REVIVE":
			_revive_player()

func _on_quality_changed(level: int) -> void:
	quality_level = clampi(level, 0, 2)
	if city != null:
		city.set_quality(quality_level)
	_save_profile()

func _on_sensitivity_changed(value: float) -> void:
	camera_sensitivity = clampf(value, 0.5, 2.4)
	_save_profile()

func _open_menu() -> void:
	if state != GameState.PLAYING:
		return
	if active_car != null:
		active_car.throttle = 0.0
	free_camera_touch_id = -1
	joystick_vector = Vector2.ZERO
	shot_requested = false
	fire_held = false
	voice.stop_transmission()
	state = GameState.MENU
	_set_game_world_visible(false)
	ui.set_screen("menu")
	_save_profile()

func _interact() -> void:
	if state != GameState.PLAYING:
		return
	if active_car != null:
		_exit_car()
		return
	var nearest_car = null
	var nearest_dist := 4.5
	for car in cars:
		var distance: float = player.global_position.distance_to(car.global_position)
		if distance < nearest_dist and not car.occupied():
			nearest_car = car
			nearest_dist = distance
	if nearest_car != null:
		_enter_car(nearest_car)
		return
	if player.global_position.distance_to(Vector3(9, 0, -15)) < 8.0 and not job_active:
		job_active = true
		job_status = "ENTREGA: DESTINO ZONA LESTE"
		ui.show_toast("Encomenda recebida! Leve até o ponto X=120 Z=60.")
		_save_profile()
		return
	if job_active and player.global_position.distance_to(Vector3(120, 0, 60)) < 12.0:
		job_active = false
		job_status = "TRABALHO DISPONÍVEL"
		money += 350
		points += 25
		ui.show_toast("Entrega concluída • +R$ 350 • +25 XP")
		_save_profile()
		return
	ui.show_toast("Nada para interagir aqui. Aproxime-se de um carro ou entrega.")

func _enter_car(car) -> void:
	active_car = car
	fire_held = false
	shot_requested = false
	active_car.driver_inside = true
	active_car.engine_on = true
	player.enter_vehicle()
	player.input_direction = Vector2.ZERO
	camera_yaw = active_car.rotation.y
	ui.show_toast("%s • Joystick dirige, USAR sai do veículo" % active_car.car_name)

func _exit_car() -> void:
	if active_car == null:
		return
	var former_car = active_car
	former_car.driver_inside = false
	former_car.throttle = 0.0
	former_car.steer = 0.0
	active_car = null
	var drop: Vector3 = former_car.global_position + former_car.global_transform.basis.x * 2.2 + Vector3(0, 0.3, 0)
	player.exit_vehicle(drop)
	ui.show_toast("Você saiu do veículo")

func _fire_weapon() -> void:
	if state != GameState.PLAYING or active_car != null or player.is_dead:
		return
	if shoot_cooldown > 0.0 or reload_time > 0.0:
		return
	if ammo_in_clip <= 0:
		shoot_cooldown = 0.60
		ui.show_toast("Pente vazio • Toque em RECARGA")
		return
	shoot_cooldown = 0.23
	ammo_in_clip -= 1
	weapon_recoil = 1.0
	player.play_shoot_recoil()
	_spawn_muzzle_flash()
	if shot_player != null:
		shot_player.play()
	# Aim ray starts at the actual screen center, not at the shoulder.
	var origin := camera.project_ray_origin(get_viewport().get_visible_rect().size * 0.5)
	var target := origin + camera.project_ray_normal(get_viewport().get_visible_rect().size * 0.5) * 85.0
	var query := PhysicsRayQueryParameters3D.new()
	query.from = origin
	query.to = target
	query.exclude = [player.get_rid()]
	query.collision_mask = 1 | 4 | 8
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var endpoint := target
	if not result.is_empty():
		endpoint = result["position"]
	_spawn_tracer(player.global_position + Vector3(0, 1.35, 0), endpoint)
	ui.flash_reticle(not result.is_empty())
	if not result.is_empty():
		var collider = result.get("collider")
		if collider != null and npcs.has(collider):
			var killed: bool = collider.take_hit(34.0)
			if killed:
				eliminations += 1
				points += 10
				money += 40
				ui.show_toast("ALVO DERRUBADO • +10 XP • +R$ 40")
				_save_profile()
			else:
				ui.show_toast("ACERTO CONFIRMADO")
	if ammo_in_clip == 0 and reserve_ammo > 0:
		ui.show_toast("Sem munição no pente • Recarregue")

func _spawn_tracer(start_point: Vector3, end_point: Vector3) -> void:
	var diff := end_point - start_point
	var length := diff.length()
	if length <= 0.01:
		return
	var effect := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.014
	mesh.bottom_radius = 0.014
	mesh.height = length
	effect.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.78, 0.24)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	effect.material_override = material
	effect.position = (start_point + end_point) * 0.5
	effect.quaternion = Quaternion(Vector3.UP, diff.normalized())
	game_root.add_child(effect)
	get_tree().create_timer(0.07).timeout.connect(effect.queue_free)

func _spawn_muzzle_flash() -> void:
	# Short flash at hand position; cosmetic only, with no physics collision.
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.69, 0.20)
	flash.light_energy = 1.8
	flash.omni_range = 3.0
	flash.shadow_enabled = false
	flash.position = player.global_position + Vector3(0, 1.37, 0) - player.global_transform.basis.z * 0.3 + player.global_transform.basis.x * 0.22
	game_root.add_child(flash)
	get_tree().create_timer(0.045).timeout.connect(flash.queue_free)

func _start_reload() -> void:
	if state != GameState.PLAYING or active_car != null or player.is_dead:
		return
	if reload_time > 0.0 or ammo_in_clip >= 12 or reserve_ammo <= 0:
		return
	reload_time = 1.8
	if reload_player != null:
		reload_player.play()
	ui.show_toast("Recarregando arma...")

func _finish_reload() -> void:
	var to_load := mini(12 - ammo_in_clip, reserve_ammo)
	reserve_ammo -= to_load
	ammo_in_clip += to_load
	ui.show_toast("Arma recarregada")

func _damage_player(amount: float) -> void:
	if player.is_dead:
		return
	var remaining := amount
	if armour > 0:
		var absorbed := minf(armour, remaining * 0.7)
		armour -= absorbed
		remaining -= absorbed
	if player.receive_damage(remaining):
		state = GameState.DEAD
		deaths += 1
		fire_held = false
		shot_requested = false
		voice.stop_transmission()
		ui.show_death()
		ui.show_toast("Você foi incapacitado")
		_save_profile()

func _revive_player() -> void:
	if state != GameState.DEAD:
		return
	if active_car != null:
		_exit_car()
	player.revive()
	armour = 0.0
	is_crouched = false
	run_enabled = false
	fire_held = false
	shot_requested = false
	state = GameState.PLAYING
	ui.hide_death()
	ui.show_toast("Atendimento concluído • Revivido no hospital")
	_save_profile()

func _show_inventory() -> void:
	if state != GameState.PLAYING:
		return
	var info := "IDENTIDADE: LEXUS URBANO 01\nDINHEIRO: R$ %d\nBANCO: R$ %d\nPISTOLA: 12 TIROS POR PENTE\nMUNIÇÃO: %d / %d\nKITS MÉDICOS: %d\nVIDA: %d\nCOLETE: %d\nELIMINAÇÕES: %d\nMORTES: %d\nEXPERIÊNCIA: %d XP\n\nTRABALHO: %s\n\nComandos RP: /ajuda, /rg, /saldo, /gps, /trabalho, /curar, /comprarmunicao" % [money, bank_money, ammo_in_clip, reserve_ammo, medkits, int(player.health), int(armour), eliminations, deaths, points, job_status]
	ui.open_info(info)

func _on_chat_command(line: String) -> void:
	if state != GameState.PLAYING:
		return
	var command := line.to_lower().strip_edges()
	match command:
		"/ajuda":
			ui.open_info("COMANDOS RP LOCAL\n/rg /saldo /inventario /gps /trabalho\n/curar /comprarmunicao /recarregar /carro\n/staffhelp /voz\n\nCÂMERA: arraste na região livre da direita.\nATIRAR: segure o botão. USAR: entrar/sair do carro.\n\nOffline: nenhum privilégio no servidor.")
		"/rg":
			ui.open_info("REGISTRO GERAL\nNome: Lexus Urbano 01\nCidade: Cidade Lexus RP\nOcupação: Trabalhador\nNível: %d\nMultiplayer: NÃO CONECTADO" % int(points / 100 + 1))
		"/saldo":
			ui.show_toast("CARTEIRA: R$ %d | BANCO: R$ %d" % [money, bank_money])
		"/inventario", "/mochila":
			_show_inventory()
		"/gps":
			ui.show_toast("GPS: ENTREGA X=120 Z=60 • GARAGEM X=14 Z=17")
		"/trabalho":
			ui.show_toast("Encomenda: vá até X=9 Z=-15 e toque em USAR")
		"/carro":
			ui.show_toast("Garagem: há veículos em X=14 Z=17, X=-10 Z=22")
		"/recarregar":
			_start_reload()
		"/curar":
			if medkits > 0 and player.health < 100:
				medkits -= 1
				player.heal(55)
				ui.show_toast("Kit médico usado • VIDA RECUPERADA")
				_save_profile()
			else:
				ui.show_toast("Não precisa curar ou não possui kits médicos")
		"/comprarmunicao":
			if money >= 50:
				money -= 50
				reserve_ammo += 24
				ui.show_toast("Comprou 24 munições por R$ 50")
				_save_profile()
			else:
				ui.show_toast("Saldo insuficiente: precisa de R$ 50")
		"/staffhelp":
			ui.open_info("STAFF LOCAL — SOMENTE TESTES OFFLINE\n/staffmodo\n/staffcurar\n/stafftp X Z\n/staffcarro\n/staffhora HH\n\nNo futuro, comandos reais exigem autenticação e validação no servidor.")
		"/staffmodo":
			staff_demo = not staff_demo
			ui.show_toast("Staff de demonstração %s" % ("ligado" if staff_demo else "desligado"))
		"/staffcurar":
			if not _check_staff_demo():
				return
			player.heal(100)
			armour = 100
			ui.show_toast("Vida e colete restaurados (offline)")
		"/staffcarro":
			if not _check_staff_demo():
				return
			var new_car = VehicleScript.new()
			new_car.car_name = "Sedan de Staff — DEMO"
			new_car.paint_color = Color(0.2, 0.25, 0.32)
			new_car.position = player.global_position + Vector3(3.8, 0, -3.5)
			game_root.add_child(new_car)
			cars.append(new_car)
			ui.show_toast("Carro de teste criado")
		"/voz":
			ui.show_toast("VoIP experimental: configure endereço e conecte no botão VOZ")
		_:
			if command.begins_with("/stafftp "):
				if not _check_staff_demo():
					return
				var args := command.split(" ", false)
				if args.size() != 3 or not args[1].is_valid_float() or not args[2].is_valid_float():
					ui.show_toast("Uso: /stafftp X Z")
					return
				player.global_position = Vector3(float(args[1]), 0.45, float(args[2]))
				city.ensure_chunk_at(player.global_position)
				ui.show_toast("Teleporte offline concluído")
			elif command.begins_with("/staffhora "):
				if not _check_staff_demo():
					return
				var args := command.split(" ", false)
				if args.size() != 2 or not args[1].is_valid_float():
					ui.show_toast("Uso: /staffhora 0-23")
					return
				session_hour = clampf(float(args[1]), 0.0, 23.99)
				city.set_time(session_hour)
				ui.show_toast("Hora da demo alterada")
			elif command.begins_with("/"):
				ui.show_toast("Comando não encontrado • /ajuda")
			else:
				ui.show_toast("CHAT LOCAL (offline): %s" % line)

func _refresh_hud() -> void:
	var focus_pos: Vector3 = active_car.global_position if active_car != null else player.global_position
	var pos_x: float = focus_pos.x
	var pos_z: float = focus_pos.z
	var location_text := "CENTRO LEXUS"
	if pos_z > 70:
		location_text = "BAIRRO SUL"
	elif pos_z < -70:
		location_text = "AVENIDA NORTE"
	elif pos_x > 65:
		location_text = "ZONA LESTE"
	elif pos_x < -65:
		location_text = "VILA OESTE"
	var speed := 0
	if active_car != null:
		speed = active_car.speed_kmh()
	ui.update_hud(player.health, player.stamina, armour, money, location_text, ammo_in_clip, reserve_ammo, active_car != null, speed, job_status, active_car.fuel if active_car != null else 0.0)
	ui.set_voice_status(voice.connection_label() if voice != null else "VOZ OFFLINE")
	city.update_visibility(focus_pos)
	var car_pts: Array = []
	for car in cars:
		car_pts.append(car.global_position)
	var npc_pts: Array = []
	for npc in npcs:
		if npc.active:
			npc_pts.append(npc.global_position)
	ui.update_minimap(focus_pos, player.rotation.y, car_pts, npc_pts, active_car != null)

func _load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ConfigPath) != OK:
		return
	money = maxi(0, int(cfg.get_value("player", "cash", 500)))
	bank_money = maxi(0, int(cfg.get_value("player", "bank", 0)))
	reserve_ammo = maxi(0, int(cfg.get_value("player", "reserve_ammo", 60)))
	medkits = maxi(0, int(cfg.get_value("player", "medkits", 2)))
	points = maxi(0, int(cfg.get_value("player", "xp", 0)))
	eliminations = maxi(0, int(cfg.get_value("player", "kills", 0)))
	deaths = maxi(0, int(cfg.get_value("player", "deaths", 0)))
	quality_level = clampi(int(cfg.get_value("settings", "graphics", 1)), 0, 2)
	voice_server_url = str(cfg.get_value("settings", "voice_server_url", VOICE_SERVER_URL))
	camera_sensitivity = clampf(float(cfg.get_value("settings", "camera_sensitivity", 1.0)), 0.5, 2.4)

func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "cash", money)
	cfg.set_value("player", "bank", bank_money)
	cfg.set_value("player", "reserve_ammo", reserve_ammo)
	cfg.set_value("player", "medkits", medkits)
	cfg.set_value("player", "xp", points)
	cfg.set_value("player", "kills", eliminations)
	cfg.set_value("player", "deaths", deaths)
	cfg.set_value("settings", "graphics", quality_level)
	cfg.set_value("settings", "voice_server_url", voice_server_url)
	cfg.set_value("settings", "camera_sensitivity", camera_sensitivity)
	var err := cfg.save(ConfigPath)
	if err != OK:
		push_warning("Perfil não pôde ser salvo: " + str(err))

func _exit_tree() -> void:
	_save_profile()

func _check_staff_demo() -> bool:
	if staff_demo and state == GameState.PLAYING:
		return true
	ui.show_toast("Ative /staffmodo para TESTE OFFLINE. Sem autorização online.")
	return false

func _on_voice_status(label: String) -> void:
	if ui != null:
		ui.set_voice_status(label)

func _toggle_voice() -> void:
	if voice == null:
		return
	if voice.is_connected_to_voice():
		voice.disconnect_server()
		return
	if not (voice_server_url.begins_with("wss://") or voice_server_url.begins_with("ws://")):
		ui.show_toast("VoIP: falta servidor. Configure VOICE_SERVER_URL em main.gd")
		return
	voice.connect_server(voice_server_url, "cidade_lexus_demo")

func _on_voice_url_changed(value: String) -> void:
	if value != "" and not (value.begins_with("wss://") or value.begins_with("ws://")):
		ui.show_toast("Endereço VoIP deve começar por wss:// ou ws://")
		return
	voice_server_url = value
	_save_profile()
	ui.show_toast("Servidor de voz salvo" if value != "" else "Servidor de voz apagado")
