extends CanvasLayer

signal play_pressed
signal quality_changed(level: int)
signal sensitivity_changed(level: float)
signal camera_distance_changed(value: float)
signal voice_url_changed(url: String)
signal action_pressed(action: String)
signal move_changed(direction: Vector2)
signal command_entered(command: String)
signal interaction_selected(choice_id: String)
signal appearance_changed(outfit: int, skin_tone: int, hair_tone: int)
signal gps_selected(world_position: Vector3)
signal gps_cleared

const Joystick = preload("res://scripts/virtual_joystick.gd")
const Minimap = preload("res://scripts/lexus_minimap.gd")
const Humanoid = preload("res://scripts/humanoid.gd")
const BG_PATH = "res://assets/background_ui_v12.png"

var menu: Control
var loading: Control
var hud: Control
var settings_panel: Control
var actions_panel: Control
var map_panel: Control
var map_surface
var actions_title: Label
var actions_subtitle: Label
var actions_container: VBoxContainer
var interaction_hint: Label
var organization_label: Label
var info_panel: Control
var death_panel: Control
var chat_line: LineEdit
var loading_bar: ProgressBar
var loading_text: Label
var game_title: Label
var hp: ProgressBar
var stamina: ProgressBar
var armor: ProgressBar
var location: Label
var cash_label: Label
var ammo_label: Label
var speed_label: Label
var job_label: Label
var gps_label: Label
var climate_label: Label
var alert_label: Label
var voice_label: Label
var reticle_timer := 0.0
var crosshair_label: Label
var toast: Label
var minimap
var movement
var buttons: Dictionary = {}
var toast_time := 0.0
var quality_opt: OptionButton
var mouse_opt: HSlider
var camera_distance_opt: HSlider
var voice_input: LineEdit
var main_title: Label
var server_opt: OptionButton
var _last_size := Vector2.ZERO
var shade: ColorRect
var appearance_panel: Control
var preview_human: Node3D
var avatar_outfit: OptionButton
var avatar_skin: OptionButton
var avatar_hair: OptionButton
var avatar_note: Label
var play_btn: Button
var settings_btn: Button

func _ready() -> void:
	menu = _make_menu()
	loading = _make_loading()
	hud = _make_hud()
	settings_panel = _make_settings()
	appearance_panel = _make_appearance()
	actions_panel = _make_actions_panel()
	map_panel = _make_map_panel()
	info_panel = _make_info_panel()
	death_panel = _make_death_panel()
	set_screen("loading")
	get_viewport().size_changed.connect(_relayout)
	_relayout()

func _process(delta: float) -> void:
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast.visible = false
	if appearance_panel.visible and preview_human != null:
		preview_human.rotation.y = sin(Time.get_ticks_msec() * 0.00038) * 0.20
		preview_human.call("update_pose", delta, 0.15, false, false, 0.0, false, false)
	if reticle_timer > 0.0:
		reticle_timer -= delta
		if reticle_timer <= 0.0 and crosshair_label != null:
			crosshair_label.modulate = Color.WHITE

func _root(interactive: bool = false) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS if interactive else Control.MOUSE_FILTER_IGNORE
	add_child(root)
	return root

func _style(bg: Color, line: Color = Color(0.85, 0.19, 0.27, 0.85), radius: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = line
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	return s

func _panel(parent: Control, rect: Rect2, color: Color = Color(0.03, 0.06, 0.10, 0.87)) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", _style(color))
	parent.add_child(p)
	return p

func _label(parent: Control, value: String, rect: Rect2, font_size: int = 18) -> Label:
	var l := Label.new()
	l.text = value
	l.position = rect.position
	l.size = rect.size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _button(parent: Control, label_text: String, rect: Rect2, action: String, highlight: bool = false) -> Button:
	var b := Button.new()
	b.text = label_text
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.focus_mode = Control.FOCUS_ALL
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_stylebox_override("normal", _style(Color(0.61, 0.06, 0.11, 0.95) if highlight else Color(0.04, 0.08, 0.13, 0.82)))
	b.add_theme_stylebox_override("hover", _style(Color(0.80, 0.11, 0.17, 1.0)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.35, 0.07, 0.11, 1.0)))
	b.add_theme_stylebox_override("focus", _style(Color(0.0, 0.0, 0.0, 0.0), Color(1.0, 0.38, 0.38), 13))
	parent.add_child(b)
	if action == "FIRE":
		b.button_down.connect(func(): action_pressed.emit("FIRE_DOWN"))
		b.button_up.connect(func(): action_pressed.emit("FIRE_UP"))
	elif action == "VOICE_PTT":
		b.button_down.connect(func(): action_pressed.emit("VOICE_DOWN"))
		b.button_up.connect(func(): action_pressed.emit("VOICE_UP"))
	elif action != "":
		b.pressed.connect(func(): action_pressed.emit(action))
	return b

