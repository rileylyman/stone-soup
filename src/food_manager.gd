extends Node2D

const Food = preload("res://src/food.tscn")

func _process(delta):
	if Input.is_action_just_pressed("add_item"):
		add_food()

func add_food():
	var next_food : PathFollow2D = Food.instantiate()
	$Paths.get_child(randi() % $Paths.get_child_count()).add_child(next_food)
	next_food.progress_ratio = randf()
