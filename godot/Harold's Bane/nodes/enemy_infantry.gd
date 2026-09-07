extends CharacterBody2D

@export var speed = 20
@export var turn_speed = .5
@export var front_damage := 5
@export var side_damage := 10
@export var rear_damage := 20

@export var max_health := 100
@export var health_bar_width := 50.0
@export var health_bar_height := 6.0

var target = position
var facing_angle := PI
var health: int
var health_bar: Node2D
var health_fill: ColorRect

func _ready():
	add_to_group("enemies")
	health = max_health
	_create_health_bar()

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
	health_fill.color = Color(0.85, 0.2, 0.2)
	health_fill.size = Vector2(health_bar_width, health_bar_height)
	health_bar.add_child(health_fill)

func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	_update_health_bar()
	if health == 0:
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
