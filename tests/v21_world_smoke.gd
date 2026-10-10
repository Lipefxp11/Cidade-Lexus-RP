extends SceneTree

const Geo = preload("res://scripts/lexus_geography.gd")
const MapScript = preload("res://scripts/lexus_minimap.gd")
const WorldScript = preload("res://scripts/city_world.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if Geo.city_name(Vector3.ZERO) != "DUQUE DE CAXIAS":
		_fail("cidade inicial invalida")
		return
	if Geo.city_name(Vector3(0, 0, 550)) != "CIDADE DE DEUS":
		_fail("cidade depois da ponte invalida")
		return
	if Geo.city_name(Vector3(860, 0, 550)) != "ZONA NORTE":
		_fail("zona norte nao existe")
		return
	if not Geo.is_bridge_cell(Vector2i(0, 4)) or Geo.is_bridge_cell(Vector2i(2, 4)):
		_fail("ponte ou rio inconsistentes")
		return
	if not Geo.is_tunnel_cell(Vector2i(8, 7)):
		_fail("tunel nao conectado ao corredor leste")
		return
	var world = WorldScript.new()
	root.add_child(world)
	await process_frame
	world.ensure_chunk_at(Vector3(0, 0, 320))
	await process_frame
	var bridge = world.loaded_chunks.get(Vector2i(0, 4))
	if bridge == null or bridge.get_node_or_null("PonteColisao") == null:
		_fail("colisao da ponte ausente")
		return
	world.ensure_chunk_at(Vector3(80, 0, 320))
	await process_frame
	var river = world.loaded_chunks.get(Vector2i(1, 4))
	if river == null or river.get_node_or_null("AguaComOndas") == null:
		_fail("agua ausente ou rio virou rua")
		return
	world.ensure_chunk_at(Vector3(640, 0, 560))
	await process_frame
	var tunnel = world.loaded_chunks.get(Vector2i(8, 7))
	if tunnel == null:
		_fail("corredor do tunel nao foi instanciado")
		return
	world.set_time(22.0)
	if world.day_light.light_energy >= 0.5:
		_fail("noite nao escureceu a luz")
		return
	world.set_time(12.0)
	if world.day_light.light_energy <= 0.9:
		_fail("dia nao reativou a luz")
		return
	world.set_weather(2)
	if world.weather_type != 2 or not world.rain_fx.emitting:
		_fail("chuva nao ativou")
		return
	var map_node = MapScript.new()
	map_node.size = Vector2(650, 480)
	root.add_child(map_node)
	await process_frame
	if map_node._point(0, Geo.RIVER_END_Z).y <= map_node._point(0, Geo.RIVER_START_Z).y:
		_fail("rio invertido no mapa")
		return
	print("V21 WORLD OK: 3 cidades, rio, ponte, tunel, clima, mini mapa")
	quit(0)

func _fail(reason: String) -> void:
	printerr("V21 WORLD ERROR: " + reason)
	quit(1)
