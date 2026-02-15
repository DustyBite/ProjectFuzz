extends WorldScript
@export var bunkerX := 5
@export var bunkerY := 5
@export var gridSpacing := 10.0   # size of 1 grid unit
@export var bunkerCeiling: PackedScene
@export var bunkerCeiling3x1: PackedScene  # NEW: Add your 3x1 centerpiece scene
@export var bunkerWall: PackedScene
@export var worldColor := Color(0,0,0)
@export var dayMode := false
@export var dayEnd := false
@export var raveMode := false
@export var voxelGI : VoxelGI
@export var voxelGIPadding := 20.0  # Padding around bunker for VoxelGI
@export var voxelGIHeight := 20.0  # Height of VoxelGI volume
var hue := 0.0
var dayTime := 0.0
var dayLength := 60.0
@onready var environment := $enviroment
@onready var worldEnvironment := $WorldEnvironment
@onready var bunkerSpawnPos : Marker3D = $bunkerSpawnPoint

func _ready():
	Global.worldColor = worldColor
	super._ready()

func _process(delta: float) -> void:
	worldEnvironment.environment.volumetric_fog_albedo = Global.worldColor
	
	if raveMode:
		hue += delta
		if hue > 1.0:
			hue -= 1.0
		Global.worldColor = Color.from_hsv(hue, 1.0, 1.0)
	
	if dayMode:
		dayTime += delta / dayLength
		if dayTime > 1.0:
			if dayEnd:
				Global.worldColor = Color(1.0, 0.0, 0.0)
				return
			dayTime = 0.0
		var t = dayTime
		var sun = clamp(sin(t * PI), 0.0, 1.0)
		var sunrise = Color(1.0, 0.6, 0.4)
		var noon    = Color(1.0, 0.98, 0.92)
		var sunset  = Color(0.95, 0.5, 0.3)
		var night   = Color(0.15, 0.2, 0.4)
		var color : Color
		if t < 0.25:
			color = sunrise.lerp(noon, t / 0.25)
		elif t < 0.75:
			color = noon.lerp(sunset, (t - 0.25) / 0.5)
		else:
			color = sunset.lerp(night, (t - 0.75) / 0.25)
		Global.worldColor = color * (sun * 1.0 + 0.15)

func generateBunker():
	print("I generate Bunker now")
	var tileSize := gridSpacing * 2.0
	var bunkerWidth := bunkerX * tileSize
	var bunkerDepth := bunkerY * tileSize
	var halfGrid := gridSpacing * 0.5
	
	# Calculate center offset to align bunker on X axis
	var centerOffsetX := -(bunkerWidth / 2.0) + (tileSize / 2.0)
	var spawnPos := bunkerSpawnPos.global_position
	
	# Calculate center X index for door entrance
	var centerXIndex := int(bunkerX / 2)
	
	# Calculate how many skylights can fit
	var numSkylights := 0
	var skylightPositions := []
	
	# Minimum size check
	if bunkerX >= 5 and bunkerY >= 3:
		numSkylights = (bunkerX - 1) / 4  # Automatically converts to int
		
		if numSkylights > 0:
			var currentX := 1  # Start after left border
			
			for i in range(numSkylights):
				var centerX := currentX + 1
				skylightPositions.append(centerX)
				currentX += 4
	
	if numSkylights > 0:
		print("Spawning %d skylight strip(s) at positions: %s" % [numSkylights, skylightPositions])
	else:
		print("Bunker too small for skylights - need at least 5x3 grid")
	
	# --- CEILING / FLOOR ---
	for x in range(bunkerX):
		for y in range(bunkerY):
			var shouldSkip := false
			
			# Check if this tile is part of any skylight
			if numSkylights > 0 and y >= 1 and y < bunkerY - 1:
				for centerX in skylightPositions:
					if x >= centerX - 1 and x <= centerX + 1:
						shouldSkip = true
						break
			
			if shouldSkip:
				continue
			
			var ceiling = bunkerCeiling.instantiate()
			ceiling.position = spawnPos + Vector3(x * tileSize + centerOffsetX, 0, y * tileSize)
			environment.add_child(ceiling)
	
	# --- SPAWN SKYLIGHT STRIPS ---
	if numSkylights > 0 and bunkerCeiling3x1:
		for centerX in skylightPositions:
			# Spawn a 3x1 piece for each Y position (except the borders)
			for y in range(1, bunkerY - 1):
				var centerpiece = bunkerCeiling3x1.instantiate()
				centerpiece.position = spawnPos + Vector3(centerX * tileSize + centerOffsetX, 0, y * tileSize)
				
				# Check if this is an edge piece
				var isFirstEdge := (y == 1)
				var isLastEdge := (y == bunkerY - 2)
				
				if isFirstEdge or isLastEdge:
					# Set isEdge to true
					if centerpiece.has_method("set"):
						centerpiece.set("isEdge", true)
					elif "isEdge" in centerpiece:
						centerpiece.isEdge = true
					
					# Rotate the last edge 180 degrees
					if isLastEdge:
						centerpiece.rotation_degrees.y = 180
				
				environment.add_child(centerpiece)
	
	# --- NORTH & SOUTH WALLS (along X axis) ---
	for x in range(bunkerX):
		# Skip the center wall segment on the south side (entrance)
		if x != centerXIndex:
			var worldX := x * gridSpacing * 2 + centerOffsetX
			# South wall (entrance side)
			spawnWall(spawnPos + Vector3(worldX, 0, -15), 90)
		
		# North wall (always spawn all segments)
		var worldX := x * gridSpacing * 2 + centerOffsetX
		spawnWall(spawnPos + Vector3(worldX, 0, bunkerDepth - 5), -90)
	
	# --- EAST & WEST WALLS (along Z axis) ---
	for y in range(bunkerY):
		var worldZ := y * gridSpacing * 2
		spawnWall(spawnPos + Vector3(-15 + centerOffsetX, 0, worldZ), 180)
		spawnWall(spawnPos + Vector3(bunkerWidth - halfGrid + centerOffsetX, 0, worldZ), 0)
	
	print("Bunker Generated :D")
	
	if voxelGI:
		updateVoxelGI(spawnPos, centerOffsetX, bunkerWidth, bunkerDepth)

func updateVoxelGI(spawnPos: Vector3, centerOffsetX: float, bunkerWidth: float, bunkerDepth: float):
	# Position the VoxelGI in the center of the bunker
	voxelGI.position = spawnPos + Vector3(centerOffsetX + bunkerWidth / 2.0, 0, bunkerDepth / 2.0)
	
	# Set the size to cover the entire bunker with custom padding
	voxelGI.size = Vector3(bunkerWidth + voxelGIPadding, voxelGIHeight, bunkerDepth + voxelGIPadding)
	
	# Wait one frame for geometry to be fully added
	await get_tree().process_frame
	
	# Rebake the VoxelGI
	voxelGI.bake()
	
	print("VoxelGI updated and rebaked!")



func spawnWall(pos: Vector3, rot_y: float):
	var wall = bunkerWall.instantiate()
	wall.position = pos
	wall.rotation_degrees.y = rot_y
	environment.add_child(wall)
