extends Control

signal map_clicked
signal waypoint_selected(world_position: Vector3)

const Geo = preload("res://scripts/lexus_geography.gd")
const CELL_SIZE = Geo.CELL_SIZE

# Map drawn from the SAME positions and road rules used by the procedural world.
# Stylized, top-down map. Not a GTA V map texture or a real-world street map.
var map_radius: float = 145.0
var player_pos := Vector3.ZERO
var car_positions: Array = []
var npc_positions: Array = []
var landmarks: Array = []
var heading := 0.0
var is_driving := false
var allow_waypoint := false
var waypoint_active := false
var waypoint_world := Vector3.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	custom_minimum_size = Vector2(166, 166)
	queue_redraw()

func _scale_px() -> float:
	return minf(size.x, size.y) * 0.48 / maxf(55.0, map_radius)

func _point(wx: float, wz: float) -> Vector2:
	return size * 0.5 + Vector2(wx - player_pos.x, wz - player_pos.z) * _scale_px()

func _visible_world() -> Rect2:
	var meter_per_px := 1.0 / maxf(0.001, _scale_px())
	return Rect2(Vector2(player_pos.x, player_pos.z) - size * 0.5 * meter_per_px, size * meter_per_px)

func _draw() -> void:
	var vp := Rect2(Vector2.ZERO, size)
	draw_rect(vp, Color(0.032, 0.075, 0.070, 0.99), true)
	var world_area := _visible_world()
	_draw_city_zones(world_area, vp)
	_draw_river(world_area, vp)
	_draw_relief(world_area)
	_draw_roads(world_area)
	_draw_route_structures()
	_draw_city_names()
	for item in landmarks:
		var poi: Dictionary = item
		if str(poi.get("type", "")) in ["city", "bridge", "tunnel"]:
			continue # These are already labeled as geographic markers.
		var pos: Vector3 = poi.get("position", Vector3.ZERO)
		var type_id := str(poi.get("type", ""))
		var dot := Color(0.35, 0.73, 0.95)
		if type_id == "org":
			dot = Color(1.0, 0.25, 0.25)
		elif type_id == "hospital":
			dot = Color(0.35, 0.94, 0.51)
		elif type_id in ["skins", "dealer", "tuning", "workshop"]:
			dot = Color(1.0, 0.79, 0.36)
		_draw_poi(pos, dot)
	for item in car_positions:
		_draw_poi(item as Vector3, Color(0.24, 0.69, 0.98))
	for item in npc_positions:
		_draw_poi(item as Vector3, Color(0.96, 0.37, 0.23))
	_draw_waypoint()
	var p := size * 0.5
	var triangle := PackedVector2Array([
		p + Vector2(0, -10).rotated(-heading),
		p + Vector2(-6, 7).rotated(-heading),
		p + Vector2(6, 7).rotated(-heading)
	])
	draw_colored_polygon(triangle, Color(0.98, 0.97, 0.96))
	draw_arc(p, 12.0, 0.0, TAU, 28, Color(0.06, 0.09, 0.11), 1.6)
	draw_rect(vp.grow(-1.0), Color(0.85, 0.16, 0.21, 0.95), false, 2.0)
	_draw_compass()

func _draw_city_zones(_world_area: Rect2, _viewport: Rect2) -> void:
	var north_edge := clampf(_point(0, Geo.RIVER_END_Z).y, 0.0, size.y)
	if north_edge < size.y:
		draw_rect(Rect2(Vector2(0, north_edge), Vector2(size.x, size.y - north_edge)), Color(0.23, 0.28, 0.20, 0.30), true)
	var north_x := clampf(_point(Geo.TUNNEL_END_X, 0).x, 0.0, size.x)
	if north_x < size.x and north_edge < size.y:
		draw_rect(Rect2(Vector2(north_x, north_edge), Vector2(size.x - north_x, size.y - north_edge)), Color(0.30, 0.31, 0.20, 0.23), true)

func _draw_river(_world_area: Rect2, viewport: Rect2) -> void:
	var y0 := _point(0, Geo.RIVER_START_Z).y
	var y1 := _point(0, Geo.RIVER_END_Z).y
	var river_rect := Rect2(Vector2(0, y0), Vector2(size.x, y1 - y0)).intersection(viewport)
	if river_rect.has_area():
		draw_rect(river_rect, Color(0.035, 0.25, 0.39, 1.0), true)
		for n in range(8):
			var y := y0 + (float(n) + 0.5) * (y1 - y0) / 8.0
			if y >= 0.0 and y < size.y:
				draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.17, 0.40, 0.51, 0.26), 1.0)
	for z in [Geo.RIVER_START_Z, Geo.RIVER_END_Z]:
		var py := _point(0, z).y
		if py >= 0.0 and py < size.y:
			draw_line(Vector2(0, py), Vector2(size.x, py), Color(0.64, 0.69, 0.54), 2.0)

func _draw_relief(world_area: Rect2) -> void:
	# Contours hint at hills in favela districts; streets are drawn on top.
	var anchors := [Vector2(-80, -35), Vector2(80, -115), Vector2(-155, 550), Vector2(135, 680), Vector2(900, 690)]
	for center in anchors:
		if not world_area.grow(180).has_point(center):
			continue
		var pixel := _point(center.x, center.y)
		for level in range(3):
			draw_arc(pixel, (28.0 + float(level) * 14.0) * _scale_px(), 0.0, TAU, 32, Color(0.53, 0.59, 0.37, 0.42), 1.1)