func _background(parent: Control) -> void:
	var tex := TextureRect.new()
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(BG_PATH):
		tex.texture = load(BG_PATH)
	parent.add_child(tex)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.color = Color(0.03, 0.035, 0.055, 0.34)
	parent.add_child(dim)

func _make_menu() -> Control:
	# An interactive Control root makes touch propagation explicit.
	var root := _root(true)
	_background(root)

	# The reference image contained an old blue Google sign-in button.
	# An opaque left-side shade hides this obsolete element without modifying the image.
	shade = ColorRect.new()
	shade.name = "MenuShade"
	shade.position = Vector2.ZERO
	shade.size = Vector2(660, 720)
	shade.color = Color(0.015, 0.028, 0.055, 0.97)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var card := _panel(root, Rect2(48, 54, 520, 590), Color(0.018, 0.043, 0.072, 0.97))
	card.name = "MenuCard"
	_label(card, "CIDADE LEXUS RP", Rect2(27, 25, 462, 43), 29)
	main_title = _label(card, "SUA CIDADE. SUA HISTÓRIA.", Rect2(27, 88, 460, 73), 29)
	_label(card, "DUQUE DE CAXIAS  /  CIDADE DE DEUS  /  ZONA NORTE  /  V21", Rect2(27, 180, 464, 27), 16)
	_label(card, "ESCOLHA O SERVIDOR", Rect2(27, 237, 462, 28), 16)

	server_opt = OptionButton.new()
	server_opt.name = "ServerSelector"
	server_opt.position = Vector2(27, 270)
	server_opt.size = Vector2(465, 52)
	server_opt.mouse_filter = Control.MOUSE_FILTER_STOP
	server_opt.add_item("CIDADE LEXUS  •  DEMO OFFLINE")
	server_opt.select(0)
	server_opt.add_theme_font_size_override("font_size", 17)
	server_opt.add_theme_stylebox_override("normal", _style(Color(0.08, 0.10, 0.15, 0.98)))
	card.add_child(server_opt)

	_label(card, "Modo local disponível. O multiplayer ainda está em desenvolvimento.", Rect2(27, 332, 460, 46), 15)
	play_btn = _button(card, "JOGAR", Rect2(27, 378, 465, 65), "PLAY", true)
	play_btn.name = "PlayButton"
	play_btn.add_theme_font_size_override("font_size", 28)
	var appearance_btn := _button(card, "PERSONALIZAR PERSONAGEM", Rect2(27, 451, 465, 50), "APPEARANCE")
	appearance_btn.name = "AppearanceButton"
	settings_btn = _button(card, "CONFIGURAÇÕES", Rect2(27, 508, 465, 50), "SETTINGS")
	settings_btn.name = "SettingsButton"
	_label(card, "ANDROID  •  HORIZONTAL  •  PROTÓTIPO OFFLINE", Rect2(27, 564, 464, 20), 12)
	return root

func _make_loading() -> Control:
	var root := _root()
	_background(root)
	var card := _panel(root, Rect2(260, 250, 760, 220), Color(0.02, 0.05, 0.08, 0.90))
	card.name = "LoadingCard"
	var label := _label(card, "CIDADE LEXUS RP", Rect2(32, 25, 700, 55), 33)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_text = _label(card, "Preparando jogo...", Rect2(32, 90, 700, 34), 20)
	loading_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_bar = ProgressBar.new()
	loading_bar.position = Vector2(35, 143)
	loading_bar.size = Vector2(690, 22)
	loading_bar.show_percentage = false
	card.add_child(loading_bar)
	_label(card, "Carregamento do protótipo local • Não conecta a um servidor real", Rect2(32, 183, 700, 28), 15)
	# Crédito da amostra realista usada na V19 (CC BY 4.0).
	_label(card, "Modelo humano de teste: Bake3D • CC BY 4.0", Rect2(32, 204, 700, 22), 12)
	return root

