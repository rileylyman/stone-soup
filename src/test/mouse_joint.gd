extends Node2D

@export var connection = null

func _process(delta):
	if Input.is_action_just_pressed("left_click"):
		$StaticBody2D/CollisionShape2D.disabled = false
	if Input.is_action_just_released("left_click"):
		$StaticBody2D/CollisionShape2D.disabled = true
	if Input.is_action_pressed("left_click"):
		$PinJoint2D.position = get_global_mouse_position()
		$StaticBody2D.position = get_global_mouse_position()

func attach(obj : Node2D, pos):
	$StaticBody2D.position = pos
	$PinJoint2D.position = pos
	$PinJoint2D.node_b = obj.get_path()
