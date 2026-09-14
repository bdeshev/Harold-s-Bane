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
		if has_move_order:
			move_arrow.path.clear()
			move_arrow.path.append(target)
			move_arrow.path.append_array(move_queue)
			move_arrow.visible = true
		else:
			move_arrow.visible = false


func _unhandled_input(event):
	if event.is_action_pressed("move") and is_selected:
		_issue_formation_move(get_global_mouse_position(), event.shift_pressed)
		_show_move_arrow()


func _issue_formation_move(dest: Vector2, queued: bool) -> void:
	var selected := get_tree().get_nodes_in_group("friendlies").filter(
		func(u): return u.is_selected and u.health > 0
	)
	if selected.size() <= 1:
		if queued:
			queue_move(dest)
		else:
			order_move(dest)
		return
	var centroid := Vector2.ZERO
	for u in selected:
		centroid += u.global_position
	centroid /= selected.size()
	var my_dest := dest + (global_position - centroid)
	if queued:
		queue_move(my_dest)
	else:
		order_move(my_dest)


func _on_input_event(_viewport, event, _shape_idx):
	if event.is_action_released("click"):
		if event.shift_pressed:
			set_selected(not is_selected)
		else:
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