func _make_hud() -> Control:
	var root := _root()
	var card := _panel(root, Rect2(20, 16, 346, 158), Color(0.025, 0.044, 0.076, 0.88))
	card.name = "HudCard"
	_label(card, "CIDADE LEXUS RP", Rect2(14, 10, 310, 28), 21)
	location = _label(card, "LEXUS CENTRAL", Rect2(14, 39, 310, 26), 16)
	hp = _progress(card, Vector2(14, 74), Color(0.88, 0.17, 0.20))
	stamina = _progress(card, Vector2(14, 100), Color(0.33, 0.65, 0.98))
	armor = _progress(card, Vector2(14, 126), Color(0.54, 0.56, 0.65))
	_label(card, "VIDA", Rect2(208, 69, 100, 22), 14)
	_label(card, "ENERGIA", Rect2(208, 95, 100, 22), 14)
	_label(card, "COLETE", Rect2(208, 121, 100, 22), 14)

	minimap = Minimap.new()
	minimap.position = Vector2(1087, 17)
	minimap.size = Vector2(173, 173)
	root.add_child(minimap)
	minimap.map_clicked.connect(func(): action_pressed.emit("MAP"))
	cash_label = _label(root, "R$ 15000", Rect2(810, 17, 250, 35), 21)
	ammo_label = _label(root, "PISTOLA • 12 / 60", Rect2(810, 60, 260, 33), 17)
	speed_label = _label(root, "A PÉ", Rect2(810, 102, 270, 33), 18)
	job_label = _label(root, "TRABALHO: DISPONÍVEL", Rect2(810, 144, 300, 33), 15)
	gps_label = _label(root, "GPS: sem destino", Rect2(385, 81, 410, 30), 16)
	climate_label = _label(root, "12:00  •  TEMPO LIMPO", Rect2(385, 38, 410, 35), 18)
	voice_label = _label(root, "VOZ: OFFLINE", Rect2(810, 181, 300, 26), 16)
	organization_label = _label(root, "ORGANIZACAO: CIDADAO", Rect2(810, 210, 320, 26), 15)
	interaction_hint = _label(root, "F / USAR: interagir perto de casas e servicos", Rect2(390, 560, 530, 34), 16)
	interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label = _label(root, "", Rect2(420, 24, 380, 48), 22)
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = _label(root, "", Rect2(350, 95, 610, 55), 20)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.visible = false

	movement = Joystick.new()
	root.add_child(movement)
	movement.moved.connect(func(dir: Vector2): move_changed.emit(dir))

	buttons["RUN"] = _button(root, "CORRER", Rect2(0, 0, 110, 66), "RUN", true)
	buttons["JUMP"] = _button(root, "PULAR", Rect2(0, 0, 110, 66), "JUMP")
	buttons["CROUCH"] = _button(root, "AGACHAR", Rect2(0, 0, 128, 66), "CROUCH")
	buttons["FIRE"] = _button(root, "ATIRAR", Rect2(0, 0, 132, 75), "FIRE", true)
	buttons["RELOAD"] = _button(root, "RECARGA", Rect2(0, 0, 118, 62), "RELOAD")
	buttons["INTERACT"] = _button(root, "F • INTERAGIR", Rect2(0, 0, 172, 58), "INTERACT")
	buttons["ITEMS"] = _button(root, "MOCHILA", Rect2(0, 0, 108, 49), "ITEMS")
	buttons["CHAT"] = _button(root, "CHAT RP", Rect2(0, 0, 105, 49), "CHAT")
	buttons["MENU"] = _button(root, "MENU", Rect2(0, 0, 103, 49), "MENU")
	buttons["MAP"] = _button(root, "MAPA", Rect2(0, 0, 103, 49), "MAP")
	buttons["SIREN"] = _button(root, "SIRENE", Rect2(0, 0, 110, 49), "SIREN")
	buttons["VOICE_CONNECT"] = _button(root, "VOZ", Rect2(0, 0, 108, 48), "VOICE_CONNECT")
	buttons["VOICE_PTT"] = _button(root, "SEGURAR P/ FALAR", Rect2(0, 0, 156, 58), "VOICE_PTT")

	chat_line = LineEdit.new()
	chat_line.placeholder_text = "/ajuda ou mensagem local"
	chat_line.visible = false
	chat_line.position = Vector2(400, 605)
	chat_line.size = Vector2(480, 51)
	chat_line.text_submitted.connect(_submit_chat)
	root.add_child(chat_line)

	# Tiny aim reticle in the center.
	var cross := _label(root, "+", Rect2(618, 331, 48, 48), 28)
	cross.name = "Crosshair"
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_label = cross
	return root

