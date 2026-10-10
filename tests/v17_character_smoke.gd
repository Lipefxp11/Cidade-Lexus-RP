extends SceneTree

# Validates that the ORIGINAL character.glb is imported and the game script uses it.
# Test runs on GitHub Actions after the Godot editor has imported the GLB.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed := load("res://assets/models/character.glb") as PackedScene
	if packed == null:
		printerr("V17 character: character.glb could not be imported as a PackedScene")
		quit(1)
		return
	var humanoid_script = load("res://scripts/humanoid.gd")
	if humanoid_script == null:
		printerr("V17 character: humanoid.gd could not be parsed")
		quit(1)
		return
	var body = humanoid_script.new()
	root.add_child(body)
	await process_frame
	if body.realistic_model_active:
		if body.imported_animation == null:
			printerr("V19 character: realistic model missing animation player")
			quit(1)
			return
		body.update_pose(0.016, 0.0, false, false)
		body.update_pose(0.016, 1.3, false, false)
		body.update_pose(0.016, 0.4, true, false)
		print("V19 character smoke OK: real human, skinned GLB, animation clips")
		quit(0)
		return
	if not body.official_model_active:
		printerr("V17 character: Lexus Urbano 01 was not selected as the default model")
		quit(1)
		return
	var required := ["LexusHead", "LexusLeftArm", "LexusRightArm", "LexusLeftLeg", "LexusRightLeg", "LexusLeftShin", "LexusRightShin"]
	for part_name in required:
		if not body.imported_parts.has(part_name):
			printerr("V17 character: missing articulated part ", part_name)
			quit(1)
			return
	body.update_pose(0.016, 0.0, false, false)
	body.update_pose(0.016, 1.3, false, false)
	body.update_pose(0.016, 0.2, true, false)
	body.update_pose(0.016, 0.0, false, true, 1.0)
	body.update_pose(0.016, 0.0, false, false, 0.0, true)
	body.update_pose(0.016, 0.0, false, false, 0.0, false, true)
	print("V17 character smoke OK: official GLB, animated joints, walking, sprinting, crouching, aiming, jumping and falling")
	quit(0)
