extends SceneTree

# Headless wiring test. Requires Godot; does not validate Android hardware.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var ui_source = load("res://scripts/lexus_ui.gd")
	if ui_source == null:
		printerr("V16 test: no UI script")
		quit(1)
		return
	var ui = ui_source.new()
	root.add_child(ui)
	await process_frame
	var fire: Button = ui.buttons.get("FIRE") as Button
	var ptt: Button = ui.buttons.get("VOICE_PTT") as Button
	var connect_button: Button = ui.buttons.get("VOICE_CONNECT") as Button
	if fire == null or ptt == null or connect_button == null:
		printerr("V16 test: fire or voice buttons missing")
		quit(1)
		return
	var received: Array[String] = []
	ui.action_pressed.connect(func(action: String): received.append(action))
	fire.button_down.emit()
	fire.button_up.emit()
	ptt.button_down.emit()
	ptt.button_up.emit()
	connect_button.pressed.emit()
	if received != ["FIRE_DOWN", "FIRE_UP", "VOICE_DOWN", "VOICE_UP", "VOICE_CONNECT"]:
		printerr("V16 test: input signals invalid: ", received)
		quit(1)
		return
	if not (ui.voice_input is LineEdit):
		printerr("V16 test: voice server input missing")
		quit(1)
		return
	var world_code = load("res://scripts/city_world.gd")
	if world_code == null:
		printerr("V16 test: world streaming script missing")
		quit(1)
		return
	print("V16 input test OK: firing, push-to-talk, settings, world script")
	quit(0)
