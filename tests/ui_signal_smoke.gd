extends SceneTree

# Menu-level action wiring test, executed headlessly by GitHub Actions.
# This cannot reproduce a physical Android touchscreen; run device QA separately.
func _initialize() -> void:
	call_deferred("_check_menu")

func _check_menu() -> void:
	var ui_script = load("res://scripts/lexus_ui.gd")
	if ui_script == null:
		printerr("V15 UI test: lexus_ui.gd unavailable")
		quit(1)
		return
	var ui = ui_script.new()
	root.add_child(ui)
	await process_frame
	var play: Button = ui.menu.get_node_or_null("MenuCard/PlayButton") as Button
	var settings: Button = ui.menu.get_node_or_null("MenuCard/SettingsButton") as Button
	var selector: OptionButton = ui.menu.get_node_or_null("MenuCard/ServerSelector") as OptionButton
	if play == null or settings == null or selector == null:
		printerr("V15 UI test: a menu button or server selector is missing")
		quit(1)
		return
	if ui.menu.mouse_filter != Control.MOUSE_FILTER_PASS:
		printerr("V15 UI test: menu root mouse filter is incorrect")
		quit(1)
		return
	if not Input.emulate_mouse_from_touch:
		printerr("V15 UI test: Android touch-to-mouse emulation is disabled")
		quit(1)
		return
	var received: Array[String] = []
	ui.action_pressed.connect(func(action: String): received.append(action))
	play.pressed.emit()
	settings.pressed.emit()
	if received != ["PLAY", "SETTINGS"]:
		printerr("V15 UI test: actions were not emitted: ", received)
		quit(1)
		return
	if selector.item_count != 1:
		printerr("V15 UI test: unexpected nonfunctional server choices")
		quit(1)
		return
	print("V15 UI test OK: PLAY and SETTINGS connected; touch emulation enabled")
	quit(0)
