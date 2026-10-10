extends Node3D

# CIDADE LEXUS RP V18 — morros, serviços, interiores e RP local demonstrativo.
# Gameplay remains local until an authoritative multiplayer backend exists.
const WorldScript = preload("res://scripts/city_world.gd")
const Geo = preload("res://scripts/lexus_geography.gd")
const PlayerScript = preload("res://scripts/lexus_player.gd")
const VehicleScript = preload("res://scripts/lexus_vehicle.gd")
const NPCScript = preload("res://scripts/lexus_npc.gd")
const UIScript = preload("res://scripts/lexus_ui.gd")
const ConfigPath = "user://lexus_v13.cfg"
const VoiceScript = preload("res://scripts/lexus_voice.gd")
const InteriorScript = preload("res://scripts/lexus_interiors.gd")
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
var camera_distance: float = 3.05
var camera_shoulder: float = 0.33
var camera_collision_query: PhysicsRayQueryParameters3D
var fire_held := false
var weapon_recoil := 0.0
var session_hour := 12.0
var climate_auto := true
var climate_accumulator := 0.0
var current_weather := 0 # 0 sol/limpo, 1 nublado, 2 chuva
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
var money: int = 15000
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
var interiors
var inside_house := false
var house_return_position := Vector3.ZERO
var active_context: Dictionary = {}
var current_org: String = "CIDADAO"
var owned_houses: Array[String] = []
var owned_cars: Array[String] = []
var owned_car_states: Array[Dictionary] = []
var unlocked_outfits: Array[int] = [0]
var current_outfit: int = 0
var skin_tone: int = 1
var hair_tone: int = 0
var gps_active: bool = false
var gps_target: Vector3 = Vector3.ZERO
var saved_spawn_position: Vector3 = Vector3(0, 0.15, 12)
var camera_smooth: float = 10.0
var last_interaction_time: float = -100.0
var interaction_cooldown_seconds: float = 0.30

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
	ui.interaction_selected.connect(_on_interaction_selected)
	ui.quality_changed.connect(_on_quality_changed)
	ui.sensitivity_changed.connect(_on_sensitivity_changed)
	ui.camera_distance_changed.connect(_on_camera_distance_changed)
	ui.voice_url_changed.connect(_on_voice_url_changed)
	ui.appearance_changed.connect(_on_appearance_changed)
	ui.gps_selected.connect(_on_gps_selected)
	ui.gps_cleared.connect(_on_gps_cleared)
	ui.update_settings(quality_level, camera_sensitivity, camera_distance)
	ui.update_appearance(current_outfit, skin_tone, hair_tone)
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
	# Profiles stored near the channel reload onto the shore/bridge safely.
	if Geo.is_river_position(saved_spawn_position):
		if absf(saved_spawn_position.x) < Geo.BRIDGE_WIDTH * 0.5:
			saved_spawn_position.y = 2.8
		else:
			saved_spawn_position.z = Geo.RIVER_START_Z - 22.0 if saved_spawn_position.z < 360.0 else Geo.RIVER_END_Z + 22.0
			saved_spawn_position.y = 0.45
	player.position = saved_spawn_position
	game_root.add_child(player)
	city.ensure_chunk_at(saved_spawn_position)

	interiors = InteriorScript.new()
	interiors.name = "CasasInteriores"
	game_root.add_child(interiors)

	var car_spawns := [
		{"name":"Sedan Lexus", "model":"sedan", "pos":Vector3(14, 0.12, 17), "color":Color(0.12, 0.15, 0.19), "team":"", "plate":"LX-0001"},
		{"name":"Hatch Lexus", "model":"hatch", "pos":Vector3(-10, 0.12, 22), "color":Color(0.64, 0.08, 0.11), "team":"", "plate":"LX-0002"},
		{"name":"SUV Lexus", "model":"sw4", "pos":Vector3(71, 0.12, 17), "color":Color(0.37, 0.40, 0.44), "team":"", "plate":"LX-0003"},
		{"name":"BOPE | BMW X7", "model":"x7", "pos":Vector3(91, 0.12, -23), "color":Color(0.07, 0.10, 0.13), "team":"BOPE", "plate":"BOPE-01"},
		{"name":"POLICIA CIVIL | BMW X7", "model":"x7", "pos":Vector3(68, 0.12, 24), "color":Color(0.17, 0.21, 0.31), "team":"POLICIA CIVIL", "plate":"CIVIL-01"},
		{"name":"COMANDO VERMELHO | SW4", "model":"sw4", "pos":Vector3(12, 0.12, 103), "color":Color(0.58, 0.10, 0.13), "team":"COMANDO VERMELHO", "plate":"CV-001"},
		{"name":"PRIMEIRO COMANDO | SW4", "model":"sw4", "pos":Vector3(-12, 0.12, 57), "color":Color(0.17, 0.18, 0.21), "team":"PRIMEIRO COMANDO", "plate":"PC-001"},
		{"name":"SAMU | AMBULANCIA", "model":"samu", "pos":Vector3(68, 0.12, 103), "color":Color(0.91, 0.91, 0.89), "team":"SAMU", "plate":"SAMU-01"}
	]
	for entry in car_spawns:
		_spawn_vehicle(str(entry["name"]), str(entry["model"]), entry["pos"], entry["color"], str(entry["team"]), str(entry["plate"]))
	for i in range(mini(owned_cars.size(), 6)):
		var type_name := owned_cars[i]
		var car_pos := Vector3(10.8, 0.12, 20.0 + float(i) * 7.2)
		var new_car = _spawn_vehicle("VEICULO PARTICULAR", type_name, car_pos, Color(0.13, 0.25, 0.35), "", "MEU-%03d" % i)
		new_car.garage_owned = true
		if i < owned_car_states.size():
			var saved_state: Dictionary = owned_car_states[i]
			new_car.engine_level = clampi(int(saved_state.get("engine", 0)), 0, 3)
			new_car.fuel = clampf(float(saved_state.get("fuel", 100.0)), 0.0, 100.0)
			new_car.durability = clampf(float(saved_state.get("durability", 100.0)), 0.0, 100.0)
			if saved_state.get("paint", null) is Color:
				new_car.set_paint(saved_state["paint"])

	for pos in [Vector3(0, 0.2, -44), Vector3(60, 0.2, -70), Vector3(-60, 0.2, 74), Vector3(120, 0.2, 105)]:
		var bot = NPCScript.new()
		bot.position = pos
		game_root.add_child(bot)
		npcs.append(bot)

	camera = Camera3D.new()
	camera.fov = 67.0
	camera.current = true
	game_root.add_child(camera)
	camera.global_position = player.global_position + Vector3(0.5, 2.8, 3.6)
	camera.look_at(player.global_position + Vector3(0, 1.45, 0), Vector3.UP)
	city.set_quality(quality_level)
	city.set_time(session_hour)
	city.set_weather(current_weather)
	shot_player = AudioStreamPlayer.new()
	shot_player.stream = load("res://assets/audio/disparo_demo.wav")
	shot_player.volume_db = -7.0
	game_root.add_child(shot_player)
	reload_player = AudioStreamPlayer.new()
	reload_player.stream = load("res://assets/audio/recarga_demo.wav")
	reload_player.volume_db = -8.0
	game_root.add_child(reload_player)



