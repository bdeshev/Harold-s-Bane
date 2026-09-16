extends Control

@onready var address_input: LineEdit = %AddressInput
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var status_label: Label = %StatusLabel

const STATUS_HOSTING := "Hosting. Waiting for opponent..."
const STATUS_CONNECTED := "Opponent connected. Starting battle..."
const STATUS_FAILED := "Connection failed."


func _ready() -> void:
	address_input.text = HighLevelNetworkHandler.get_local_ip()
	HighLevelNetworkHandler.server_started.connect(_on_server_started)
	HighLevelNetworkHandler.game_started.connect(_on_game_started)
	HighLevelNetworkHandler.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_join_success)


func _on_host_pressed() -> void:
	if host_button.disabled:
		return
	host_button.disabled = true
	join_button.disabled = true
	HighLevelNetworkHandler.start_server()


func _on_join_pressed() -> void:
	if join_button.disabled:
		return
	join_button.disabled = true
	host_button.disabled = true
	HighLevelNetworkHandler.start_client(address_input.text.strip_edges())


func _on_server_started() -> void:
	status_label.text = "Hosting at %s — waiting for opponent..." % HighLevelNetworkHandler.get_local_ip()


func _on_join_success() -> void:
	status_label.text = "Connected. Waiting for battle to start..."


func _on_connection_failed() -> void:
	status_label.text = STATUS_FAILED
	host_button.disabled = false
	join_button.disabled = false


func _on_game_started() -> void:
	status_label.text = STATUS_CONNECTED
	get_tree().paused = false
	visible = false
	_show_game(true)


func _show_game(shown: bool) -> void:
	var root := get_tree().current_scene
	for node in root.get_children():
		if node is MultiplayerSpawner:
			continue
		node.visible = shown