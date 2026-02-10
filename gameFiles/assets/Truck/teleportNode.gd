extends Interactable

@export var TeleportSpot : Node3D
@export var truckInterior : StaticBody3D

func _on_interacted(body: Node) -> void:
	
	var parent = body.get_parent()
	if parent:
		parent.remove_child(body)
	
	truckInterior.add_child(body)
	
	body.global_transform = TeleportSpot.global_transform