func _spawn_vehicle(display_name: String, car_type: String, spawn_pos: Vector3, color: Color, team: String = "", plate_value: String = "LEXUS"):
	var instance = VehicleScript.new()
	instance.car_name = display_name
	instance.model_type = car_type
	instance.paint_color = color
	instance.organization = team
	instance.plate = plate_value
	instance.position = spawn_pos
	game_root.add_child(instance)
	cars.append(instance)
	return instance


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

	climate_accumulator += delta
	if climate_accumulator >= 1.0:
		var elapsed := climate_accumulator
		climate_accumulator = 0.0
		if climate_auto:
			# Full 24-hour in-game cycle over 24 real-world minutes.
			session_hour = fposmod(session_hour + elapsed * (24.0 / (24.0 * 60.0)), 24.0)
		city.set_time(session_hour)

	# Avoid getting trapped underwater when walking off the bridge.
	if not inside_house and active_car == null and player.global_position.y < -3.1:
		var safe_z := 251.0 if player.global_position.z < 360.0 else 469.0
		player.global_position = Vector3(0.0, 1.3, safe_z)
		player.velocity = Vector3.ZERO
		city.ensure_chunk_at(player.global_position)
		ui.show_toast("Você voltou para a margem do canal")

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
		player.input_direction = Vector2.ZERO if ui.map_panel.visible or ui.actions_panel.visible else _get_move_input()
		player.run_held = run_enabled
		player.crouch_held = is_crouched
		player.aim_held = fire_held or weapon_recoil > 0.05

	if player.is_dead:
		return
	if not inside_house:
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
		active_car.throttle = 0.0 if ui.map_panel.visible or ui.actions_panel.visible else -move.y
		active_car.steer = 0.0 if ui.map_panel.visible or ui.actions_panel.visible else move.x
		player.global_position = active_car.global_position
		if active_car.fuel <= 0:
			active_car.engine_on = false
	elif (fire_held or shot_requested) and shoot_cooldown <= 0.0:
		_fire_weapon()
	shot_requested = false

func _unhandled_input(event: InputEvent) -> void:
	if state != GameState.PLAYING or ui.actions_panel.visible or ui.map_panel.visible or ui.settings_panel.visible or ui.chat_line.visible:
		free_camera_touch_id = -1
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
					if ui.actions_panel.visible:
						ui.close_actions()
					elif ui.map_panel.visible:
						ui.close_full_map()
					else:
						_open_menu()
				KEY_Q:
					fire_held = true

