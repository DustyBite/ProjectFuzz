extends VehicleBody3D

@onready var frWheel := $FRWheel
@onready var flWheel := $FLWheel
@onready var crWheel := $CRWheel
@onready var clWheel := $CLWheel
@onready var rrWheel := $RRWheel
@onready var rlWheel := $RLWheel
@onready var truck := self


var isActive = false
var steeringAngle: float  = 0
var targetAngle: float = 0
var steerSpeed: float  = 5.0
@export var engineForce = 2000
@export var brakeForce = 50
@export var maxSteerAngle: float  = .40

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(_event) -> void:
	
	if Input.is_action_just_pressed("truckForwards"):
		truck.engine_force = engineForce
	
	if Input.is_action_just_released("truckForwards"):
		truck.engine_force = 0
	
	if Input.is_action_just_pressed("truckBack"):
		truck.brake = brakeForce
	
	if Input.is_action_just_released("truckBack"):
		truck.brake = 0
	
	if Input.is_action_just_pressed("truckLeft"):
		targetAngle = maxSteerAngle
	
	if Input.is_action_just_released("truckLeft"):
		targetAngle = 0
	
	if Input.is_action_just_pressed("truckRight"):
		targetAngle = -maxSteerAngle
	
	if Input.is_action_just_released("truckRight"):
		targetAngle = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	#frWheel.engine_force = engineForce
	#flWheel.engine_force = engineForce
	#crWheel.engine_force = engineForce
	#clWheel.engine_force = engineForce
	#rrWheel.engine_force = engineForce
	#rlWheel.engine_force = engineForce
	
	steeringAngle = lerp_angle(steeringAngle, targetAngle, steerSpeed * delta)
	
	frWheel.steering = steeringAngle
	flWheel.steering = steeringAngle
	rrWheel.steering = -steeringAngle
	rlWheel.steering = -steeringAngle
