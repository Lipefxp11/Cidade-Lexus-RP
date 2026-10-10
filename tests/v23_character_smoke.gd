extends SceneTree

# V23: garante o novo protagonista ao inves do modelo antigo ou fallback procedural.
func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var model := load("res://assets/models/character.glb") as PackedScene
    if model == null:
        printerr("V23 ERROR: GLB do personagem nao importado")
        quit(1)
        return
    var model_instance := model.instantiate() as Node3D
    if model_instance == null:
        printerr("V23 ERROR: GLB nao gerou Node3D")
        quit(1)
        return
    root.add_child(model_instance)
    var expected := [
        "LexusRig", "LexusChest", "LexusHead", "LexusLeftArm", "LexusRightArm",
        "LexusLeftHand", "LexusRightHand", "LexusLeftLeg", "LexusRightLeg",
        "LexusLeftShin", "LexusRightShin", "LexusLeftFoot", "LexusRightFoot"
    ]
    for part in expected:
        if model_instance.find_child(part, true, false) == null:
            printerr("V23 ERROR: falta articulacao: ", part)
            quit(1)
            return
    var humanoid_script = load("res://scripts/humanoid.gd")
    if humanoid_script == null:
        printerr("V23 ERROR: humanoid.gd nao compila")
        quit(1)
        return
    var body = humanoid_script.new()
    root.add_child(body)
    await process_frame
    if body.character_version != "LEXUS_URBANO_02":
        printerr("V23 ERROR: versao incorreta do personagem")
        quit(1)
        return
    if not body.official_model_active:
        printerr("V23 ERROR: novo GLB nao esta ativo; fallback indevido")
        quit(1)
        return
    body.apply_appearance(1, 2, 0)
    body.update_pose(0.016, 0.0, false, false)
    body.update_pose(0.016, 1.3, false, false)
    body.update_pose(0.016, 0.7, true, true, 0.5)
    if body.outfit_index != 1 or body.skin_tone_index != 2:
        printerr("V23 ERROR: personalizacao nao persistiu no personagem")
        quit(1)
        return
    print("V23 PERSONAGEM OK: Lexus Urbano 02 importado, controles preservados")
    quit(0)