func _move_camera(relative: Vector2) -> void:
	camera_yaw = wrapf(camera_yaw - relative.x * camera_sensitivity * 0.0045, -PI, PI)
	camera_pitch = clampf(camera_pitch - relative.y * camera_sensitivity * 0.0037, -0.38, 0.60)


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
	if camera == null or player == null:
		return
	var driving := active_car != null
	var actor_pos: Vector3 = active_car.global_position if driving else player.global_position
	# Aim at the person, not a distant invisible target (old camera bug).
	var target := actor_pos + Vector3(0.0, 1.48 if not is_crouched or driving else 1.05, 0.0)
	var d: float = 5.0 if driving else camera_distance
	var backward := Vector3(sin(camera_yaw) * cos(camera_pitch), sin(camera_pitch), cos(camera_yaw) * cos(camera_pitch))
	var shoulder := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw)) * (0.0 if driving else camera_shoulder)
	var desired := target + backward * d + shoulder + Vector3(0.0, 0.35 if driving else 0.10, 0.0)
	# Prevent the camera from clipping into buildings; exclude the controlled actor.
	var ray := PhysicsRayQueryParameters3D.create(target, desired)
	ray.collision_mask = 1 | 4
	ray.exclude = [player.get_rid()]
	if driving:
		ray.exclude.append(active_car.get_rid())
	var obstruction := get_world_3d().direct_space_state.intersect_ray(ray)
	if not obstruction.is_empty():
		var spot: Vector3 = obstruction["position"]
		desired = spot + (target - spot).normalized() * 0.25
	camera.global_position = camera.global_position.lerp(desired, clampf(delta * camera_smooth, 0.0, 1.0))
	if camera.global_position.distance_to(target) > 0.12:
		camera.look_at(target, Vector3.UP)


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
	player.visual.apply_appearance(current_outfit, skin_tone, hair_tone)
	ui.set_organization(current_org)
	ui.show_toast("Cidade Lexus RP V21 • TRÊS CIDADES • OFFLINE")
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
		"APPEARANCE":
			ui.open_appearance()
		"CLOSE_APPEARANCE":
			ui.close_appearance()
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
		"MAP":
			ui.open_full_map()
		"CLOSE_MAP":
			ui.close_full_map()
		"MAP_IN":
			ui.zoom_full_map(true)
		"MAP_OUT":
			ui.zoom_full_map(false)
		"GPS_CLEAR":
			_on_gps_cleared()
		"GPS_DUQUE":
			_set_city_gps(Geo.DUQUE_CENTER, "Duque de Caxias")
		"GPS_CDD":
			_set_city_gps(Geo.CDD_CENTER, "Cidade de Deus")
		"GPS_NORTE":
			_set_city_gps(Geo.NORTH_CENTER, "Zona Norte")
		"CLOSE_ACTIONS":
			ui.close_actions()
		"SIREN":
			if active_car != null:
				active_car.toggle_siren()
				ui.show_toast("Sirene %s" % ("ligada" if active_car.siren_active else "desligada"))
			else:
				ui.show_toast("Entre em uma viatura para acionar a sirene")
		"CLOSE_INFO":
			ui.close_info()
		"CHAT":
			ui.open_chat()
		"REVIVE":
			_revive_player()

func _set_city_gps(world_position: Vector3, title: String) -> void:
	_on_gps_selected(world_position)
	ui.show_toast("GPS definido: %s" % title)

func _set_weather_mode(mode: int) -> void:
	current_weather = clampi(mode, 0, 2)
	if city != null:
		city.set_weather(current_weather)
	var weather_text := str(["LIMPO", "NUBLADO", "CHUVA"][current_weather])
	ui.show_toast("Tempo: %s" % weather_text)
	_save_profile()

func _set_climate(mode: int) -> void:
	climate_auto = false
	session_hour = 22.0 if mode == 1 else 12.0
	if city != null:
		city.set_time(session_hour)
	ui.show_toast("Clima %d: %s" % [mode, "NOITE" if mode == 1 else "DIA"])
	_save_profile()

func _on_gps_selected(world_position: Vector3) -> void:
	gps_target = Vector3(clampf(world_position.x, -100000.0, 100000.0), 0.0, clampf(world_position.z, -100000.0, 100000.0))
	gps_active = true
	ui.show_toast("Destino marcado no GPS. Feche o mapa para dirigir.")
	_save_profile()

func _on_gps_cleared() -> void:
	gps_active = false
	ui.show_toast("Rota do GPS removida")
	_save_profile()

