extends Node3D
class_name WorldScript

const PLAYER_SCENE := preload("res://assets/Player/player.tscn")
const PORT := 7000
const MAX_CLIENTS := 3

@export var singleplayer_mode := false
@export var bunker_mode := false


@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

var spawn_points: Array[Vector3] = []
var next_spawn_index := 0


func _ready():
	if bunker_mode:
		generateBunker()
	
	spawn_points = get_spawn_points()

	if singleplayer_mode:
		print("SINGLEPLAYER MODE")
		var player := PLAYER_SCENE.instantiate()
		player.name = "1"
		add_child(player)
		player.global_position = spawn_points[0]
		return

	# MultiplayerSpawner setup (Godot 4.6)
	spawner.add_spawnable_scene(PLAYER_SCENE.resource_path)
	spawner.spawn_function = _spawn_player

	# Multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

	# Launch mode
	if "--client" in OS.get_cmdline_args():
		print("Starting as CLIENT")
		await get_tree().create_timer(0.5).timeout
		join_game("127.0.0.1")
	else:
		print("Starting as SERVER")
		host_game()

func generateBunker():
	pass

func get_spawn_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for child in $spawnPoints.get_children():
		if child is Marker3D:
			points.append(child.global_position)
	return points


# -------------------------
# NETWORK SETUP
# -------------------------

func host_game():
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to start server: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	print("✓ Server started on port ", PORT)

	# Spawn server player
	spawn_player(multiplayer.get_unique_id())


func join_game(address: String):
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		push_error("Failed to connect: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	print("→ Connecting to ", address, ":", PORT)


# -------------------------
# PLAYER SPAWNING
# -------------------------

# This runs on ALL peers
func _spawn_player(peer_id: int) -> Node:
	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)

	var spawn_pos := spawn_points[next_spawn_index % spawn_points.size()]
	next_spawn_index += 1
	player.position = spawn_pos

	player.set_multiplayer_authority(peer_id)

	print("Spawned player node for peer ", peer_id)
	return player


# This runs ONLY on the server
func spawn_player(peer_id: int):
	if not multiplayer.is_server():
		return

	print("Requesting spawn for peer ", peer_id)
	spawner.spawn(peer_id)


func _on_peer_connected(id: int):
	print("Peer connected: ", id)

	if multiplayer.is_server():
		spawn_player(id)


func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)

	if has_node(str(id)):
		get_node(str(id)).queue_free()


# -------------------------
# CLIENT EVENTS
# -------------------------

func _on_connected_to_server():
	print("✓ Connected to server")
	print("My peer ID: ", multiplayer.get_unique_id())


func _on_connection_failed():
	print("✗ Connection failed")
