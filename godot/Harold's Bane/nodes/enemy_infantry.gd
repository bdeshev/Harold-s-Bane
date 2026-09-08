extends "res://nodes/unit_base.gd"


func _setup():
	add_to_group("enemies")
	facing_angle = PI
	auto_engage = true


func _health_bar_color() -> Color:
	return Color(0.85, 0.2, 0.2)


func _enemy_group() -> String:
	return "friendlies"
