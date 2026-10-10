extends RefCounted

# Fonte compartilhada: regras do mapa 3D, minimapa e GPS.
# Mapa ORIGINAL e simplificado inspirado em cidades da região metropolitana do RJ.
const CELL_SIZE = 80.0
const RIVER_START_Z = 280.0
const RIVER_END_Z = 440.0
const BRIDGE_CENTER_X = 0.0
const BRIDGE_WIDTH = 15.6
const TUNNEL_BEGIN_X = 520.0
const TUNNEL_END_X = 760.0
const TUNNEL_CENTER_Z = 560.0

const DUQUE_CENTER = Vector3(0.0, 0.0, 0.0)
const CDD_CENTER = Vector3(0.0, 0.0, 560.0)
const NORTH_CENTER = Vector3(850.0, 0.0, 560.0)

static func is_river_cell(cell: Vector2i) -> bool:
	return cell.y == 4 or cell.y == 5

static func is_bridge_cell(cell: Vector2i) -> bool:
	return cell.x == 0 and is_river_cell(cell)

static func is_bridge_approach(cell: Vector2i) -> bool:
	return cell.x == 0 and (cell.y == 3 or cell.y == 6)

static func is_tunnel_cell(cell: Vector2i) -> bool:
	return cell.y == 7 and cell.x >= 7 and cell.x <= 9

static func is_river_position(world_pos: Vector3) -> bool:
	return world_pos.z >= RIVER_START_Z and world_pos.z < RIVER_END_Z

static func is_bridge_position(world_pos: Vector3) -> bool:
	return is_river_position(world_pos) and absf(world_pos.x) <= BRIDGE_WIDTH * 0.5

static func city_name(world_pos: Vector3) -> String:
	if world_pos.z >= RIVER_END_Z:
		if world_pos.x >= TUNNEL_END_X:
			return "ZONA NORTE"
		return "CIDADE DE DEUS"
	return "DUQUE DE CAXIAS"

static func district_label(world_pos: Vector3) -> String:
	if is_bridge_position(world_pos):
		return "PONTE LEXUS • RIO"
	if is_river_position(world_pos):
		return "CANAL LEXUS • ÁGUA"
	if is_tunnel_cell(Vector2i(roundi(world_pos.x / CELL_SIZE), roundi(world_pos.z / CELL_SIZE))):
		return "TÚNEL DA ZONA NORTE"
	return city_name(world_pos)

static func rolling_height(cell: Vector2i, local: Vector2) -> float:
	# O relevo não invade as avenidas (corredores com |x| ou |z| <= 11).
	if is_river_cell(cell) or is_tunnel_cell(cell):
		return 0.0
	var edge_x := clampf((absf(local.x) - 10.7) / 29.3, 0.0, 1.0)
	var edge_z := clampf((absf(local.y) - 10.7) / 29.3, 0.0, 1.0)
	var wx := float(cell.x) * CELL_SIZE + local.x
	var wz := float(cell.y) * CELL_SIZE + local.y
	var wave := 0.68 + 0.16 * sin(wx * 0.029) + 0.16 * cos(wz * 0.035)
	var amp := 3.0 if cell.y >= 6 else 1.8
	return maxf(0.0, edge_x * edge_z * amp * wave)

static func landmark_points() -> Array:
	return [
		{"title":"Duque de Caxias", "type":"city", "position":DUQUE_CENTER},
		{"title":"Cidade de Deus", "type":"city", "position":CDD_CENTER},
		{"title":"Zona Norte", "type":"city", "position":NORTH_CENTER},
		{"title":"Ponte Lexus", "type":"bridge", "position":Vector3(0, 0, 360)},
		{"title":"Túnel da Zona Norte", "type":"tunnel", "position":Vector3(640, 0, 560)}
	]