func _on_appearance_changed(outfit: int, skin_index: int, hair_index: int) -> void:
	# Offline demo: existing wardrobe ownership still applies to outfits bought in the shop.
	# The player may preview locked clothes but cannot equip them for free.
	if not unlocked_outfits.has(outfit):
		ui.show_toast("Roupa bloqueada. Compre na loja de skins dentro da cidade.")
		ui.update_appearance(current_outfit, skin_tone, hair_tone)
		return
	current_outfit = clampi(outfit, 0, 2)
	skin_tone = clampi(skin_index, 0, 3)
	hair_tone = clampi(hair_index, 0, 3)
	if player != null and player.visual != null:
		player.visual.apply_appearance(current_outfit, skin_tone, hair_tone)
	ui.show_toast("Aparência salva no personagem local")
	_save_profile()

func _on_quality_changed(level: int) -> void:
	quality_level = clampi(level, 0, 2)
	if city != null:
		city.set_quality(quality_level)
	_save_profile()

func _on_sensitivity_changed(value: float) -> void:
	camera_sensitivity = clampf(value, 0.5, 2.4)
	_save_profile()

func _on_camera_distance_changed(value: float) -> void:
	camera_distance = clampf(value, 2.5, 4.5)
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
	var now := float(Time.get_ticks_msec()) / 1000.0
	if now - last_interaction_time < interaction_cooldown_seconds:
		return
	last_interaction_time = now
	if inside_house:
		if interiors.near_exit(player.global_position):
			_leave_house()
		else:
			ui.show_toast("Vá até a porta para sair (F)")
		return
	if active_car != null:
		_exit_car()
		return
	var nearest_car = _nearest_vehicle(player.global_position, 4.5)
	if nearest_car != null:
		if nearest_car.organization != "" and nearest_car.organization != current_org and not staff_demo:
			ui.show_toast("Viatura exclusiva: %s" % nearest_car.organization)
			return
		_enter_car(nearest_car)
		return
	var nearest: Dictionary = city.nearest_interactable(player.global_position)
	if not nearest.is_empty():
		_show_world_interaction(nearest)
		return
	if player.global_position.distance_to(Vector3(9, 0, -15)) < 8.0 and not job_active:
		job_active = true
		job_status = "ENTREGA: DESTINO ZONA LESTE"
		gps_active = true
		gps_target = Vector3(120, 0, 60)
		ui.show_toast("Encomenda recebida! Leve até X=120 Z=60")
		_save_profile()
		return
	if job_active and player.global_position.distance_to(Vector3(120, 0, 60)) < 12.0:
		job_active = false
		job_status = "TRABALHO DISPONIVEL"
		gps_active = false
		money += 350
		points += 25
		ui.show_toast("Entrega concluída • +R$ 350 • +25 XP")
		_save_profile()
		return
	ui.show_toast("Nenhuma interação próxima. Use o MAPA para localizar serviços.")

func _nearest_vehicle(origin: Vector3, radius: float):
	var found = null
	var current_distance := radius
	for car in cars:
		if not is_instance_valid(car) or car.occupied():
			continue
		var d: float = origin.distance_to(car.global_position)
		if d < current_distance:
			current_distance = d
			found = car
	return found

func _show_world_interaction(item: Dictionary) -> void:
	active_context = item
	var options: Array = []
	var kind: String = item["type"]
	match kind:
		"house":
			var home_id := str(item["id"])
			options.append({"id":"house_visit", "label":"VISITAR INTERIOR"})
			if owned_houses.has(home_id):
				options.append({"id":"house_owned", "label":"CASA ADQUIRIDA"})
			else:
				options.append({"id":"house_buy", "label":"COMPRAR CASA - R$ 1.800"})
		"dealer":
			options.append({"id":"dealer_sedan", "label":"SEDAN LEXUS - R$ 4.000"})
			options.append({"id":"dealer_hatch", "label":"HATCH LEXUS - R$ 3.000"})
			options.append({"id":"dealer_sw4", "label":"SUV ESTILO SW4 - R$ 9.000"})
		"skins":
			options.append({"id":"outfit_0", "label":"LOOK LEXUS CLASSICO - GRATIS"})
			options.append({"id":"outfit_1", "label":"LOOK VERMELHO - R$ 600"})
			options.append({"id":"outfit_2", "label":"LOOK OPERACIONAL - R$ 900"})
		"tuning":
			options.append({"id":"tune_engine", "label":"MELHORAR MOTOR - R$ 500"})
			options.append({"id":"tune_paint", "label":"PINTURA VERMELHA - R$ 250"})
		"workshop":
			options.append({"id":"repair_car", "label":"REPARAR VEICULO - R$ 300"})
			options.append({"id":"refuel_car", "label":"ABASTECER VEICULO - R$ 200"})
		"market":
			options.append({"id":"buy_medkit", "label":"COMPRAR KIT MEDICO - R$ 200"})
			options.append({"id":"buy_ammo", "label":"COMPRAR MUNICAO - R$ 50"})
		"hospital":
			options.append({"id":"hospital_heal", "label":"ATENDIMENTO - R$ 150"})
			options.append({"id":"join_org", "label":"INGRESSAR NO SAMU (DEMO)"})
		"org":
			options.append({"id":"join_org", "label":"INGRESSAR: %s (DEMO)" % str(item["team"])})
			options.append({"id":"leave_org", "label":"SAIR DA ORGANIZACAO"})
	ui.show_actions(str(item["title"]), "Interações locais offline • Pressione um botão", options)

