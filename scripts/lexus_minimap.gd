extends Control

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
	draw_rect(rect, Color(0.03, 0.065, 0.10, 0.91), true)
	draw_rect(rect.grow(-5.0), Color(0.18, 0.34, 0.22, 0.9), true)
	for axis in [-120.0, -60.0, 0.0, 60.0, 120.0]:
		var x: float = _map_x(axis)
		var y: float = _map_y(axis)
		draw_line(Vector2(x, 5), Vector2(x, size.y - 5), Color(0.60, 0.64, 0.66, 0.92), 5.0)
		draw_line(Vector2(5, y), Vector2(size.x - 5, y), Color(0.60, 0.64, 0.66, 0.92), 5.0)
	for car in car_positions:
		var pos: Vector3 = car
		draw_circle(_map(pos), 4.0, Color(0.23, 0.63, 1.0, 0.98))
	for npc in npc_positions:
		var pos: Vector3 = npc
		draw_circle(_map(pos), 3.0, Color(1.0, 0.34, 0.24, 0.9))
	var p := _map(player_pos)
	var alpha := -heading
	var front := p + Vector2(0, -11).rotated(alpha)
	var left := p + Vector2(-6, 7).rotated(alpha)
	var right := p + Vector2(6, 7).rotated(alpha)
	draw_colored_polygon(PackedVector2Array([front, left, right]), Color(1.0, 0.95, 0.88))
	draw_rect(rect.grow(-1.0), Color(0.89, 0.19, 0.24, 0.85), false, 2.0)

func _map_x(x: float) -> float:
	return 7.0 + (x + 190.0) / 380.0 * maxf(10.0, size.x - 14.0)

func _map_y(z: float) -> float:
	return 7.0 + (z + 190.0) / 380.0 * maxf(10.0, size.y - 14.0)

func _map(p: Vector3) -> Vector2:
	return Vector2(_map_x(p.x), _map_y(p.z))

func refresh(player_location: Vector3, face_angle: float, cars: Array, npcs: Array, driving: bool) -> void:
	player_pos = player_location
	heading = face_angle
	car_positions = cars
	npc_positions = npcs
	is_driving = driving
	queue_redraw()
