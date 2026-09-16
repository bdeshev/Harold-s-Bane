extends CharacterBody2D


@export var speed = 20
@export var turn_speed = 1
@export var attack_interval := 1.0
@export var base_damage := 5
@export var side_modifier := 100.0
@export var rear_modifier := 300.0
@export var separation_radius := 45.0
@export var separation_strength := 25.0

@onready var range_area: Area2D = $Area2D

@export var max_health := 100
@export var health_bar_width := 50.0
@export var health_bar_height := 6.0

var has_move_order := false
var move_queue: Array[Vector2] = []
var target = position
var facing_angle := 0.0
var health: int
var health_bar: Node2D
var health_fill: ColorRect
var attack_timer := 0.0
var is_selected := false
var move_arrow: Node2D


func _enter_tree() -> void:
	_update_authority()


func _update_authority() -> void:
	var is_local := get_multiplayer_authority() == multiplayer.get_unique_id()
	if is_local:
		add_to_group("controllable")
		set_process_unhandled_input(true)
		input_pickable = true
	else:
		remove_from_group("controllable")
		set_process_unhandled_input(false)
		input_pickable = false


func _ready():
	add_to_group("units")
	_setup()
	input_event.connect(_on_input_event)
	health = max_health
	_create_health_bar()


func _setup():
	pass


func _health_bar_color() -> Color:
	return Color.WHITE


func _opposing_group() -> String:
	return ""


func _create_health_bar() -> void:
	health_bar = Node2D.new()
	health_bar.top_level = true
	health_bar.z_index = 100
	add_child(health_bar)

	var background := ColorRect.new()
	background.color = Color(0.1, 0.1, 0.1, 0.8)
	background.size = Vector2(health_bar_width, health_bar_height)
	health_bar.add_child(background)

	health_fill = ColorRect.new()
	health_fill.color = _health_bar_color()
	health_fill.size = Vector2(health_bar_width, health_bar_height)
	health_bar.add_child(health_fill)


func take_damage(amount: int) -> void:
	if not multiplayer.is_server():
		return
	health = maxi(health - amount, 0)
	_sync_health.rpc(health)
	if health == 0:
		_dying()


@rpc("any_peer", "call_local", "reliable")
func _sync_health(value: int) -> void:
	health = value
	_update_health_bar()


func _dying() -> void:
	health = 0
	_sync_death.rpc()
	queue_free()


@rpc("any_peer", "call_local", "reliable")
func _sync_death() -> void:
	health = 0
	_update_health_bar()


func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	_update_health_bar()


func _update_health_bar() -> void:
	health_bar.visible = health < max_health
	var ratio := float(health) / float(max_health)
	health_fill.size.x = health_bar_width * ratio


func _process(_delta):
	health_bar.global_position = global_position + Vector2(-health_bar_width / 2.0, -35.0)
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
	var selected := get_tree().get_nodes_in_group("controllable").filter(
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
	var sprite := $Sprite2D as AnimatedSprite2D
	if sprite.sprite_frames.has_animation("selected"):
		sprite.play("selected" if selected else "unselected")
	else:
		sprite.modulate = Color(1.0, 0.5, 0.5) if selected else Color.WHITE


func _show_move_arrow() -> void:
	if move_arrow == null:
		move_arrow = Node2D.new()
		move_arrow.set_script(load("res://nodes/move_arrow.gd"))
		move_arrow.top_level = true
		move_arrow.z_index = 50
		add_child(move_arrow)


func _physics_process(delta):
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		return

	if health == 0:
		return

	attack_timer += delta

	if has_move_order:
		_move_toward_target(delta)
	else:
		velocity = Vector2.ZERO

	_apply_separation(delta)
	_try_attack()


func _move_toward_target(delta) -> void:
	var to_target := global_position.distance_to(target)
	if to_target > 10.0:
		var desired_angle := (target - global_position).angle() + PI / 2.0
		facing_angle = rotate_toward(facing_angle, desired_angle, turn_speed * delta)
		rotation = facing_angle
		if is_equal_angle(facing_angle, desired_angle):
			velocity = Vector2.UP.rotated(facing_angle) * speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
		has_move_order = false
		_advance_move_queue()


func _advance_move_queue() -> void:
	if move_queue.is_empty():
		return
	target = move_queue.pop_front()
	has_move_order = true


func _apply_separation(delta) -> void:
	var push := Vector2.ZERO
	for u in get_tree().get_nodes_in_group("units"):
		if u == self or u.health <= 0 or u.is_in_group(_opposing_group()):
			continue
		var offset: Vector2 = global_position - u.global_position
		var dist := offset.length()
		if dist < separation_radius and dist > 0.01:
			push += offset / dist * (1.0 - dist / separation_radius)
	if push != Vector2.ZERO:
		global_position += push.normalized() * separation_strength * delta


func _try_attack() -> void:
	if attack_timer < attack_interval:
		return
	for body in range_area.get_overlapping_bodies():
		if body.is_in_group(_opposing_group()) and body.health > 0:
			var defender_damage := get_damage_vs(body)
			var counter_damage: int = body.get_damage_vs(self)
			if multiplayer.is_server():
				body.take_damage(defender_damage)
				take_damage(counter_damage)
			else:
				body.take_damage.rpc_id(1, defender_damage)
				take_damage.rpc_id(1, counter_damage)
			attack_timer = 0.0
			break


func order_move(dest: Vector2) -> void:
	_sync_move_order.rpc(dest)


@rpc("any_peer", "call_local", "reliable")
func _sync_move_order(dest: Vector2) -> void:
	target = dest
	move_queue.clear()
	has_move_order = true


func queue_move(dest: Vector2) -> void:
	_sync_queue_move.rpc(dest)


@rpc("any_peer", "call_local", "reliable")
func _sync_queue_move(dest: Vector2) -> void:
	if has_move_order:
		move_queue.append(dest)
	else:
		target = dest
		has_move_order = true


func is_equal_angle(a: float, b: float) -> bool:
	return absf(angle_difference(a, b)) < 0.01


func get_damage_vs(defender: Node2D) -> int:
	var dir_to_attacker: Vector2 = (global_position - defender.global_position).normalized()
	var defender_forward: Vector2 = Vector2.UP.rotated(defender.facing_angle)
	var dot := defender_forward.dot(dir_to_attacker)
	if dot > 0.5:
		return base_damage
	elif dot < -0.5:
		return damage_modifier(rear_modifier)
	return damage_modifier(side_modifier)


func damage_modifier(percent: float) -> int:
	return int(round(base_damage * (1.0 + percent / 100.0)))
