extends CollisionObject3D
class_name Interactable

signal interacted(body)

@export var promptMessage = "Interact"
@export var promptInput = "interact"

func getPrompt(_body):
	var keyName = ""
	for action in InputMap.action_get_events(promptInput):
		if action is InputEventKey:
			keyName = action.as_text_physical_keycode()
			break
	
	return promptMessage + "\n[" + keyName + "]"

func interact(body):
	interacted.emit(body)
