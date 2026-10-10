extends SceneTree

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var model_path := "res://assets/models/hero_realistic.glb"
	var scene := load(model_path) as PackedScene
	if scene == null:
		printerr("V19 REAL HUMAN ERROR: imported GLB unavailable")
		quit(1)
		return
	var inst := scene.instantiate() as Node3D
	if inst == null:
		printerr("V19 REAL HUMAN ERROR: GLB did not instantiate as Node3D")
		quit(1)
		return
	if inst.find_children("*", "Skeleton3D", true, false).is_empty():
		printerr("V19 REAL HUMAN ERROR: skeleton missing")
		inst.free()
		quit(1)
		return
	if inst.find_children("*", "AnimationPlayer", true, false).is_empty():
		printerr("V19 REAL HUMAN ERROR: AnimationPlayer missing")
		inst.free()
		quit(1)
		return
	inst.free()
	var body = load("res://scripts/humanoid.gd").new()
	root.add_child(body)
	await process_frame
	if not body.realistic_model_active:
		printerr("V19 REAL HUMAN ERROR: game did not choose the realistic skinned character")
		quit(1)
		return
	if body.imported_animation == null or body.imported_animation.get_animation_list().size() < 2:
		printerr("V19 REAL HUMAN ERROR: no useful animations available")
		quit(1)
		return
	body.update_pose(0.016, 0.0, false, false)
	body.update_pose(0.016, 0.6, false, false)
	body.update_pose(0.016, 1.4, false, false)
	print("V19 REAL HUMAN OK: skin rig, animation and default selection")
	quit(0)
