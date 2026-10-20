extends RigidBody2D

const LIFETIME = 2.5

var age = 0.0


func _ready():
	add_to_group("debris")


func _process(delta):
	age += delta
	if age > LIFETIME:
		queue_free()
