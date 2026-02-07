extends VehicleBody3D

@onready var frWheel := $FRWheel
@onready var flWheel := $FLWheel
@onready var crWheel := $CRWheel
@onready var clWheel := $CLWheel
@onready var rrWheel := $RRWheel
@onready var rlWheel := $RLWheel

var isActive = false
var steeringAngle = 0
var engineForce = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(_event) -> void:
	
	if Input.is_action_just_pressed("truckForwards"):
		engineForce = 1
	
	if Input.is_action_just_released("truckForwards"):
		engineForce = 0
	
	if Input.is_action_just_pressed("truckBack"):
		engineForce = -1
	
	if Input.is_action_just_released("truckBack"):
		engineForce = 0
	
	if Input.is_action_just_pressed("truckLeft"):
		steeringAngle = .25
	
	if Input.is_action_just_released("truckLeft"):
		steeringAngle = 0
	
	if Input.is_action_just_pressed("truckRight"):
		steeringAngle = -.25
	
	if Input.is_action_just_released("truckRight"):
		steeringAngle = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	frWheel.engine_force = engineForce
	flWheel.engine_force = engineForce
	crWheel.engine_force = engineForce
	clWheel.engine_force = engineForce
	rrWheel.engine_force = engineForce
	rlWheel.engine_force = engineForce
	
	frWheel.steering = steeringAngle
	flWheel.steering = steeringAngle
	rrWheel.steering = -steeringAngle
	rlWheel.steering = -steeringAngle
