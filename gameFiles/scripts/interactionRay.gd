extends RayCast3D

@onready var prompt = $prompt

func _physics_process(_delta):
	prompt.text = ""
	
	if is_colliding():
		var collider = get_collider()
		if collider.has_method("getPrompt"):
			prompt.text = collider.getPrompt(owner)
