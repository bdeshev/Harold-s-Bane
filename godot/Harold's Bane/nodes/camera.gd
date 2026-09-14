extends Camera2D

const DEFAULT_MAP_PATH := NodePath("../map")

@export var zoom_step := 1.15
@export var max_zoom := 4.0
@export var map_path: NodePath = DEFAULT_MAP_PATH

@onready var _map: Sprite2D = get_node_or_null(map_path) as Sprite2D

var _map_rect := Rect2()
var _min_zoom := 0.1


func _ready() -> void:
	make_current()
	_update_limits()
	get_viewport().size_changed.connect(_update_limits)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_at(get_global_mouse_position(), zoom_step)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_at(get_global_mouse_position(), 1.0 / zoom_step)
			MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		position = _clamp_position(position - event.relative / zoom.x)


func _zoom_at(world_point: Vector2, factor: float) -> void:
	var new_zoom := clampf(zoom.x * factor, _min_zoom, max_zoom)
	var effective := new_zoom / zoom.x
	if is_equal_approx(effective, 1.0):
		return
	zoom = Vector2(new_zoom, new_zoom)
	position = _clamp_position(position + (world_point - position) * (1.0 - 1.0 / effective))


func _update_limits() -> void:
	if not _has_map():
		return
	var size: Vector2 = _map.texture.get_size() * _map.global_scale
	_map_rect = Rect2(_map.global_position - size / 2.0, size)
	_min_zoom = maxf(
		get_viewport_rect().size.x / _map_rect.size.x,
		get_viewport_rect().size.y / _map_rect.size.y)
	zoom = Vector2(clampf(zoom.x, _min_zoom, max_zoom), zoom.x)
	position = _clamp_position(position)


func _clamp_position(p: Vector2) -> Vector2:
	if not _has_map():
		return p
	var half_view := get_viewport_rect().size / (2.0 * zoom.x)
	var clamped := p
	for axis in 2:
		var min_pos := _map_rect.position[axis] + half_view[axis]
		var max_pos := _map_rect.end[axis] - half_view[axis]
		if min_pos > max_pos:
			clamped[axis] = _map_rect.get_center()[axis]
		else:
			clamped[axis] = clampf(p[axis], min_pos, max_pos)
	return clamped


func _has_map() -> bool:
	return _map != null and _map.texture != null
