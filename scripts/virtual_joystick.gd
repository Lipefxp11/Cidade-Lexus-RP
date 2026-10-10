extends Control
signal moved(direction: Vector2)

var direction := Vector2.ZERO
var touch_id: int = -1
var dragging_mouse := false
var center := Vector2(91, 91)
var max_radius := 56.0

func _ready() -> void:
	custom_minimum_size = Vector2(182, 182)
	size = Vector2(182, 182)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _draw() -> void:
	draw_circle(center, 82.0, Color(0.015, 0.025, 0.04, 0.45))
	draw_arc(center, 82.0, 0, TAU, 64, Color(1.0, 1.0, 1.0, 0.25), 3.0)
	draw_circle(center + direction * max_radius, 31.0, Color(0.65, 0.08, 0.12, 0.72))
	draw_arc(center + direction * max_radius, 31.0, 0, TAU, 40, Color(1.0, 1.0, 1.0, 0.65), 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed and touch_id == -1:
			touch_id = ev.index
			_update_dir(ev.position)
			accept_event()
		elif not ev.pressed and ev.index == touch_id:
			touch_id = -1
			_reset()
			accept_event()
	elif event is InputEventScreenDrag:
		var ev := event as InputEventScreenDrag
		if ev.index == touch_id:
			_update_dir(ev.position)
			accept_event()
	elif event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT:
			dragging_mouse = ev.pressed
			if dragging_mouse:
				_update_dir(ev.position)
			else:
				_reset()
			accept_event()
	elif event is InputEventMouseMotion and dragging_mouse:
		var ev := event as InputEventMouseMotion
		_update_dir(ev.position)
		accept_event()

func _update_dir(local: Vector2) -> void:
	direction = ((local - center) / max_radius).limit_length(1.0)
	moved.emit(direction)
	queue_redraw()

func _reset() -> void:
	direction = Vector2.ZERO
	moved.emit(direction)
	queue_redraw()
