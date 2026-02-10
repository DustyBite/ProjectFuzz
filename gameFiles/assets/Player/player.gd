extends CharacterBody3D

# -------------------
# NODES
# -------------------

@onready var head := $head
@onready var firstPersonCamera := $head/firstPersonCamera
@onready var thirdPersonCamera := $head/thirdPersonCamera

@onready var standingCollisionShape := $standingCollisionShape
@onready var crouchingCollisionShape := $crouchingCollisionShape
@onready var playerHeightRC := $crouchRC
@onready var jumpHeightRC := $jumpRC

@onready var firstPersonModel := $head/firstPersonModel
@onready var thirdPersonModel := $thirdPersonModel
@onready var thirdPersonTemp := $thirdPersonModel/playerModelTemp

@onready var vest : Node = $vest
@onready var dropPos := $dropPos

@onready var flashlight := $head/flashlight
#@onready var pauseUI := $pauseUI

@onready var weaponLabel := $"UI Items/weaponLabel"
@onready var ammoType := $"UI Items/ammoType"
@onready var ammoLabel := $"UI Items/ammoLabel"

# -------------------
# EQUIPMENT
# -------------------

@export var primary : Node3D
@export var secondary : Node3D
@export var tertiary : Node3D
var curEquipSlot = 0
var equippedItem : Node3D = null

# -------------------
# TRUCK
# -------------------
var truck : Node3D

# -------------------
# STATE
# -------------------

var inPauseMenu := false
var inTerminal := false

var currentSpeed := 5.0
const walkingSpeed := 4.0
const sprintingSpeed := 8.0
const crouchingSpeed := 2.0

var crouchingDepth := -0.5
const jumpVelocity := 4.5
var lerpSpeed := 10.0

var direction := Vector3.ZERO
const mouseSens := 0.25
var camera := 1
var flashlightToggle := false


# -------------------
# VISIBILITY HELPERS
# -------------------

func set_layer_recursive(node: Node, layer: int, add := false):
	if node is VisualInstance3D:
		if add:
			node.layers |= (1 << (layer - 1))
		else:
			node.layers = (1 << (layer - 1))

	for child in node.get_children():
		set_layer_recursive(child, layer, add)


func setup_visibility_layers():
	if is_multiplayer_authority():
		# Local player
		firstPersonCamera.cull_mask = 0b00000011
		thirdPersonCamera.cull_mask = 0b00000101

		set_layer_recursive(firstPersonModel, 2)
		set_layer_recursive(thirdPersonModel, 1)
		set_layer_recursive(thirdPersonModel, 3, true)
	else:
		# Remote player
		set_layer_recursive(thirdPersonModel, 1)
		set_layer_recursive(firstPersonModel, 0)


# -------------------
# LIFECYCLE
# -------------------

func _ready():
	# Authority may not be valid yet on clients
	call_deferred("_post_ready")

func _post_ready():
	print("Player:", name, " Authority:", get_multiplayer_authority())

	setup_visibility_layers()

	if is_multiplayer_authority():
		firstPersonCamera.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print("✓ Local player")
	else:
		# Remote players never keep cameras
		firstPersonCamera.queue_free()
		thirdPersonCamera.queue_free()
		print("✗ Remote player")


# -------------------
# INPUT
# -------------------

func _process(_delta):
	if Input.is_action_pressed("attack"):
		if equippedItem != null:
			equippedItem.useHeld()
	elif Input.is_action_just_released("attack"):
		if equippedItem != null:
			equippedItem.useReleased()
	
	checkAmmo()
	

func _input(event):
	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("pause"):
		if inPauseMenu:
			unpauseGame()
		else:
			pauseGame()
		return

	if inPauseMenu or inTerminal:
		return

	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouseSens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouseSens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if Input.is_action_just_pressed("changeCamera"):
		changeCamera()
	
	if Input.is_action_just_pressed("drop"):
		dropEquipped()
	
	if Input.is_action_just_pressed("primary"):
		gunInteraction(1)
	
	if Input.is_action_just_pressed("secondary"):
		gunInteraction(2)
	
	if Input.is_action_just_pressed("tertiary"):
		gunInteraction(3)
	
	if Input.is_action_just_pressed("changeAmmoType"):
		if equippedItem != null and equippedItem.has_method("changeAmmo"):
			equippedItem.changeAmmo()
	
	if Input.is_action_just_pressed("reload"):
		if equippedItem != null:
			equippedItem.reload()
	
	if Input.is_action_just_pressed("flashlight"):
		toggleFlashlight()


