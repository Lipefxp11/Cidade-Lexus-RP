extends Control

# Player-centered local minimap: doesn't break when procedural coordinates grow.
const MAP_RADIUS = 110.0
const CELL_SIZE = 80.0
var player_pos := Vector3.ZERO
var car_positions: Array = []
var npc_positions: Array = []
var heading: float = 0.0
var is_driving := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(166, 166)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.03, 0.06, 0.09, 0.96), true)
	draw_rect(rect.grow(-5), Color(0.17, 0.31, 0.22, 0.92), true)
	# Local city street grid, translated around the current player position.
	var min_x := floori((player_pos.x - MAP_RADIUS) / CELL_SIZE)
	var max_x := ceili((player_pos.x + MAP_RADIUS) / CELL_SIZE)
	var min_z := floori((player_pos.z - MAP_RADIUS) / CELL_SIZE)
	var max_z := ceili((player_pos.z + MAP_RADIUS) / CELL_SIZE)
	for index in range(min_x, max_x + 1):
		var screen_x := _local_x(index * CELL_SIZE)
		draw_line(Vector2(screen_x, 4), Vector2(screen_x, size.y - 4), Color(0.64, 0.66, 0.69, 0.92), 6.0)
	for index in range(min_z, max_z + 1):
		var screen_y := _local_z(index * CELL_SIZE)
		draw_line(Vector2(4, screen_y), Vector2(size.x - 4, screen_y), Color(0.64, 0.66, 0.69, 0.92), 6.0)
	for item in car_positions:
		var car: Vector3 = item
		_draw_poi(car, Color(0.25, 0.66, 1.0))
	for item in npc_positions:
		var npc: Vector3 = item
		_draw_poi(npc, Color(1.0, 0.35, 0.30))
	var point := size * 0.5
	var triangle := PackedVector2Array([
		point + Vector2(0, -9).rotated(-heading),
		point + Vector2(-6, 7).rotated(-heading),
		point + Vector2(6, 7).rotated(-heading)
	])
	draw_colored_polygon(triangle, Color(1.0, 0.95, 0.87))
	draw_rect(rect.grow(-1), Color(0.85, 0.15, 0.22, 0.9), false, 2.0)

func _local_x(x: float) -> float:
	return size.x * 0.5 + (x - player_pos.x) / MAP_RADIUS * size.x * 0.48

func _local_z(z: float) -> float:
	return size.y * 0.5 + (z - player_pos.z) / MAP_RADIUS * size.y * 0.48

func _draw_poi(pos: Vector3, color: Color) -> void:
	var point := Vector2(_local_x(pos.x), _local_z(pos.z))
	if point.x > 5 and point.x < size.x - 5 and point.y > 5 and point.y < size.y - 5:
		draw_circle(point, 3.8, color)

func refresh(player_location: Vector3, face_angle: float, cars: Array, npcs: Array, driving: bool) -> void:
	player_pos = player_location
	heading = face_angle
	car_positions = cars
	npc_positions = npcs
	is_driving = driving
	queue_redraw()
