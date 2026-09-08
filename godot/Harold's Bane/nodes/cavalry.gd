extends "res://nodes/infantry.gd"


func _setup():
	super()
	speed = 60
	front_damage = 15
	side_damage = 25
	rear_damage = 40
	max_health = 60


func _ready():
	super()
	health = max_health
