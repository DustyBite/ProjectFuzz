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

@export var weaponLabel: String
@export_enum("9mil", "shotgun") var caliber: String
@export var magSize: int
@export var ammoTotal: int
@export var fireRate: float
@export var fireRange: float = 500
@export var isAutomatic: bool = false

var canFire:= true
var triggerPulled: bool = false
var currentAmmo = 0
var allAmmo: String = ""
var vest : Node

func _ready() -> void:
	var player = self.get_parent().get_parent().get_parent()
	vest = player.get_child(2)
	
	getAmmo()
	updateAmmo()
	
	raycast.enabled = false
	raycast.target_position = Vector3(0, 0, fireRange)
	currentAmmo = magSize
	
	# Create debug line
	debugLine = MeshInstance3D.new()
	add_child(debugLine)
	debugLine.mesh = ImmediateMesh.new()
	
	# Add material so it's visible
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.RED
	debugLine.material_override = material

func getAmmo():
	getAmmoType()

func getAmmoType():
	pass

func updateAmmo():
	match caliber:
		"9mil":
			vest.nineMilAmmo = ammoTotal
		"shotgun":
			vest.shotgunAmmo = ammoTotal

func clearAmmo():
	ammoTotal += currentAmmo
	currentAmmo = 0
	updateAmmo()

func _process(_delta):
	allAmmo = str(currentAmmo) + "/" + str(ammoTotal)

func useHeld():
	if canFire and currentAmmo > 0:
		if not isAutomatic and triggerPulled:
			return
		
		triggerPulled = true
		
		currentAmmo -= 1
		#print(currentAmmo)
		shoot()
		canFire = false
		await get_tree().create_timer(fireRate).timeout
		canFire = true
	elif currentAmmo == 0:
		#print("Out of Ammo")
		return

func useReleased():
	triggerPulled = false

func reload():
	#getAmmo()
	if currentAmmo == magSize:
		print("No need to reload")
		return
	elif ammoTotal > 0:
		var dif
		dif = magSize - currentAmmo
		if dif > ammoTotal:
			dif = ammoTotal
		currentAmmo += dif
		ammoTotal -= dif
		print("reloaded")
	else:
		print("out of Ammo")
	updateAmmo()

func shoot():
	match caliber:
		"9mil":
			shootSingle(false, 2.0, 10)
		"shotgun":
			shootSpread(8, 10, 10)

func shootSingle(pen: bool, spreadAngle: float, damage: int):
	var spreadX = randf_range(-spreadAngle, spreadAngle)
	var spreadY = randf_range(-spreadAngle, spreadAngle)
	
	raycast.rotation_degrees = Vector3(spreadX, spreadY, 0)
	
	var current_damage = damage
	var damage_falloff = 0.5
	
	var start = raycast.global_position
	var ray_direction = raycast.global_transform.basis.z
	var ray_origin = start
	var max_distance = fireRange
	
	var continue_penetrating = true
	var traveled_distance = 0.0
	
	while continue_penetrating and traveled_distance < max_distance:
		# Manual raycast using PhysicsRayQueryParameters3D
		var space_state = raycast.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * (max_distance - traveled_distance))
		var result = space_state.intersect_ray(query)
		
		if result:
			var hit_point = result.position
			var hitObject = result.collider
			
			if hitObject.has_method("takeDamage"):
				hitObject.takeDamage(int(current_damage))
			
			current_damage *= damage_falloff
			
			if not pen or current_damage < 1:
				draw_debug_line(start, hit_point)
				continue_penetrating = false
			else:
				# Continue ray from slightly past the hit point
				traveled_distance += start.distance_to(hit_point)
				ray_origin = hit_point + ray_direction * 0.01
		else:
			# No hit, draw to max range
			draw_debug_line(start, ray_origin + ray_direction * (max_distance - traveled_distance))
			continue_penetrating = false
	
	raycast.rotation_degrees = Vector3.ZERO

func shootSpread(pelletCount, shotgunSpread, damage):
	
	for i in range(pelletCount):
		var spreadX = randf_range(-shotgunSpread, shotgunSpread)
		var spreadY = randf_range(-shotgunSpread, shotgunSpread)
		
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
