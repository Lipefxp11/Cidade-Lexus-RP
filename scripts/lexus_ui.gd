extends CanvasLayer

signal play_pressed
signal quality_changed(level: int)
signal sensitivity_changed(level: float)
signal voice_url_changed(url: String)
signal action_pressed(action: String)
signal move_changed(direction: Vector2)
signal command_entered(command: String)

const Joystick = preload("res://scripts/virtual_joystick.gd")
const Minimap = preload("res://scripts/lexus_minimap.gd")
const BG_PATH = "res://assets/background_ui_v12.png"

var menu: Control
var loading: Control
var hud: Control
var settings_panel: Control
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
var voice_input: LineEdit
var main_title: Label
var server_opt: OptionButton
var _last_size := Vector2.ZERO
var shade: ColorRect
var play_btn: Button
var settings_btn: Button

func _ready() -> void:
	menu = _make_menu()
	loading = _make_loading()
	hud = _make_hud()
	settings_panel = _make_settings()
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
	_label(card, "BRASIL  /  RIO DE JANEIRO  /  V17", Rect2(27, 180, 464, 27), 16)
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
	play_btn = _button(card, "JOGAR", Rect2(27, 397, 465, 72), "PLAY", true)
	play_btn.name = "PlayButton"
	play_btn.add_theme_font_size_override("font_size", 29)
	settings_btn = _button(card, "CONFIGURAÇÕES", Rect2(27, 484, 465, 58), "SETTINGS")
	settings_btn.name = "SettingsButton"
	_label(card, "ANDROID  •  HORIZONTAL  •  PROTÓTIPO OFFLINE", Rect2(27, 553, 464, 25), 13)
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
	cash_label = _label(root, "R$ 500", Rect2(810, 17, 250, 35), 21)
	ammo_label = _label(root, "PISTOLA • 12 / 60", Rect2(810, 60, 260, 33), 17)
	speed_label = _label(root, "A PÉ", Rect2(810, 102, 270, 33), 18)
	job_label = _label(root, "TRABALHO: DISPONÍVEL", Rect2(810, 144, 300, 33), 15)
	voice_label = _label(root, "VOZ: OFFLINE", Rect2(810, 181, 300, 26), 16)
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
	buttons["INTERACT"] = _button(root, "USAR / ENTRAR", Rect2(0, 0, 172, 58), "INTERACT")
	buttons["ITEMS"] = _button(root, "MOCHILA", Rect2(0, 0, 108, 49), "ITEMS")
	buttons["CHAT"] = _button(root, "CHAT RP", Rect2(0, 0, 105, 49), "CHAT")
	buttons["MENU"] = _button(root, "MENU", Rect2(0, 0, 103, 49), "MENU")
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
	var p := _panel(root, Rect2(370, 90, 540, 515), Color(0.035, 0.06, 0.09, 0.98))
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
	_label(p, "Servidor VoIP experimental (wss://)", Rect2(28, 308, 480, 30), 18)
	voice_input = LineEdit.new()
	voice_input.position = Vector2(28, 343)
	voice_input.size = Vector2(480, 46)
	voice_input.placeholder_text = "wss://seu-servidor-de-voz.example"
	voice_input.text_submitted.connect(func(value: String): voice_url_changed.emit(value.strip_edges()))
	voice_input.focus_exited.connect(func(): voice_url_changed.emit(voice_input.text.strip_edges()))
	p.add_child(voice_input)
	_label(p, "Precisa de servidor próprio; não conecta ao SA-MP.", Rect2(28, 399, 478, 25), 14)
	_button(p, "SALVAR E VOLTAR", Rect2(27, 440, 484, 52), "CLOSE_SETTINGS")
	return root

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

func show_toast(text: String) -> void:
	toast.text = text
	toast.visible = true
	toast_time = 3.0

func set_screen(name: String) -> void:
	menu.visible = name == "menu"
	loading.visible = name == "loading"
	hud.visible = name == "game"
	settings_panel.visible = false
	info_panel.visible = false
	death_panel.visible = false
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

func update_settings(level: int, camera_sens: float) -> void:
	quality_opt.select(clampi(level, 0, 2))
	mouse_opt.value = camera_sens

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
	var info_card := info_panel.get_node("InfoCard") as Panel
	info_card.scale = Vector2.ONE * minf(1.0, minf((vp.x - 24.0) / info_card.size.x, (vp.y - 24.0) / info_card.size.y))
	info_card.position = (vp - info_card.size * info_card.scale) * 0.5
	var death_card := death_panel.get_node("DeathCard") as Panel
	death_card.scale = Vector2.ONE * minf(1.0, minf((vp.x - 24.0) / death_card.size.x, (vp.y - 24.0) / death_card.size.y))
	death_card.position = (vp - death_card.size * death_card.scale) * 0.5
	movement.position = Vector2(20, vp.y - 210)
	minimap.position = Vector2(vp.x - 188, 12)
	cash_label.position = Vector2(vp.x - 440, 19)
	ammo_label.position = Vector2(vp.x - 440, 62)
	speed_label.position = Vector2(vp.x - 440, 103)
	job_label.position = Vector2(vp.x - 440, 143)
	voice_label.position = Vector2(vp.x - 440, 181)
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
	buttons["VOICE_CONNECT"].position = Vector2(right - 572, bottom - 382)
	buttons["VOICE_PTT"].position = Vector2(right - 572, bottom - 321)
	chat_line.position = Vector2((vp.x - 480) * 0.5, bottom - 82)
	var cross := hud.get_node("Crosshair") as Label
	cross.position = (vp - cross.size) * 0.5