func _on_interaction_selected(choice: String) -> void:
	if state != GameState.PLAYING or active_context.is_empty() or inside_house:
		ui.close_actions()
		return
	# Distância e estado validados novamente para não acionar menus antigos.
	var target: Vector3 = active_context["position"]
	if player.global_position.distance_to(target) > 8.0:
		ui.show_toast("Aproxime-se novamente do local")
		ui.close_actions()
		return
	if not _is_valid_action_for_context(str(active_context["type"]), choice):
		ui.show_toast("Ação indisponível neste local")
		ui.close_actions()
		return
	match choice:
		"house_visit":
			_enter_house(str(active_context["id"]))
		"house_buy":
			var home_id := str(active_context["id"])
			if owned_houses.has(home_id):
				ui.show_toast("Você já possui esta casa")
			elif _spend(1800):
				owned_houses.append(home_id)
				ui.show_toast("Casa comprada • Propriedade salva")
		"house_owned":
			ui.show_toast("Esta casa já pertence ao seu personagem")
		"dealer_sedan", "dealer_hatch", "dealer_sw4":
			var model := "sedan" if choice == "dealer_sedan" else ("hatch" if choice == "dealer_hatch" else "sw4")
			var cost := 4000 if model == "sedan" else (3000 if model == "hatch" else 9000)
			if owned_cars.size() >= 6:
				ui.show_toast("Garagem cheia (limite demo: 6 veículos)")
			elif _spend(cost):
				owned_cars.append(model)
				var number := owned_cars.size()
				var pos := Vector3(10.8, 0.12, 20.0 + float(number - 1) * 7.2)
				var purchased = _spawn_vehicle("CARRO PARTICULAR", model, pos, Color(0.13, 0.25, 0.35), "", "MEU-%03d" % number)
				purchased.garage_owned = true
				ui.show_toast("Veículo comprado • Disponível na garagem central")
		"outfit_0", "outfit_1", "outfit_2":
			var index := int(choice.get_slice("_", 1))
			var cost := 0 if index == 0 else (600 if index == 1 else 900)
			if unlocked_outfits.has(index) or _spend(cost):
				if not unlocked_outfits.has(index):
					unlocked_outfits.append(index)
				current_outfit = index
				player.visual.apply_appearance(index, skin_tone, hair_tone)
				ui.show_toast("Roupa equipada: modelo %d" % index)
		"tune_engine", "tune_paint", "repair_car", "refuel_car":
			_service_vehicle_action(choice)
		"buy_medkit":
			if _spend(200):
				medkits += 1
				ui.show_toast("Kit médico adicionado ao inventário")
		"buy_ammo":
			if _spend(50):
				reserve_ammo += 24
				ui.show_toast("24 munições adicionadas")
		"hospital_heal":
			if player.health >= 100.0:
				ui.show_toast("Sua vida já está cheia")
			elif _spend(150):
				player.heal(100.0)
				ui.show_toast("Atendimento concluído")
		"join_org":
			current_org = str(active_context.get("team", "CIDADAO"))
			ui.set_organization(current_org)
			ui.show_toast("Organização local: " + current_org)
		"leave_org":
			current_org = "CIDADAO"
			ui.set_organization(current_org)
			ui.show_toast("Você saiu da organização")
	ui.close_actions()
	active_context = {}
	_save_profile()

func _is_valid_action_for_context(kind: String, choice: String) -> bool:
	match kind:
		"house": return choice in ["house_visit", "house_buy", "house_owned"]
		"dealer": return choice in ["dealer_sedan", "dealer_hatch", "dealer_sw4"]
		"skins": return choice in ["outfit_0", "outfit_1", "outfit_2"]
		"tuning": return choice in ["tune_engine", "tune_paint"]
		"workshop": return choice in ["repair_car", "refuel_car"]
		"market": return choice in ["buy_medkit", "buy_ammo"]
		"hospital": return choice in ["hospital_heal", "join_org"]
		"org": return choice in ["join_org", "leave_org"]
	return false

func _spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if money < amount:
		ui.show_toast("Saldo insuficiente • Necessário R$ %d" % amount)
		return false
	money -= amount
	return true

