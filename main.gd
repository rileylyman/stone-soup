extends Node2D

func _ready():
	await get_tree().process_frame
	if OS.has_feature("run_soup"):
		get_tree().change_scene_to_file("res://src/soup.tscn")
	else:
		get_tree().change_scene_to_file("res://src/doodle.tscn")