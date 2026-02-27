extends Interactable

@export var parentSpot : Node3D
@export var unparentSpot : Node3D

@export var truckInterior : StaticBody3D

func _on_interacted(body: Node) -> void:
	
	var parent = body.get_parent()
	if parent != truckInterior:
		parent.remove_child(body)
		truckInterior.add_child(body)
		body.global_transform = parentSpot.global_transform
	
	else:
		parent.remove_child(body)
		var root = get_tree().get_current_scene()
		root.add_child(body)
		body.global_transform = unparentSpot.global_transform
		body.global_rotation = Vector3()
