extends Node
class_name GunScript
# -------------------
# NODES
# -------------------
@onready var raycast := $RayCast3D
var debugLine: MeshInstance3D
# -------------------
# STATE
# -------------------
@export_enum("9mil", "shotgun") var ammoType: String
@export var maxAmmo: int
@export var fireRate: float
@export var spreadAngle: float = 2.0
@export var fireRange: float = 500
@export var damage: int = 10
@export var isAutomatic: bool = false

var canFire:= true
var triggerPulled: bool = false
var currentAmmo = 0

func _ready() -> void:
	raycast.enabled = false
	raycast.target_position = Vector3(0, 0, fireRange)
	currentAmmo = maxAmmo
	
	# Create debug line
	debugLine = MeshInstance3D.new()
	add_child(debugLine)
	debugLine.mesh = ImmediateMesh.new()
	
	# Add material so it's visible
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.RED
	debugLine.material_override = material

func useHeld():
	if canFire and currentAmmo > 0:
		if not isAutomatic and triggerPulled:
			return
		
		triggerPulled = true
		
		currentAmmo -= 1
		print(currentAmmo)
		shoot()
		canFire = false
		await get_tree().create_timer(fireRate).timeout
		canFire = true
	elif currentAmmo == 0:
		print("Out of Ammo")
		return

func useReleased():
	triggerPulled = false

func reload():
	currentAmmo = maxAmmo
	print("reloaded")

func shoot():
	match ammoType:
		"9mil":
			shootSingle()
		"shotgun":
			shootShotgun()

func shootSingle():
	var spreadX = randf_range(-spreadAngle, spreadAngle)
	var spreadY = randf_range(-spreadAngle, spreadAngle)
	
	raycast.rotation_degrees = Vector3(spreadX, spreadY, 0)
	
	raycast.enabled = true
	raycast.force_raycast_update()
	
	var start = raycast.global_position
	var end = raycast.get_collision_point() if raycast.is_colliding() else raycast.global_position + raycast.global_transform.basis * raycast.target_position
	
	# Draw debug line
	draw_debug_line(start, end)
	
	if raycast.is_colliding():
		var hitObject = raycast.get_collider()
		
		# Apply damage
		if hitObject.has_method("takeDamage"):
			hitObject.takeDamage(damage)
	
	raycast.enabled = false
	raycast.rotation_degrees = Vector3.ZERO

func shootShotgun():
	var pellet_count = 8  # Number of pellets per shot
	var shotgun_spread = 10.0  # Wider spread than normal guns
	
	for i in range(pellet_count):
		var spreadX = randf_range(-shotgun_spread, shotgun_spread)
		var spreadY = randf_range(-shotgun_spread, shotgun_spread)
		
		raycast.rotation_degrees = Vector3(spreadX, spreadY, 0)
		
		raycast.enabled = true
		raycast.force_raycast_update()
		
		var start = raycast.global_position
		var end = raycast.get_collision_point() if raycast.is_colliding() else raycast.global_position + raycast.global_transform.basis * raycast.target_position
		
		# Draw debug line
		draw_debug_line(start, end)
		
		if raycast.is_colliding():
			var hitObject = raycast.get_collider()
			
			# Apply damage per pellet (usually less than full damage)
			if hitObject.has_method("takeDamage"):
				hitObject.takeDamage(damage)
		
		raycast.enabled = false
		raycast.rotation_degrees = Vector3.ZERO

func draw_debug_line(start: Vector3, end: Vector3):
	# Create a NEW mesh instance each time
	var line = MeshInstance3D.new()
	get_tree().root.add_child(line)  # Add to root so it stays in world space
	line.mesh = ImmediateMesh.new()
	
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.GREEN  # Start with green
	line.material_override = material
	
	var mesh = line.mesh as ImmediateMesh
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start)  # Use global positions directly
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	
	# Fade from green to red over time
	var lifetime = 5.0
	var elapsed = 0.0
	
	while elapsed < lifetime:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
		var t = elapsed / lifetime  # 0 to 1
		material.albedo_color = Color.GREEN.lerp(Color.RED, t)
	
	line.queue_free()
