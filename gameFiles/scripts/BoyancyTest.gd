extends RigidBody3D

@export var floatForce := 1.0
@export var waterDrag := .05
@export var waterAngularDrag := .05

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

const waterHeight := 0
var submerged := false

func _physics_process(_delta: float) -> void:
	submerged = false
	var depth = (waterHeight + .5) - global_position.y
	if depth > 0 :
		submerged = true
		apply_central_force(Vector3.UP * floatForce * gravity * depth)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity *= 1 - waterDrag
		state.angular_velocity *= 1 - waterAngularDrag
