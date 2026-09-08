extends Node2D

const color := Color(1.0, 0.95, 0.0, 1.0)
const head_length := 14.0
const head_half_width := 5.0

var from_point := Vector2.ZERO
var to_point := Vector2.ZERO

func _process(_delta):
	if visible:
		queue_redraw()

func _draw():
	var offset := to_point - from_point
	var length := offset.length()
	if length < head_length:
		return
	var direction := offset / length
	var shaft_end := to_point - direction * head_length
	draw_line(from_point, shaft_end, color, 2.0)
	var side := direction.orthogonal() * head_half_width
	draw_colored_polygon(PackedVector2Array([to_point, shaft_end + side, shaft_end - side]), color)
