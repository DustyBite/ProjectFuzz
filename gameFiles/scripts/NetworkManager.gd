extends Node

var my_peer_id: int = 1

func set_peer_id(id: int):
	my_peer_id = id
	print("NetworkManager: Set peer ID to ", id)

func get_peer_id() -> int:
	return my_peer_id
