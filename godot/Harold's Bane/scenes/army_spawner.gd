extends MultiplayerSpawner

const BLUE_SPAWNS := [
	[Vector2(692, 1037), preload("res://scenes/units/Blue_infantry.tscn")],
	[Vector2(1131, 1151), preload("res://scenes/units/Blue_infantry.tscn")],
	[Vector2(903, 1131), preload("res://scenes/units/Blue_infantry.tscn")],
	[Vector2(1014, 1144), preload("res://scenes/units/Blue_infantry.tscn")],
	[Vector2(1258, 1146), preload("res://scenes/units/Blue_infantry.tscn")],
	[Vector2(1454, 1081), preload("res://scenes/units/Blue_infantry.tscn")],
	[Vector2(1922, 973), preload("res://scenes/units/Blue_cavalry.tscn")],
	[Vector2(1812, 969), preload("res://scenes/units/Blue_cavalry.tscn")],
	[Vector2(566, 1001), preload("res://scenes/units/Blue_infantry.tscn")],
	[Vector2(1576, 1029), preload("res://scenes/units/Blue_infantry.tscn")],
	[Vector2(460, 929), preload("res://scenes/units/Blue_infantry.tscn")],
	[Vector2(1690, 967), preload("res://scenes/units/Blue_infantry.tscn")],
]

const RED_SPAWNS := [
	[Vector2(1021, 299), preload("res://scenes/units/Red_cavalry.tscn")],
	[Vector2(884, 342), preload("res://scenes/units/Red_infantry.tscn")],
	[Vector2(779, 406), preload("res://scenes/units/Red_infantry.tscn")],
	[Vector2(669, 469), preload("res://scenes/units/Red_infantry.tscn")],
	[Vector2(46, 448), preload("res://scenes/units/Red_infantry.tscn")],
	[Vector2(-64, 378), preload("res://scenes/units/Red_infantry.tscn")],
	[Vector2(-173, 323), preload("res://scenes/units/Red_infantry.tscn")],
	[Vector2(1140, 286), preload("res://scenes/units/Red_cavalry.tscn")],
	[Vector2(167, 492), preload("res://scenes/units/Red_infantry.tscn")],
	[Vector2(284, 492), preload("res://scenes/units/Red_infantry.tscn")],
	[Vector2(402, 500), preload("res://scenes/units/Red_infantry.tscn")],
	[Vector2(526, 505), preload("res://scenes/units/Red_infantry.tscn")],
]

@export_enum("Blue", "Red") var army: int = 0

var _spawned := false


func _ready() -> void:
	spawn_function = _spawn_unit
	HighLevelNetworkHandler.game_started.connect(_on_game_started)
	if HighLevelNetworkHandler.is_hosting and army == 0:
		_request_army("blue", 1)
	elif multiplayer.is_server() and not multiplayer.get_peers().is_empty():
		for id in multiplayer.get_peers():
			_request_army("red", id)
			break


func _on_game_started() -> void:
	if not multiplayer.is_server():
		return
	if army == 0:
		_request_army("blue", 1)
	else:
		for id in multiplayer.get_peers():
			_request_army("red", id)
			break


func _request_army(army_id: String, peer: int) -> void:
	if not multiplayer.is_server() or _spawned:
		return
	_spawned = true
	var spawns: Array = BLUE_SPAWNS if army_id == "blue" else RED_SPAWNS
	for i in spawns.size():
		spawn({"army": army_id, "i": i, "peer": peer})


func _spawn_unit(data: Variant) -> Node:
	var spawns: Array = BLUE_SPAWNS if data["army"] == "blue" else RED_SPAWNS
	var i: int = data["i"]
	var unit: Node = spawns[i][1].instantiate()
	unit.position = spawns[i][0]
	unit.name = "%s_%d" % [data["army"], i]
	unit.set_multiplayer_authority(data["peer"])
	return unit
