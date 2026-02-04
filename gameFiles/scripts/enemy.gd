extends Node

var health = 100

func _process(_delta):
	if health <= 0:
		self.queue_free()

func takeDamage(damage):
	health -= damage
	print(health)
