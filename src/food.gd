extends PathFollow2D

@onready var rotate_speed = 1.0
@onready var speed = 100.0
@onready var direction = 1

func _ready():
	if randi() % 2 == 0:
		direction = -1

func _process(delta):
	progress += delta * speed * direction
	rotate(rotate_speed * delta)
