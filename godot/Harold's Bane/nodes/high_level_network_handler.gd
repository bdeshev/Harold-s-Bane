extends Node

const DEFAULT_ADDRESS := "127.0.0.1"
const PORT := 3500

var peer: ENetMultiplayerPeer
var is_hosting := false
var _game_started := false


static func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.contains(".") and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			return ip
	return "127.0.0.1"

signal server_started
signal client_joined
signal game_started
signal connection_failed


func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, 1)
	if err != OK:
		push_error("Failed to create server: %s" % err)
		connection_failed.emit()
		return
	is_hosting = true
	multiplayer.multiplayer_peer = peer
	server_started.emit()


func start_client(address: String = DEFAULT_ADDRESS) -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		push_error("Failed to create client: %s" % err)
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


func _on_peer_connected(_id: int) -> void:
	if is_hosting:
		client_joined.emit()
		_begin_battle()


func _on_peer_disconnected(_id: int) -> void:
	if is_hosting:
		client_joined.emit()


func _on_connected_to_server() -> void:
	_begin_battle()


func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()


func _begin_battle() -> void:
	if _game_started:
		return
	_game_started = true
	game_started.emit()
	if get_tree().current_scene == null or get_tree().current_scene.scene_file_path != "res://scenes/main.tscn":
		get_tree().change_scene_to_file("res://scenes/main.tscn")