func _progress(parent: Control, p: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = p
	bar.size = Vector2(190, 18)
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	var bg := _style(Color(0.10, 0.12, 0.17, 0.95), Color(0.13, 0.17, 0.21), 6)
	var fill := _style(color, color, 6)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func _make_settings() -> Control:
	var root := _root(true)
	root.visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.01, 0.03, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var p := _panel(root, Rect2(370, 60, 540, 590), Color(0.035, 0.06, 0.09, 0.98))
	p.name = "SettingsCard"
	_label(p, "CONFIGURAÇÕES", Rect2(28, 28, 430, 44), 27)
	_label(p, "Gráficos", Rect2(28, 100, 420, 30), 19)
	quality_opt = OptionButton.new()
	quality_opt.position = Vector2(28, 140)
	quality_opt.size = Vector2(444, 45)
	quality_opt.add_item("BAIXO — mais FPS")
	quality_opt.add_item("MÉDIO — equilibrado")
	quality_opt.add_item("ALTO — mais sombras")
	quality_opt.select(1)
	quality_opt.item_selected.connect(func(idx: int): quality_changed.emit(idx))
	p.add_child(quality_opt)
	_label(p, "Sensibilidade da câmera", Rect2(28, 213, 420, 28), 19)
	mouse_opt = HSlider.new()
	mouse_opt.position = Vector2(30, 251)
	mouse_opt.size = Vector2(430, 35)
	mouse_opt.min_value = 0.5
	mouse_opt.max_value = 2.4
	mouse_opt.step = 0.1
	mouse_opt.value = 1.0
	mouse_opt.value_changed.connect(func(value: float): sensitivity_changed.emit(value))
	p.add_child(mouse_opt)
	_label(p, "Distância da câmera", Rect2(28, 298, 420, 28), 19)
	camera_distance_opt = HSlider.new()
	camera_distance_opt.position = Vector2(30, 335)
	camera_distance_opt.size = Vector2(430, 32)
	camera_distance_opt.min_value = 2.5
	camera_distance_opt.max_value = 4.5
	camera_distance_opt.step = 0.1
	camera_distance_opt.value = 3.05
	camera_distance_opt.value_changed.connect(func(value: float): camera_distance_changed.emit(value))
	p.add_child(camera_distance_opt)
	_label(p, "Servidor VoIP experimental (wss://)", Rect2(28, 390, 480, 30), 18)
	voice_input = LineEdit.new()
	voice_input.position = Vector2(28, 423)
	voice_input.size = Vector2(480, 46)
	voice_input.placeholder_text = "wss://seu-servidor-de-voz.example"
	voice_input.text_submitted.connect(func(value: String): voice_url_changed.emit(value.strip_edges()))
	voice_input.focus_exited.connect(func(): voice_url_changed.emit(voice_input.text.strip_edges()))
	p.add_child(voice_input)
	_label(p, "Precisa de servidor próprio; não conecta ao SA-MP.", Rect2(28, 479, 478, 25), 14)
	_button(p, "SALVAR E VOLTAR", Rect2(27, 520, 484, 52), "CLOSE_SETTINGS")
	return root

func _make_appearance() -> Control:
	var root := _root(true)
	root.visible = false
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.0, 0.008, 0.02, 0.88)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(veil)
	var card := _panel(root, Rect2(175, 62, 930, 602), Color(0.022, 0.04, 0.075, 0.99))
	card.name = "AppearanceCard"
	_label(card, "CRIAÇÃO DE PERSONAGEM", Rect2(28, 16, 820, 48), 28)
	_label(card, "Visual oficial do Cidade Lexus RP • Jogador local", Rect2(28, 61, 820, 30), 16)
	# A live 3D preview of exactly the model used during gameplay.
	var preview_frame := Panel.new()
	preview_frame.position = Vector2(25, 100)
	preview_frame.size = Vector2(472, 445)
	preview_frame.add_theme_stylebox_override("panel", _style(Color(0.04, 0.07, 0.11, 1.0)))
	card.add_child(preview_frame)
	var scene_container := SubViewportContainer.new()
	scene_container.position = Vector2(6, 6)
	scene_container.size = Vector2(460, 433)
	scene_container.stretch = true
	scene_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_frame.add_child(scene_container)
	var view := SubViewport.new()
	view.size = Vector2i(460, 433)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	view.gui_disable_input = true
	scene_container.add_child(view)
	var stage := Node3D.new()
	view.add_child(stage)
	var ambiance := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.11, 0.15, 0.20, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.90, 0.97)
	env.ambient_light_energy = 0.70
	ambiance.environment = env
	stage.add_child(ambiance)
	var keylight := DirectionalLight3D.new()
	keylight.rotation_degrees = Vector3(-48, 20, 0)
	keylight.light_energy = 1.75
	stage.add_child(keylight)
	var portrait_camera := Camera3D.new()
	portrait_camera.fov = 43.0
	portrait_camera.position = Vector3(0, 1.45, -4.40)
	stage.add_child(portrait_camera)
	portrait_camera.look_at(Vector3(0, 1.17, 0), Vector3.UP)
	portrait_camera.current = true
	preview_human = Humanoid.new()
	stage.add_child(preview_human)
	var label := _label(card, "ROUPAS", Rect2(523, 123, 350, 30), 18)
	avatar_outfit = OptionButton.new()
	avatar_outfit.position = Vector2(523, 158)
	avatar_outfit.size = Vector2(366, 50)
	avatar_outfit.add_item("Lexus Street • Preta")
	avatar_outfit.add_item("Lexus Urban • Vermelha")
	avatar_outfit.add_item("Lexus Night • Azul")
	avatar_outfit.item_selected.connect(_appearance_preview_changed)
	card.add_child(avatar_outfit)
	_label(card, "TOM DE PELE", Rect2(523, 226, 350, 30), 18)
	avatar_skin = OptionButton.new()
	avatar_skin.position = Vector2(523, 260)
	avatar_skin.size = Vector2(366, 49)
	for tone in ["Morena escura", "Morena", "Bronzeada", "Clara"]:
		avatar_skin.add_item(tone)
	avatar_skin.item_selected.connect(_appearance_preview_changed)
	card.add_child(avatar_skin)
	_label(card, "COR DO CABELO", Rect2(523, 328, 350, 30), 18)
	avatar_hair = OptionButton.new()
	avatar_hair.position = Vector2(523, 361)
	avatar_hair.size = Vector2(366, 49)
	for style in ["Preto natural", "Castanho", "Prateado", "Preto azulado"]:
		avatar_hair.add_item(style)
	avatar_hair.item_selected.connect(_appearance_preview_changed)
	card.add_child(avatar_hair)
	avatar_note = _label(card, "Selecione a aparência. A roupa deve estar liberada na loja de skins.", Rect2(520, 432, 368, 65), 15)
	var save_btn := _button(card, "SALVAR PERSONAGEM", Rect2(523, 504, 366, 60), "", true)
	save_btn.pressed.connect(_commit_appearance)
	_button(card, "VOLTAR", Rect2(25, 554, 472, 37), "CLOSE_APPEARANCE")
	return root

