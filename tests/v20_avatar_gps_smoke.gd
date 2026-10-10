extends SceneTree

func _initialize() -> void:
    call_deferred("_test")

func _fail(reason: String) -> void:
    printerr("V20 SMOKE ERROR: " + reason)
    quit(1)

func _test() -> void:
    var humanoid_script = load("res://scripts/humanoid.gd")
    var hud_script = load("res://scripts/lexus_ui.gd")
    if humanoid_script == null or hud_script == null:
        _fail("Missing game scripts")
        return
    var body = humanoid_script.new()
    root.add_child(body)
    await process_frame
    if not body.official_model_active and not body.realistic_model_active:
        _fail("Neither packaged GLB nor optional human imported")
        return
    body.apply_appearance(2, 3, 2)
    if body.outfit_index != 2 or body.skin_tone_index != 3 or body.hair_style_index != 2:
        _fail("Appearance not stored in humanoid")
        return
    var hud = hud_script.new()
    root.add_child(hud)
    await process_frame
    if hud.appearance_panel == null or hud.preview_human == null:
        _fail("Character preview not built")
        return
    var avatar_button = hud.menu.get_node_or_null("MenuCard/AppearanceButton")
    if avatar_button == null:
        _fail("Avatar button missing")
        return
    hud.open_appearance()
    if not hud.appearance_panel.visible:
        _fail("Character window not visible")
        return
    hud.update_appearance(0, 1, 1)
    var got: Array[int] = []
    hud.appearance_changed.connect(func(style: int, skin: int, hair: int): got.assign([style, skin, hair]))
    hud._commit_appearance()
    if got != [0, 1, 1]:
        _fail("Appearance save signal failed")
        return
    hud.close_appearance()
    hud.set_screen("game")
    hud.open_full_map()
    var selected: Array[Vector3] = []
    hud.gps_selected.connect(func(world: Vector3): selected.append(world))
    hud.map_surface.waypoint_selected.emit(Vector3(38, 0, 72))
    if selected.size() != 1 or selected[0].x != 38:
        _fail("GPS on expanded map failed")
        return
    hud.update_gps(true, Vector3(38, 0, 72), Vector3.ZERO)
    if "sem destino" in hud.gps_label.text:
        _fail("GPS label not refreshed")
        return
    print("V20 TEST OK: bundled character, wardrobe, preview, save signal and GPS")
    quit(0)
