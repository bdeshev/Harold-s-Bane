extends "res://nodes/infantry.gd"


func _setup():
	super()
	speed = 60
	base_damage = 15
	side_modifier = 60.0
	rear_modifier = 160.0
	max_health = 60


func _ready():
	super()
	health = max_health
