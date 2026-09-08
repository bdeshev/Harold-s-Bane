extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK }


@export var speed = 20
@export var turn_speed = .5
@export var attack_interval := 1.0
@export var front_damage := 5
@export var side_damage := 10
@export var rear_damage := 20
@export var aggro_range := 400.0
@export var aggro_check_interval := 0.25

@onready var range_area: Area2D = $Area2D

@export var max_health := 100
@export var health_bar_width := 50.0
@export var health_bar_height := 6.0

var state := State.IDLE
var auto_engage := false
var has_move_order := false
var target = position
var facing_angle := 0.0
var health: int
var health_bar: Node2D
var health_fill: ColorRect
var attack_timer := 0.0
var aggro_check_timer := 0.0


func _ready():
	_setup()
	health = max_health
	_create_health_bar()


func _setup():
	pass


func _health_bar_color() -> Color:
	return Color.WHITE


func _enemy_group() -> String:
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
	health = maxi(health - amount, 0)
	_update_health_bar()
	if health == 0:
		_dying()


func _dying() -> void:
	if health_bar != null:
		health_bar.queue_free()
	queue_free()


func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	_update_health_bar()


func _update_health_bar() -> void:
	health_bar.visible = health < max_health
	var ratio := float(health) / float(max_health)
	health_fill.size.x = health_bar_width * ratio


func _process(_delta):
	health_bar.global_position = global_position + Vector2(-health_bar_width / 2.0, -35.0)


func _physics_process(delta):
	if health == 0:
		return

	attack_timer += delta
	aggro_check_timer += delta
	if aggro_check_timer >= aggro_check_interval:
		aggro_check_timer = 0.0
		_update_state()

	if has_move_order or state == State.CHASE:
		_move_toward_target(delta)
	else:
		velocity = Vector2.ZERO

	_try_attack()


func _update_state() -> void:
	if _enemy_in_range():
		state = State.ATTACK
	elif auto_engage:
		var enemy := _nearest_enemy(aggro_range)
		if enemy != null:
			target = enemy.global_position
			has_move_order = false
			state = State.CHASE
			return
		state = State.IDLE
	elif state == State.CHASE:
		state = State.IDLE


func _enemy_in_range() -> bool:
	for body in range_area.get_overlapping_bodies():
		if body.is_in_group(_enemy_group()) and body.health > 0:
			return true
	return false


func _nearest_enemy(max_dist: float) -> Node2D:
	var best: Node2D = null
	var best_dist := max_dist
	for u in get_tree().get_nodes_in_group(_enemy_group()):
		if u.health <= 0:
			continue
		var d: float = global_position.distance_to(u.global_position)
		if d < best_dist:
			best_dist = d
			best = u
	return best


func _move_toward_target(delta) -> void:
	var to_target := position.distance_to(target)
	if to_target > 10:
		var desired_angle := (target - position).angle() + PI / 2.0
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
		if state == State.CHASE:
			state = State.IDLE


func _try_attack() -> void:
	if attack_timer < attack_interval:
		return
	for body in range_area.get_overlapping_bodies():
		if body.is_in_group(_enemy_group()) and body.health > 0:
			var defender_damage := get_damage_vs(body)
			var counter_damage: int = body.get_damage_vs(self)
			body.take_damage(defender_damage)
			take_damage(counter_damage)
			attack_timer = 0.0
			break


func order_move(dest: Vector2) -> void:
	target = dest
	has_move_order = true


func is_equal_angle(a: float, b: float) -> bool:
	return absf(angle_difference(a, b)) < 0.01


func get_damage_vs(defender: Node2D) -> int:
	var dir_to_attacker: Vector2 = (global_position - defender.global_position).normalized()
	var defender_forward: Vector2 = Vector2.UP.rotated(defender.facing_angle)
	var dot := defender_forward.dot(dir_to_attacker)
	if dot > 0.5:
		return front_damage
	elif dot < -0.5:
		return rear_damage
	return side_damage