func _appearance_preview_changed(_index: int) -> void:
	if preview_human != null:
		preview_human.call("apply_appearance", avatar_outfit.selected, avatar_skin.selected, avatar_hair.selected)
	if avatar_note != null:
		avatar_note.text = "Pré-visualização. Roupa escolhida precisa estar desbloqueada."

func _commit_appearance() -> void:
	appearance_changed.emit(avatar_outfit.selected, avatar_skin.selected, avatar_hair.selected)

func update_appearance(outfit: int, skin_tone: int, hair_tone: int) -> void:
	if avatar_outfit == null:
		return
	avatar_outfit.select(clampi(outfit, 0, 2))
	avatar_skin.select(clampi(skin_tone, 0, 3))
	avatar_hair.select(clampi(hair_tone, 0, 3))
	_appearance_preview_changed(0)

func open_appearance() -> void:
	appearance_panel.visible = true
	_appearance_preview_changed(0)

func close_appearance() -> void:
	appearance_panel.visible = false

func _make_info_panel() -> Control:
	var root := _root(true)
	root.visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.03, 0.74)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var card := _panel(root, Rect2(370, 135, 540, 455), Color(0.03, 0.055, 0.09, 0.98))
	card.name = "InfoCard"
	_label(card, "MOCHILA • VIDA RP", Rect2(26, 24, 475, 43), 27)
	var details := _label(card, "", Rect2(26, 89, 480, 300), 19)
	details.name = "Details"
	_button(card, "FECHAR", Rect2(24, 387, 490, 49), "CLOSE_INFO")
	return root

func _make_death_panel() -> Control:
	var root := _root(true)
	root.visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.17, 0.015, 0.018, 0.76)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var card := _panel(root, Rect2(355, 175, 570, 335), Color(0.06, 0.02, 0.03, 0.92))
	card.name = "DeathCard"
	_label(card, "VOCÊ ESTÁ FERIDO", Rect2(40, 28, 490, 55), 34)
	_label(card, "Seu personagem foi incapacitado.\nUse o atendimento médico para reviver no hospital.\nModo demonstração: não há SAMU online.", Rect2(40, 105, 495, 112), 20)
	_button(card, "REVIVER NO HOSPITAL", Rect2(40, 240, 490, 62), "REVIVE", true)
	return root