# -------------------
# PHYSICS
# -------------------

func _physics_process(delta):
	if not is_multiplayer_authority():
		# Prevent drift on remote players
		velocity = Vector3.ZERO
		return

	if get_tree().paused or inTerminal:
		return

	# Crouch
	if Input.is_action_pressed("crouch"):
		currentSpeed = crouchingSpeed
		head.position.y = lerp(head.position.y, 1.35 + crouchingDepth, delta * lerpSpeed)
		standingCollisionShape.disabled = true
		crouchingCollisionShape.disabled = false
		
		var mesh = thirdPersonTemp.mesh
		mesh.height = 1.0
		thirdPersonTemp.position.y = mesh.height * 0.5
		
	elif not playerHeightRC.is_colliding():
		head.position.y = lerp(head.position.y, 1.35, delta * lerpSpeed)
		standingCollisionShape.disabled = false
		crouchingCollisionShape.disabled = true
		
		var mesh = thirdPersonTemp.mesh
		mesh.height = 1.6
		thirdPersonTemp.position.y = mesh.height * 0.5
		
		currentSpeed = sprintingSpeed if Input.is_action_pressed("sprint") else walkingSpeed

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not jumpHeightRC.is_colliding():
		velocity.y = jumpVelocity

	# Movement
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var forward = head.global_transform.basis.z
	var right = head.global_transform.basis.x
	var target_dir = (right * input_dir.x + forward * input_dir.y).normalized()

	direction = direction.lerp(target_dir, delta * lerpSpeed)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()


# -------------------
# ACTIONS
# -------------------

func changeCamera():
	if not firstPersonCamera or not thirdPersonCamera:
		return

	if camera == 1:
		thirdPersonCamera.current = true
		camera = 2
	else:
		firstPersonCamera.current = true
		camera = 1

func pickupEquip(item):
	if primary == null:
		primary = item
		gunInteraction(1)
	elif secondary == null:
		secondary = item
		gunInteraction(2)
	elif tertiary == null:
		tertiary = item
		gunInteraction(3)
	else:
		print("No Open Slots")
		return
	
	var parent = item.get_parent()
	if parent:
		parent.remove_child(item)
	
	firstPersonModel.add_child(item)
	item.freeze = true
	item.assignEquip(self)

func dropEquipped():
	if equippedItem == null:
		return
	
	equippedItem.clearAmmo()
	equippedItem.setCollision(true)
	
	# Get the actual parent and remove from it
	var parent = equippedItem.get_parent()
	if parent:
		parent.remove_child(equippedItem)
	
	# Add to the world
	get_tree().root.add_child(equippedItem)
	
	# Set position where it should drop
	equippedItem.global_transform = dropPos.global_transform
	
	# Optional: Add physics so it falls/can be picked up
	if equippedItem is RigidBody3D:
		equippedItem.freeze = false
		equippedItem.linear_velocity = -global_transform.basis.z * 3
	
	# Clear equipped reference
	equippedItem = null
	
	match curEquipSlot:
		1:
			primary = null
		2:
			secondary = null
		3:
			tertiary = null
	
	curEquipSlot = 0

func gunInteraction(gun):
	var guns = {
		1: primary,
		2: secondary,
		3: tertiary
	}

	var selected = guns.get(gun)
	if selected == null:
		return
	
	for item in guns.values():
		if item != null:
			item.visible = false
	
	if curEquipSlot == gun:
		selected.visible = false
		equippedItem = null
		curEquipSlot = 0
	else:
		selected.visible = true
		equippedItem = selected
		curEquipSlot = gun


func toggleFlashlight():
	flashlightToggle = !flashlightToggle
	flashlight.light_energy = 2 if flashlightToggle else 0


func pauseGame():
	inPauseMenu = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func unpauseGame():
	inPauseMenu = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# -------------------
# UI Elements
# -------------------

func checkAmmo():
	if equippedItem != null:
		weaponLabel.text = equippedItem.weaponLabel
		ammoType.text = equippedItem.ammoType
		ammoLabel.text = equippedItem.allAmmo
	else:
		weaponLabel.text = ""
		ammoType.text = ""
		ammoLabel.text = ""