func _service_vehicle_action(choice: String) -> void:
	var vehicle = _nearest_vehicle(player.global_position, 20.0)
	if vehicle == null:
		ui.show_toast("Estacione um carro próximo da oficina")
		return
	if vehicle.organization != "" and vehicle.organization != current_org and not staff_demo:
		ui.show_toast("Sem permissão para modificar viatura")
		return
	match choice:
		"tune_engine":
			if vehicle.engine_level >= 3:
				ui.show_toast("Motor já está no nível máximo")
			elif _spend(500):
				vehicle.upgrade_engine()
				ui.show_toast("Motor melhorado para nível %d" % vehicle.engine_level)
		"tune_paint":
			if _spend(250):
				vehicle.set_paint(Color(0.72, 0.08, 0.12))
				ui.show_toast("Pintura aplicada")
		"repair_car":
			if _spend(300):
				vehicle.repair()
				ui.show_toast("Veículo reparado")
		"refuel_car":
			if _spend(200):
				vehicle.refuel()
				ui.show_toast("Tanque abastecido")

func _enter_house(home_id: String) -> void:
	if active_car != null or interiors == null:
		return
	house_return_position = player.global_position
	inside_house = true
	interiors.open_house(home_id)
	city.visible = false
	for car in cars:
		car.visible = false
	player.global_position = interiors.spawn_location()
	player.velocity = Vector3.ZERO
	camera.global_position = player.global_position + Vector3(1, 2.2, 3)
	ui.show_toast("Interior carregado • Vá à porta e use F para sair")

func _leave_house() -> void:
	if not inside_house:
		return
	inside_house = false
	interiors.close_house()
	city.visible = true
	for car in cars:
		car.visible = true
	city.ensure_chunk_at(house_return_position)
	player.global_position = house_return_position + Vector3(0, 0.12, 0)
	player.velocity = Vector3.ZERO
	ui.show_toast("Você saiu da residência")

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
	info += "\n\nORG: %s | CASAS: %d | CARROS: %d | ROUPA: %d" % [current_org, owned_houses.size(), owned_cars.size(), current_outfit]
	ui.open_info(info)