func _submit_chat(text: String) -> void:
	var t := text.strip_edges()
	chat_line.text = ""
	chat_line.visible = false
	if t != "":
		command_entered.emit(t)

func update_hud(life: float, stamina_value: float, armour_value: float, money: int, location_name: String, ammo: int, reserve: int, is_car: bool, kmh: int, job_text: String, fuel_value: float = 0.0) -> void:
	hp.value = life
	stamina.value = stamina_value
	armor.value = armour_value
	location.text = location_name
	cash_label.text = "R$ %d" % money
	ammo_label.text = "PISTOLA • %d / %d" % [ammo, reserve]
	speed_label.text = ("CARRO • %d KM/H • %d%% combustível" % [kmh, int(fuel_value)]) if is_car else "A PÉ • LEXUS RP"
	job_label.text = job_text

func set_voice_status(value: String) -> void:
	if voice_label != null:
		voice_label.text = value

func flash_reticle(hit: bool) -> void:
	if crosshair_label != null:
		crosshair_label.modulate = Color(0.22, 0.95, 0.30) if hit else Color(1.0, 0.55, 0.21)
		reticle_timer = 0.13

func update_minimap(pos: Vector3, angle: float, cars: Array, npcs: Array, driving: bool) -> void:
	minimap.refresh(pos, angle, cars, npcs, driving)
	if map_surface != null:
		map_surface.refresh(pos, angle, cars, npcs, driving)

func show_toast(text: String) -> void:
	toast.text = text
	toast.visible = true
	toast_time = 3.0

func set_screen(name: String) -> void:
	menu.visible = name == "menu"
	loading.visible = name == "loading"
	hud.visible = name == "game"
	settings_panel.visible = false
	appearance_panel.visible = false
	info_panel.visible = false
	death_panel.visible = false
	actions_panel.visible = false
	map_panel.visible = false
	chat_line.visible = false

func set_loading(value: float, status: String) -> void:
	loading_bar.value = value
	loading_text.text = "%s • %d%%" % [status, int(value)]

func open_settings() -> void:
	settings_panel.visible = true

func close_settings() -> void:
	settings_panel.visible = false

func open_info(text: String) -> void:
	info_panel.visible = true
	var label := info_panel.get_node("InfoCard/Details") as Label
	label.text = text

func close_info() -> void:
	info_panel.visible = false

func open_chat() -> void:
	chat_line.visible = true
	chat_line.grab_focus()

func show_death() -> void:
	death_panel.visible = true

func hide_death() -> void:
	death_panel.visible = false

func update_settings(level: int, camera_sens: float, camera_dist: float = 3.05) -> void:
	quality_opt.select(clampi(level, 0, 2))
	mouse_opt.value = camera_sens
	camera_distance_opt.value = camera_dist

func update_voice_url(value: String) -> void:
	if voice_input != null:
		voice_input.text = value

