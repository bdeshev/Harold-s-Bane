extends Node2D

const color := Color(1.0, 0.95, 0.0, 1.0)
const waypoint_color := Color(1.0, 0.95, 0.0, 0.45)
const head_length := 14.0
const head_half_width := 5.0

var from_point := Vector2.ZERO
var path: Array[Vector2] = []

func _process(_delta):
	if visible:
		queue_redraw()

func _draw():
	if path.is_empty():
		return
	var points: Array[Vector2] = [from_point]
	points.append_array(path)
	for i in points.size() - 1:
		_draw_segment(points[i], points[i + 1], i == points.size() - 2)
	for i in points.size() - 2:
		draw_circle(points[i + 1], 4.0, waypoint_color)

func _draw_segment(start: Vector2, end: Vector2, with_head: bool) -> void:
	var offset := end - start
	var length := offset.length()
	if length < 2.0:
		return
	var direction := offset / length
	var shaft_end := end
	if with_head and length > head_length:
		shaft_end = end - direction * head_length
		var side := direction.orthogonal() * head_half_width
		draw_colored_polygon(PackedVector2Array([end, shaft_end + side, shaft_end - side]), color)
	draw_line(start, shaft_end, color, 2.0)
