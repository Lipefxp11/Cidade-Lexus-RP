extends SceneTree

# CI: valida cenários físicos, pontos RP, veículos e menus sem simular multiplayer.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world_script = load("res://scripts/city_world.gd")
	var vehicle_script = load("res://scripts/lexus_vehicle.gd")
	var interior_script = load("res://scripts/lexus_interiors.gd")
	var ui_script = load("res://scripts/lexus_ui.gd")
	if world_script == null or vehicle_script == null or interior_script == null or ui_script == null:
		_fail("algum script V18 nao carregou")
		return
	var world = world_script.new()
	root.add_child(world)
	await process_frame
	var dealership: Dictionary = world.nearest_interactable(Vector3(24, 0, -14.7), 7.0)
	if dealership.get("type", "") != "dealer":
		_fail("concessionaria nao foi registrada no mapa")
		return
	world.ensure_chunk_at(Vector3(-80, 0, 0))
	await process_frame
	var hill_cells: Array = world.find_children("Morro_Colisao", "StaticBody3D", true, false)
	if hill_cells.is_empty():
		_fail("morro fisico da favela nao existe")
		return
	var inside = interior_script.new()
	root.add_child(inside)
	inside.open_house("casa_teste")
	if not inside.visible or not inside.near_exit(inside.interior_origin + inside.door_position):
		_fail("interior ou porta de saida falhou")
		return
	inside.close_house()
	var vehicle = vehicle_script.new()
	vehicle.model_type = "samu"
	vehicle.car_name = "SAMU TESTE"
	vehicle.organization = "SAMU"
	vehicle.paint_color = Color.WHITE
	root.add_child(vehicle)
	await process_frame
	vehicle.toggle_siren()
	if not vehicle.siren_active or not vehicle.upgrade_engine() or vehicle.engine_level != 1:
		_fail("ambulancia ou tunagem falhou")
		return
	var ui = ui_script.new()
	root.add_child(ui)
	await process_frame
	ui.show_actions("CONCESSIONARIA", "Teste", [{"id":"dealer_sedan", "label":"COMPRAR"}])
	if not ui.actions_panel.visible:
		_fail("menu F nao foi aberto")
		return
	ui.close_actions()
	ui.open_full_map()
	if not ui.map_panel.visible:
		_fail("mapa expansivel nao abriu")
		return
	ui.close_full_map()
	print("V18 smoke OK: favela+colisao, concessionaria, interior, SAMU, tunagem, menu F, mapa ampliado")
	quit(0)

func _fail(message: String) -> void:
	printerr("V18 SYSTEM ERROR: " + message)
	quit(1)