func _relayout() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp == _last_size:
		return
	_last_size = vp
	var menucard := menu.get_node("MenuCard") as Panel
	var menu_scale := minf(1.0, minf((vp.y - 28.0) / 590.0, (vp.x * 0.75 - 30.0) / 520.0))
	menu_scale = maxf(0.40, menu_scale)
	menucard.scale = Vector2.ONE * menu_scale
	menucard.position = Vector2(maxf(14.0, vp.x * 0.034), (vp.y - 590.0 * menu_scale) * 0.5)
	shade.size = Vector2(minf(vp.x, menucard.position.x + 520.0 * menu_scale + 46.0), vp.y)
	var loading_card := loading.get_node("LoadingCard") as Panel
	loading_card.scale = Vector2.ONE * minf(1.0, minf((vp.x - 24.0) / loading_card.size.x, (vp.y - 24.0) / loading_card.size.y))
	loading_card.position = (vp - loading_card.size * loading_card.scale) * 0.5
	var settings_card := settings_panel.get_node("SettingsCard") as Panel
	settings_card.scale = Vector2.ONE * minf(1.0, minf((vp.x - 24.0) / settings_card.size.x, (vp.y - 24.0) / settings_card.size.y))
	settings_card.position = (vp - settings_card.size * settings_card.scale) * 0.5
	var avatar_card := appearance_panel.get_node("AppearanceCard") as Panel
	avatar_card.scale = Vector2.ONE * minf(1.0, minf((vp.x - 24.0) / avatar_card.size.x, (vp.y - 24.0) / avatar_card.size.y))
	avatar_card.position = (vp - avatar_card.size * avatar_card.scale) * 0.5
	var info_card := info_panel.get_node("InfoCard") as Panel
	info_card.scale = Vector2.ONE * minf(1.0, minf((vp.x - 24.0) / info_card.size.x, (vp.y - 24.0) / info_card.size.y))
	info_card.position = (vp - info_card.size * info_card.scale) * 0.5
	var death_card := death_panel.get_node("DeathCard") as Panel
	death_card.scale = Vector2.ONE * minf(1.0, minf((vp.x - 24.0) / death_card.size.x, (vp.y - 24.0) / death_card.size.y))
	death_card.position = (vp - death_card.size * death_card.scale) * 0.5
	var action_card := actions_panel.get_node("ActionCard") as Panel
	action_card.scale = Vector2.ONE * minf(1.0, minf((vp.x - 24.0) / action_card.size.x, (vp.y - 24.0) / action_card.size.y))
	action_card.position = (vp - action_card.size * action_card.scale) * 0.5
	var map_card := map_panel.get_node("MapCard") as Panel
	map_card.scale = Vector2.ONE * minf(1.0, minf((vp.x - 24.0) / map_card.size.x, (vp.y - 24.0) / map_card.size.y))
	map_card.position = (vp - map_card.size * map_card.scale) * 0.5
	movement.position = Vector2(20, vp.y - 210)
	minimap.position = Vector2(vp.x - 188, 12)
	cash_label.position = Vector2(vp.x - 440, 19)
	ammo_label.position = Vector2(vp.x - 440, 62)
	speed_label.position = Vector2(vp.x - 440, 103)
	job_label.position = Vector2(vp.x - 440, 143)
	voice_label.position = Vector2(vp.x - 440, 181)
	gps_label.position = Vector2(maxf(380.0, vp.x * 0.35), 74)
	alert_label.position = Vector2(vp.x * 0.34, 20)
	toast.position = Vector2((vp.x - 610) * 0.5, 92)
	var right := vp.x
	var bottom := vp.y
	buttons["RUN"].position = Vector2(right - 380, bottom - 82)
	buttons["JUMP"].position = Vector2(right - 260, bottom - 155)
	buttons["CROUCH"].position = Vector2(right - 145, bottom - 84)
	buttons["FIRE"].position = Vector2(right - 150, bottom - 253)
	buttons["RELOAD"].position = Vector2(right - 284, bottom - 237)
	buttons["INTERACT"].position = Vector2(right - 450, bottom - 160)
	buttons["ITEMS"].position = Vector2(right - 332, bottom - 303)
	buttons["CHAT"].position = Vector2(right - 450, bottom - 303)
	buttons["MENU"].position = Vector2(390, 17)
	buttons["MAP"].position = Vector2(502, 17)
	buttons["SIREN"].position = Vector2(right - 700, bottom - 315)
	organization_label.position = Vector2(vp.x - 440, 210)
	interaction_hint.position = Vector2((vp.x - 530) * 0.5, vp.y - 80)
	buttons["VOICE_CONNECT"].position = Vector2(right - 572, bottom - 382)
	buttons["VOICE_PTT"].position = Vector2(right - 572, bottom - 321)
	chat_line.position = Vector2((vp.x - 480) * 0.5, bottom - 82)
	var cross := hud.get_node("Crosshair") as Label
	cross.position = (vp - cross.size) * 0.5

func _make_actions_panel() -> Control:
	var root := _root(true)
	root.visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.015, 0.028, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var card := _panel(root, Rect2(350, 76, 580, 580), Color(0.020, 0.035, 0.061, 0.98))
	card.name = "ActionCard"
	actions_title = _label(card, "INTERAGIR", Rect2(22, 17, 535, 50), 28)
	actions_subtitle = _label(card, "Selecione uma opcao", Rect2(22, 67, 525, 58), 17)
	var scroll := ScrollContainer.new()
	scroll.name = "ActionScroll"
	scroll.position = Vector2(24, 130)
	scroll.size = Vector2(530, 370)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	actions_container = VBoxContainer.new()
	actions_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_container.custom_minimum_size = Vector2(505, 0)
	actions_container.add_theme_constant_override("separation", 10)
	scroll.add_child(actions_container)
	_button(card, "FECHAR", Rect2(24, 515, 530, 48), "CLOSE_ACTIONS")
	return root

