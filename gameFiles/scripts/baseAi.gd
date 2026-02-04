class_name BaseAI
extends CharacterBody3D

enum State {
	IDLE,
	WANDER,
	CHASE,
	FLEE
}

@export var health: float = 100

# Movement settings
@export var move_speed: float = 3.0
@export var acceleration: float = 10.0
@export var rotation_speed: float = 8.0
@export var gravity: float = 9.8

# Wander settings
@export var wander_radius: float = 10.0
@export var wander_change_interval: float = 3.0

# Detection settings
@export var detection_range: float = 15.0
@export var chase_range: float = 20.0  # How far to chase before giving up
@export var flee_range: float = 8.0

var current_state: State = State.IDLE
var target: Node3D = null
var wander_target: Vector3
var wander_timer: float = 0.0
var detected_player: Node3D = null

func _ready() -> void:
	_pick_new_wander_target()

func _process(_delta):
	# Only the server should check for death
	if multiplayer.is_server() and health <= 0:
		die()

func takeDamage(damage):
	# If we're a client, ask the server to process damage
	if not multiplayer.is_server():
		rpc_id(1, "_server_take_damage", damage)
		return
	
	# Server processes damage
	_server_take_damage(damage)

@rpc("any_peer", "call_local", "reliable")
func _server_take_damage(damage):
	# Only server actually modifies health
	if not multiplayer.is_server():
		return
	
	health -= damage
	#print("Health: ", health)
	
	# Health is synced via MultiplayerSynchronizer, so clients will see it update

func die():
	# Tell everyone to delete this enemy
	rpc("_delete_on_all_peers")

@rpc("any_peer", "call_local", "reliable")
func _delete_on_all_peers():
	queue_free()

func _physics_process(delta: float) -> void:
	# Apply gravity FIRST, before state logic
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Check for nearby players
	_check_for_players()
	
	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.WANDER:
			_wander_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.FLEE:
			_flee_behavior(delta)
	
	move_and_slide()

func _check_for_players() -> void:
	var players = get_tree().get_nodes_in_group("player")
	var closest_player: Node3D = null
	var closest_distance: float = INF
	
	# Find the closest player
	for player in players:
		if player is Node3D:
			var distance = global_position.distance_to(player.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_player = player
	
	# Update behavior based on distance to closest player
	if closest_player:
		if closest_distance <= detection_range:
			# Player entered detection range - start chasing
			if current_state != State.CHASE:
				detected_player = closest_player
				set_target(closest_player)
				change_state(State.CHASE)
		elif current_state == State.CHASE and closest_distance > chase_range:
			# Player escaped chase range - give up
			detected_player = null
			change_state(State.WANDER)

func _idle_behavior(delta: float) -> void:
	# Gradually slow down (but keep y velocity for gravity)
	velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
	velocity.z = lerp(velocity.z, 0.0, acceleration * delta)

func _wander_behavior(delta: float) -> void:
	wander_timer -= delta
	
	if wander_timer <= 0:
		_pick_new_wander_target()
		wander_timer = wander_change_interval
	
	_move_toward_position(wander_target, delta)

func _chase_behavior(delta: float) -> void:
	if target and is_instance_valid(target):
		_move_toward_position(target.global_position, delta)
	else:
		# Lost target
		detected_player = null
		change_state(State.WANDER)

func _flee_behavior(delta: float) -> void:
	if target and is_instance_valid(target):
		var flee_direction = global_position - target.global_position
		var flee_target = global_position + flee_direction.normalized() * wander_radius
		_move_toward_position(flee_target, delta)
	else:
		change_state(State.WANDER)

func _move_toward_position(target_pos: Vector3, delta: float) -> void:
	var direction = (target_pos - global_position).normalized()
	direction.y = 0  # Keep movement on horizontal plane
	
	if direction.length() > 0.1:
		# Smoothly rotate toward target
		var target_basis = Basis.looking_at(direction, Vector3.UP)
		basis = basis.slerp(target_basis, rotation_speed * delta)
		
		# Move forward (only affect x and z, leave y for gravity)
		var target_velocity = direction * move_speed
		velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)

func _pick_new_wander_target() -> void:
	var random_offset = Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)
	wander_target = global_position + random_offset

func change_state(new_state: State) -> void:
	current_state = new_state
	
	match new_state:
		State.WANDER:
			_pick_new_wander_target()
			wander_timer = wander_change_interval

func set_target(new_target: Node3D) -> void:
	target = new_target

func get_distance_to_target() -> float:
	if target and is_instance_valid(target):
		return global_position.distance_to(target.global_position)
	return INF
