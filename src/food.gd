extends Area2D

@onready var rotate_speed = 1.0
@onready var speed = 150.0
@onready var direction = Vector2.ZERO

@export var buffer = 0.0

func _ready():
	rotate_speed = randf_range(1, 1.5)
	direction.x = randf_range(-1, 1)
	direction.y = randf_range(-1, 1)
	speed = randf_range(80, 90)
	$Shadow.texture = $Sprite2D.texture

func _process(delta):
	$Sprite2D.rotate(rotate_speed * delta)
	$Shadow.rotate(rotate_speed * delta)
	position += direction * speed * delta
	if position.x < -buffer or position.x > get_viewport_rect().size.x + buffer:
		direction.x *= -1
	if position.y < -buffer or position.y > get_viewport_rect().size.y + buffer:
		direction.y *= -1
	if Input.is_action_just_pressed("left_click"):
		var sprite_rect : Rect2 = $Sprite2D.get_rect()
		if sprite_rect.has_point(get_local_mouse_position()):
			queue_free()
