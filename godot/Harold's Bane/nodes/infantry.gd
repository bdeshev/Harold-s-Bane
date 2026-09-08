extends "res://nodes/unit_base.gd"

var is_selected = false
var move_arrow: Node2D


func _setup():
	input_pickable = true
	input_event.connect(_on_input_event)
	add_to_group("friendlies")


func _health_bar_color() -> Color:
	return Color(0.2, 0.85, 0.2)


func _enemy_group() -> String:
	return "enemies"


func _process(_delta):
	super(_delta)
	if move_arrow != null:
		move_arrow.from_point = global_position


func _unhandled_input(event):
	if event.is_action_pressed("click"):
		set_selected(false)
	if event.is_action_pressed("move") and is_selected:
		order_move(get_global_mouse_position())
		_show_move_arrow()


func _on_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("click"):
		set_selected(true)
		get_viewport().set_input_as_handled()


func set_selected(selected: bool) -> void:
	is_selected = selected
	if is_selected:
		$Sprite2D.play("selected")
	else:
		$Sprite2D.play("unselected")


func _show_move_arrow() -> void:
	if move_arrow == null:
		move_arrow = Node2D.new()
		move_arrow.set_script(load("res://nodes/move_arrow.gd"))
		move_arrow.top_level = true
		move_arrow.z_index = 50
		add_child(move_arrow)
	move_arrow.from_point = global_position
	move_arrow.to_point = target
	move_arrow.visible = true
