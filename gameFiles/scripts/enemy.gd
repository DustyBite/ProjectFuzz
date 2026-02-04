extends RigidBody3D

@export var health = 100
@export var speed := 4.0

func _process(_delta):
	if health <= 0:
		self.queue_free()


func takeDamage(damage):
	health -= damage
	print(health)