func _on_chat_command(line: String) -> void:
	if state != GameState.PLAYING:
		return
	if line.length() > 160 or line.find("\n") >= 0:
		ui.show_toast("Comando inválido ou muito longo")
		return
	var command := line.to_lower().strip_edges()
	match command:
		"/ajuda":
			ui.open_info("COMANDOS RP LOCAL\n/rg /saldo /inventario /gps /mapa /org /casas\n/cdd /duque /zonanorte\n/clima 1 (NOITE) /clima 2 (DIA) /clima auto\n/tempo sol /tempo nublado /tempo chuva\n/trabalho /curar /comprarmunicao /recarregar /carro\n/staffhelp /voz\n\nUse a PONTE para Cidade de Deus; depois siga a avenida e atravesse o TÚNEL até Zona Norte. Demo offline.")
		"/rg":
			ui.open_info("REGISTRO GERAL\nNome: Lexus Urbano 01\nCidade: Cidade Lexus RP\nOcupação: Trabalhador\nNível: %d\nMultiplayer: NÃO CONECTADO" % int(points / 100 + 1))
		"/org":
			ui.open_info("ORGANIZACAO LOCAL: %s\nBOPE e CIVIL: distrito 1,0\nCV e PRIMEIRO COMANDO: distrito 0,1\nSAMU: distrito 1,1\nUse F perto das bases para ingressar na demo. Sem autenticação online." % current_org)
		"/mapa":
			ui.open_full_map()
		"/casas":
			ui.show_toast("Casas adquiridas: %d" % owned_houses.size())
		"/saldo":
			ui.show_toast("CARTEIRA: R$ %d | BANCO: R$ %d" % [money, bank_money])
		"/inventario", "/mochila":
			_show_inventory()
		"/gps":
			ui.open_full_map()
			ui.show_toast("Toque no mapa ampliado para marcar destino")
		"/gpscancelar":
			_on_gps_cleared()
		"/duque":
			_set_city_gps(Geo.DUQUE_CENTER, "Duque de Caxias")
		"/cdd", "/cidadededeus":
			_set_city_gps(Geo.CDD_CENTER, "Cidade de Deus")
		"/zonanorte":
			_set_city_gps(Geo.NORTH_CENTER, "Zona Norte")
		"/clima", "/clima ajuda":
			ui.open_info("CONTROLE DE CLIMA E HORÁRIO\n/clima 1 = noite (22:00)\n/clima 2 = dia (12:00)\n/clima auto = ciclo automático (24 min por dia)\n/tempo sol, /tempo nublado, /tempo chuva = muda o tempo local\n\nSistema da demonstração offline.")
		"/clima 1":
			_set_climate(1)
		"/clima 2":
			_set_climate(2)
		"/clima auto":
			climate_auto = true
			ui.show_toast("Ciclo de dia e noite ativado")
			_save_profile()
		"/tempo sol", "/tempo limpo":
			_set_weather_mode(0)
		"/tempo nublado":
			_set_weather_mode(1)
		"/tempo chuva":
			_set_weather_mode(2)
		"/gpsgaragem":
			_on_gps_selected(Vector3(14, 0, 17))
		"/gpsentrega":
			_on_gps_selected(Vector3(120, 0, 60))
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
			ui.open_info("STAFF LOCAL — SOMENTE TESTES OFFLINE\n/staffmodo\n/staffcurar\n/stafftp X Z\n/staffdinheiro\n/staffcarro\n/staffhora HH\n/staffvida\n/stafforg BOPE (DEMO)\n\nNo futuro, comandos reais exigem autenticação e validação no servidor.")
		"/staffmodo":
			if not OS.has_feature("debug"):
				ui.show_toast("Staff local indisponível fora do APK de desenvolvimento")
				return
			staff_demo = not staff_demo
			ui.show_toast("STAFF DE TESTE %s | OFFLINE" % ("ligado" if staff_demo else "desligado"))
		"/staffdinheiro":
			if not _check_staff_demo():
				return
			money = mini(100000000, money + 10000)
			ui.show_toast("+R$ 10.000 • somente para testes offline")
			_save_profile()
		"/staffvida":
			if not _check_staff_demo():
				return
			player.heal(100)
			ui.show_toast("Vida restaurada (staff teste)")
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
			if command.begins_with("/stafforg "):
				if not _check_staff_demo():
					return
				var org_name := command.substr(10).strip_edges().to_upper()
				if org_name not in ["BOPE", "POLICIA CIVIL", "COMANDO VERMELHO", "PRIMEIRO COMANDO", "SAMU", "CIDADAO"]:
					ui.show_toast("Organização inválida")
					return
				current_org = org_name
				ui.set_organization(current_org)
				ui.show_toast("Organização alterada na demo")
				_save_profile()
			elif command.begins_with("/stafftp "):
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
	if inside_house:
		location_text = "INTERIOR DA CASA"
	elif city != null:
		location_text = city.district_name(focus_pos)
	var speed := 0
	if active_car != null:
		speed = active_car.speed_kmh()
	ui.update_hud(player.health, player.stamina, armour, money, location_text, ammo_in_clip, reserve_ammo, active_car != null, speed, job_status, active_car.fuel if active_car != null else 0.0)
	ui.set_climate_info(session_hour, city.weather_label(), climate_auto)
	ui.set_voice_status(voice.connection_label() if voice != null else "VOZ OFFLINE")
	if not inside_house:
		city.update_visibility(focus_pos)
	ui.set_organization(current_org)
	ui.update_gps(gps_active, gps_target, focus_pos)
	if inside_house:
		ui.set_context_hint("F / USAR • SAIR PELA PORTA")
	elif active_car != null:
		ui.set_context_hint("F / USAR • SAIR DO VEICULO | SIRENE")
	else:
		var near_car = _nearest_vehicle(player.global_position, 4.5)
		var nearby: Dictionary = city.nearest_interactable(player.global_position)
		if near_car != null:
			ui.set_context_hint("F / USAR • " + near_car.car_name)
		elif not nearby.is_empty():
			ui.set_context_hint("F / USAR • " + str(nearby["title"]))
		else:
			ui.set_context_hint("F / USAR PARA INTERAGIR | TOQUE NO MINI MAPA")
	var car_pts: Array = []
	for car in cars:
		car_pts.append(car.global_position)
	var npc_pts: Array = []
	for npc in npcs:
		if npc.active:
			npc_pts.append(npc.global_position)
	ui.update_minimap(focus_pos, player.rotation.y, car_pts, npc_pts, active_car != null)
	if not inside_house:
		ui.update_landmarks(city.all_map_points())