func _draw_roads(world_area: Rect2) -> void:
	var start_x := floori(world_area.position.x / CELL_SIZE) - 1
	var end_x := ceili(world_area.end.x / CELL_SIZE) + 1
	var start_z := floori(world_area.position.y / CELL_SIZE) - 1
	var end_z := ceili(world_area.end.y / CELL_SIZE) + 1
	# Lines are clipped by our visible-world bounds; water has only the bridge at X=0.
	var width := clampf(13.5 * _scale_px(), 2.4, 12.5)
	for xi in range(start_x, end_x + 1):
		var x := float(xi) * CELL_SIZE
		if xi == 0:
			_draw_road_line(x, world_area.position.y, x, world_area.end.y, width)
		else:
			_draw_road_line(x, world_area.position.y, x, minf(world_area.end.y, Geo.RIVER_START_Z), width)
			_draw_road_line(x, maxf(world_area.position.y, Geo.RIVER_END_Z), x, world_area.end.y, width)
	for zi in range(start_z, end_z + 1):
		var z := float(zi) * CELL_SIZE
		if z > Geo.RIVER_START_Z and z < Geo.RIVER_END_Z:
			continue
		_draw_road_line(world_area.position.x, z, world_area.end.x, z, width)

func _draw_road_line(x1: float, z1: float, x2: float, z2: float, width: float) -> void:
	if z2 < z1 or x2 < x1:
		return
	var a := _point(x1, z1)
	var b := _point(x2, z2)
	draw_line(a, b, Color(0.33, 0.38, 0.39, 1.0), width + 1.1)
	draw_line(a, b, Color(0.51, 0.54, 0.54, 0.94), maxf(1.6, width * 0.72))

func _draw_route_structures() -> void:
	var bridge_a := _point(0, Geo.RIVER_START_Z)
	var bridge_b := _point(0, Geo.RIVER_END_Z)
	draw_line(bridge_a, bridge_b, Color(0.93, 0.85, 0.59), clampf(17.0 * _scale_px(), 4.0, 18.0))
	draw_line(bridge_a, bridge_b, Color(0.39, 0.45, 0.49), clampf(13.0 * _scale_px(), 3.0, 13.5))
	var tunnel_a := _point(Geo.TUNNEL_BEGIN_X, Geo.TUNNEL_CENTER_Z)
	var tunnel_b := _point(Geo.TUNNEL_END_X, Geo.TUNNEL_CENTER_Z)
	draw_line(tunnel_a, tunnel_b, Color(0.14, 0.15, 0.18), clampf(21.0 * _scale_px(), 4.5, 20.0))
	draw_line(tunnel_a, tunnel_b, Color(0.72, 0.58, 0.29), maxf(1.2, 2.0 * _scale_px()))

func _draw_city_names() -> void:
	if size.x < 350.0:
		return
	_label_on_map("DUQUE DE CAXIAS", Geo.DUQUE_CENTER, Color(0.99, 0.95, 0.82), 19)
	_label_on_map("CIDADE DE DEUS", Geo.CDD_CENTER, Color(0.99, 0.95, 0.82), 19)
	_label_on_map("ZONA NORTE", Geo.NORTH_CENTER, Color(0.99, 0.95, 0.82), 19)
	_label_on_map("PONTE", Vector3(30, 0, 360), Color(0.95, 0.83, 0.62), 14)
	_label_on_map("TÚNEL", Vector3(640, 0, 535), Color(0.98, 0.79, 0.47), 14)

func _label_on_map(text_value: String, world_position: Vector3, color: Color, px: int) -> void:
	var pos := _point(world_position.x, world_position.z)
	if pos.x < 3 or pos.y < 16 or pos.x > size.x - 120 or pos.y > size.y - 5:
		return
	var font := get_theme_default_font()
	draw_string(font, pos + Vector2(1, 1), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(0.01, 0.04, 0.07, 0.97))
	draw_string(font, pos, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)

func _draw_poi(pos: Vector3, color: Color) -> void:
	var point := _point(pos.x, pos.z)
	if point.x >= 6 and point.x <= size.x - 6 and point.y >= 6 and point.y <= size.y - 6:
		draw_circle(point, 3.8, color)

func _draw_waypoint() -> void:
	if not waypoint_active:
		return
	var marker := _point(waypoint_world.x, waypoint_world.z)
	if marker.x > 7 and marker.x < size.x - 7 and marker.y > 7 and marker.y < size.y - 7:
		draw_arc(marker, 8.5, 0.0, TAU, 22, Color(1.0, 0.78, 0.22), 2.5)
		draw_circle(marker, 3.0, Color(1.0, 0.78, 0.22))

func _draw_compass() -> void:
	var font := get_theme_default_font()
	draw_string(font, Vector2(10, 22), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.91, 0.93, 0.94))

func refresh(player_location: Vector3, face_angle: float, cars: Array, npcs: Array, driving: bool) -> void:
	player_pos = player_location
	heading = face_angle
	car_positions = cars
	npc_positions = npcs
	is_driving = driving
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			if allow_waypoint:
				var world_xy := (click.position - size * 0.5) / _scale_px()
				var chosen := Vector3(player_pos.x + world_xy.x, 0.0, player_pos.z + world_xy.y)
				if Geo.is_river_position(chosen):
					chosen.x = Geo.BRIDGE_CENTER_X
				waypoint_selected.emit(chosen)
			else:
				map_clicked.emit()
			accept_event()

func set_landmarks(points: Array) -> void:
	landmarks = points
	queue_redraw()

func set_waypoint(active: bool, location_world: Vector3 = Vector3.ZERO) -> void:
	waypoint_active = active
	waypoint_world = location_world
	queue_redraw()