func _make_map_panel() -> Control:
	var root := _root(true)
	root.visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.015, 0.028, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var card := _panel(root, Rect2(180, 50, 920, 620), Color(0.02, 0.035, 0.060, 0.98))
	card.name = "MapCard"
	_label(card, "MAPA • TRÊS CIDADES", Rect2(24, 18, 700, 45), 27)
	map_surface = Minimap.new()
	map_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	map_surface.allow_waypoint = true
	map_surface.waypoint_selected.connect(func(pos: Vector3): gps_selected.emit(pos))
	map_surface.name = "BigMap"
	map_surface.map_radius = 1050.0
	map_surface.position = Vector2(24, 82)
	map_surface.size = Vector2(670, 480)
	card.add_child(map_surface)
	_button(card, "+ ZOOM", Rect2(724, 96, 170, 54), "MAP_IN")
	_button(card, "- ZOOM", Rect2(724, 170, 170, 54), "MAP_OUT")
	_button(card, "DUQUE DE CAXIAS", Rect2(714, 235, 180, 42), "GPS_DUQUE")
	_button(card, "CIDADE DE DEUS", Rect2(714, 288, 180, 42), "GPS_CDD")
	_button(card, "ZONA NORTE", Rect2(714, 341, 180, 42), "GPS_NORTE")
	_button(card, "REMOVER GPS", Rect2(724, 424, 170, 54), "GPS_CLEAR")
	_button(card, "FECHAR MAPA", Rect2(724, 496, 170, 60), "CLOSE_MAP")
	_label(card, "PONTE → CIDADE DE DEUS → TÚNEL → ZONA NORTE", Rect2(24, 570, 850, 34), 16)
	return root

func show_actions(title: String, subtitle: String, choices: Array) -> void:
	actions_title.text = title
	actions_subtitle.text = subtitle
	for node in actions_container.get_children():
		actions_container.remove_child(node)
		node.queue_free()
	for item in choices:
		var text_value := str(item.get("label", "Acao"))
		var choice_id := str(item.get("id", ""))
		if choice_id == "":
			continue
		var button := Button.new()
		button.text = text_value
		button.custom_minimum_size = Vector2(480, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_stylebox_override("normal", _style(Color(0.07, 0.10, 0.16, 0.97)))
		button.add_theme_stylebox_override("hover", _style(Color(0.16, 0.21, 0.32, 0.98)))
		button.pressed.connect(_choose_action.bind(choice_id))
		actions_container.add_child(button)
	map_panel.visible = false
	actions_panel.visible = true

func _choose_action(choice_id: String) -> void:
	interaction_selected.emit(choice_id)

func close_actions() -> void:
	actions_panel.visible = false

func open_full_map() -> void:
	actions_panel.visible = false
	map_panel.visible = true
	if map_surface != null:
		map_surface.queue_redraw()

func close_full_map() -> void:
	map_panel.visible = false

func zoom_full_map(zoom_in: bool) -> void:
	if map_surface == null:
		return
	map_surface.map_radius = clampf(map_surface.map_radius * (0.72 if zoom_in else 1.36), 90.0, 2000.0)
	map_surface.queue_redraw()

func set_context_hint(message: String) -> void:
	if interaction_hint != null:
		interaction_hint.text = message

func set_organization(name: String) -> void:
	if organization_label != null:
		organization_label.text = "ORGANIZACAO: " + name

func update_landmarks(points: Array) -> void:
	if minimap != null:
		minimap.set_landmarks(points)
	if map_surface != null:
		map_surface.set_landmarks(points)

func set_climate_info(hour: float, weather: String, auto: bool) -> void:
	if climate_label != null:
		var hh := int(floor(hour))
		var mm := int(floor((hour - float(hh)) * 60.0))
		climate_label.text = "%02d:%02d  •  %s  •  %s" % [hh, mm, weather, "AUTO" if auto else "FIXO"]

func update_gps(active: bool, world_position: Vector3, focus_position: Vector3) -> void:
	minimap.set_waypoint(active, world_position)
	if map_surface != null:
		map_surface.set_waypoint(active, world_position)
	if gps_label != null:
		if active:
			var meters := Vector2(focus_position.x, focus_position.z).distance_to(Vector2(world_position.x, world_position.z))
			gps_label.text = "GPS: %.0f m até o destino" % meters
		else:
			gps_label.text = "GPS: sem destino"
