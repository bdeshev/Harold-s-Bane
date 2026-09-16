extends "res://nodes/unit_base.gd"


func _setup():
	add_to_group("blue")


func _health_bar_color() -> Color:
	return Color(0.2, 0.85, 0.2)


func _opposing_group() -> String:
	return "red"
