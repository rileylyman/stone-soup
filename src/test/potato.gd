extends RigidBody2D

var is_hovering = false

func _process(delta):
	if Input.is_action_just_pressed("left_click") and is_hovering:
		get_tree().get_first_node_in_group("MouseJoint").attach(self, get_global_mouse_position())

func _on_area_2d_mouse_entered():
	is_hovering = true

func _on_area_2d_mouse_exited():
	is_hovering = false