func _load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ConfigPath) != OK:
		return
	money = clampi(int(cfg.get_value("player", "cash", 15000)), 0, 100000000)
	bank_money = maxi(0, int(cfg.get_value("player", "bank", 0)))
	reserve_ammo = maxi(0, int(cfg.get_value("player", "reserve_ammo", 60)))
	medkits = maxi(0, int(cfg.get_value("player", "medkits", 2)))
	points = maxi(0, int(cfg.get_value("player", "xp", 0)))
	eliminations = maxi(0, int(cfg.get_value("player", "kills", 0)))
	deaths = maxi(0, int(cfg.get_value("player", "deaths", 0)))
	quality_level = clampi(int(cfg.get_value("settings", "graphics", 1)), 0, 2)
	session_hour = fposmod(float(cfg.get_value("world", "hour", 12.0)), 24.0)
	climate_auto = bool(cfg.get_value("world", "cycle", true))
	current_weather = clampi(int(cfg.get_value("world", "weather", 0)), 0, 2)
	voice_server_url = str(cfg.get_value("settings", "voice_server_url", VOICE_SERVER_URL))
	camera_sensitivity = clampf(float(cfg.get_value("settings", "camera_sensitivity", 1.0)), 0.5, 2.4)
	camera_distance = clampf(float(cfg.get_value("settings", "camera_distance", 3.05)), 2.5, 4.5)
	current_org = str(cfg.get_value("player", "organization", "CIDADAO"))
	if current_org not in ["BOPE", "POLICIA CIVIL", "COMANDO VERMELHO", "PRIMEIRO COMANDO", "SAMU", "CIDADAO"]:
		current_org = "CIDADAO"
	owned_houses.clear()
	for home in cfg.get_value("player", "houses", []):
		if str(home).begins_with("casa_") and owned_houses.size() < 64:
			owned_houses.append(str(home))
	owned_cars.clear()
	for model in cfg.get_value("player", "vehicles", []):
		if str(model) in ["sedan", "hatch", "sw4"] and owned_cars.size() < 6:
			owned_cars.append(str(model))
	owned_car_states.clear()
	for state_data in cfg.get_value("player", "vehicle_states", []):
		if state_data is Dictionary and owned_car_states.size() < 6:
			owned_car_states.append(state_data)
	unlocked_outfits = [0]
	for item in cfg.get_value("player", "outfits", []):
		var outfit := int(item)
		if outfit in [1, 2] and not unlocked_outfits.has(outfit):
			unlocked_outfits.append(outfit)
	current_outfit = clampi(int(cfg.get_value("player", "outfit", 0)), 0, 2)
	skin_tone = clampi(int(cfg.get_value("player", "skin_tone", 1)), 0, 3)
	hair_tone = clampi(int(cfg.get_value("player", "hair_tone", 0)), 0, 3)
	gps_active = bool(cfg.get_value("player", "gps_active", false))
	var gps_x := clampf(float(cfg.get_value("player", "gps_x", 0.0)), -100000.0, 100000.0)
	var gps_z := clampf(float(cfg.get_value("player", "gps_z", 0.0)), -100000.0, 100000.0)
	gps_target = Vector3(gps_x, 0.0, gps_z)
	var spawn_x := clampf(float(cfg.get_value("player", "spawn_x", 0.0)), -30000.0, 30000.0)
	var spawn_z := clampf(float(cfg.get_value("player", "spawn_z", 12.0)), -30000.0, 30000.0)
	saved_spawn_position = Vector3(spawn_x, 0.45, spawn_z)
	if not unlocked_outfits.has(current_outfit):
		current_outfit = 0

func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "cash", money)
	cfg.set_value("player", "bank", bank_money)
	cfg.set_value("player", "reserve_ammo", reserve_ammo)
	cfg.set_value("player", "medkits", medkits)
	cfg.set_value("player", "xp", points)
	cfg.set_value("player", "kills", eliminations)
	cfg.set_value("player", "deaths", deaths)
	cfg.set_value("player", "organization", current_org)
	cfg.set_value("player", "houses", owned_houses)
	cfg.set_value("player", "vehicles", owned_cars)
	# Do not erase garage tuning when settings are saved from the initial menu.
	var vehicle_states: Array[Dictionary] = []
	if cars.is_empty():
		vehicle_states = owned_car_states.duplicate(true)
	else:
		for car in cars:
			if is_instance_valid(car) and car.garage_owned and vehicle_states.size() < 6:
				vehicle_states.append({"engine":car.engine_level, "fuel":car.fuel, "durability":car.durability, "paint":car.paint_color})
	cfg.set_value("player", "vehicle_states", vehicle_states)
	cfg.set_value("player", "outfits", unlocked_outfits)
	cfg.set_value("player", "outfit", current_outfit)
	cfg.set_value("player", "skin_tone", skin_tone)
	cfg.set_value("player", "hair_tone", hair_tone)
	cfg.set_value("player", "gps_active", gps_active)
	cfg.set_value("player", "gps_x", gps_target.x)
	cfg.set_value("player", "gps_z", gps_target.z)
	if player != null and is_instance_valid(player) and not inside_house and not player.is_dead:
		var point: Vector3 = active_car.global_position if active_car != null else player.global_position
		saved_spawn_position = Vector3(clampf(point.x, -30000.0, 30000.0), 0.45, clampf(point.z, -30000.0, 30000.0))
	cfg.set_value("player", "spawn_x", saved_spawn_position.x)
	cfg.set_value("player", "spawn_z", saved_spawn_position.z)
	cfg.set_value("world", "hour", session_hour)
	cfg.set_value("world", "cycle", climate_auto)
	cfg.set_value("world", "weather", current_weather)
	cfg.set_value("settings", "graphics", quality_level)
	cfg.set_value("settings", "voice_server_url", voice_server_url)
	cfg.set_value("settings", "camera_sensitivity", camera_sensitivity)
	cfg.set_value("settings", "camera_distance", camera_distance)
	var err := cfg.save(ConfigPath)
	if err != OK:
		push_warning("Perfil não pôde ser salvo: " + str(err))

func _exit_tree() -> void:
	_save_profile()

func _check_staff_demo() -> bool:
	if staff_demo and OS.has_feature("debug") and state == GameState.PLAYING:
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
