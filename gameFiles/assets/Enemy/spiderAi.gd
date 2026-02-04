extends BaseAI

# State change settings
@export var state_change_interval_min: float = 3.0
@export var state_change_interval_max: float = 8.0
@export var idle_weight: float = 1.0
@export var wander_weight: float = 3.0
@export var chase_weight: float = 0.5
@export var flee_weight: float = 0.5

var state_change_timer: float = 0.0
var dummy_target: Node3D  # For chase/flee without real target

func _ready() -> void:
	super._ready()
	
	# Create a dummy target node for random movement
	dummy_target = Node3D.new()
	add_child(dummy_target)
	
	# Start with a random state
	_pick_random_state()
	_reset_state_timer()

func _physics_process(delta: float) -> void:
	state_change_timer -= delta
	
	# Time to switch states
	if state_change_timer <= 0:
		_pick_random_state()
		_reset_state_timer()
	
	# Update dummy target position if needed
	if current_state == State.CHASE or current_state == State.FLEE:
		_update_dummy_target()
	
	super._physics_process(delta)

func _pick_random_state() -> void:
	# Build a weighted list of states
	var states = []
	
	# Add states based on weights
	for i in idle_weight:
		states.append(State.IDLE)
	for i in wander_weight:
		states.append(State.WANDER)
	for i in chase_weight:
		states.append(State.CHASE)
	for i in flee_weight:
		states.append(State.FLEE)
	
	# Pick random state
	if states.size() > 0:
		var random_state = states[randi() % states.size()]
		change_state(random_state)
		
		# Set dummy target for chase/flee
		if random_state == State.CHASE or random_state == State.FLEE:
			set_target(dummy_target)
			_place_dummy_target()

func _reset_state_timer() -> void:
	state_change_timer = randf_range(state_change_interval_min, state_change_interval_max)

func _place_dummy_target() -> void:
	# Place dummy target at a random nearby position
	var random_offset = Vector3(
		randf_range(-detection_range, detection_range),
		0,
		randf_range(-detection_range, detection_range)
	)
	dummy_target.global_position = global_position + random_offset

func _update_dummy_target() -> void:
	# Keep dummy target at ground level
	dummy_target.global_position.y = global_position.y
