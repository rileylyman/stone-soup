extends Control

func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		var is_full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if not is_full else DisplayServer.WINDOW_MODE_WINDOWED)
