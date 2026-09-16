extends Node2D

const min_drag := 6.0
const fill_color := Color(0.2, 0.85, 0.2, 0.12)
const edge_color := Color(0.2, 0.85, 0.2, 0.9)

var dragging := false
var drag_start := Vector2.ZERO
var shift_held := false


func _process(_delta):
	if dragging:
		queue_redraw()


func _unhandled_input(event):
	if event.is_action_pressed("click"):
		dragging = true
		drag_start = get_global_mouse_position()
		shift_held = event.shift_pressed
		queue_redraw()
	elif event.is_action_released("click") and dragging:
		dragging = false
		queue_redraw()
		_select_units_in_rect()


func _select_units_in_rect() -> void:
	var rect := _current_rect()
	var is_drag := rect.size.length() >= min_drag
	if not is_drag and shift_held:
		return
	for unit in get_tree().get_nodes_in_group("controllable"):
		if unit.health <= 0:
			continue
		if is_drag and rect.has_point(unit.global_position):
			unit.set_selected(true)
		elif not shift_held:
			unit.set_selected(false)


func _current_rect() -> Rect2:
	return Rect2(drag_start, get_global_mouse_position() - drag_start).abs()


func _draw():
	if not dragging:
		return
	var rect := _current_rect()
	if rect.size.length() < min_drag:
		return
	draw_rect(rect, fill_color, true)
	draw_rect(rect, edge_color, false, 2.0)
