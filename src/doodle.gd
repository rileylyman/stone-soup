extends Control

var _color: Color = Color(0, 0, 0)
@onready var canvas: TextureRect = $Canvas

var data_size_x: int = 64
var data_size_y: int = 64
var data: Array

@onready var scale_x: float = canvas.size.x / data_size_x
@onready var scale_y: float = canvas.size.x / data_size_x

@export var starting_button : PaletteButton = null

var brush_size: int = 4
var last_pressed_pos = Vector2(0, 0)
var last_pressed = false
var current_tool = ""

var drawn_since_reset = false
var has_updated_canvas = false
var image_stack = []

func _ready() -> void:
	_reset_canvas()
	for pb : PaletteButton in $JonPalette.get_children():
		pb.color_picked.connect(_on_palette_color_selected)
	starting_button.button_pressed = true
	_color = starting_button.color
	$PencilTool.button_pressed = true

func _reset_canvas():
	data = []
	for i in range(data_size_x * data_size_y):
		data.append(0)
		data.append(0)
		data.append(0)
		data.append(0)
	var image := Image.new()
	image.set_data(data_size_x, data_size_y, false, Image.FORMAT_RGBA8, data)
	canvas.texture = ImageTexture.create_from_image(image)
	$SendToServer.disabled = true
	$SendToServer.mouse_default_cursor_shape = CURSOR_ARROW

var draw_points = []
func _process(_delta: float) -> void:
	var x = _get_canvas_mouse_x()
	var y = _get_canvas_mouse_y()
	if Input.is_action_just_pressed("left_click") and current_tool == "Bucket":
		if (x >= 0 and x < data_size_x) and (y >= 0 and y <= data_size_y):
			var check_color = _get_color_at(x, y)
			_bucket_fill(Vector2(x, y), check_color)
			for point in fill_points:
				_draw_at(point.x, point.y, _color)
			_update_canvas()
	if Input.is_action_just_released("left_click"):
		if has_updated_canvas:
			has_updated_canvas = false
			if canvas.texture != null:
				image_stack.push_back(canvas.texture.get_image())
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if current_tool == "Bucket":
			return
		if x >= 0 and x < data_size_x and y >= 0 and y < data_size_y:
			_draw_at_sz(x, y, _color, brush_size)
			_update_canvas()
			if last_pressed:
				var curr_pos = Vector2(x, y)
				if curr_pos.distance_to(last_pressed_pos) > (brush_size >> 2):
					_draw_line(curr_pos, last_pressed_pos)
		last_pressed_pos = Vector2(x, y)
		last_pressed = true
	else:
		last_pressed = false
	if Input.is_action_just_pressed("fullscreen"):
		var is_full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if not is_full else DisplayServer.WINDOW_MODE_WINDOWED)

func _draw_line(start_pos : Vector2, end_pos : Vector2):
	var direction = start_pos.direction_to(end_pos)
	var add_buffer = direction * (brush_size >> 2)
	var curr_pos = start_pos + add_buffer
	var sz = brush_size
	while curr_pos.distance_to(end_pos) > (brush_size >> 2):
		for i in range(sz):
			for j in range(sz):
				if i == 0 and j == 0 or (i == sz-1 and j == sz-1):
					continue
				if (i == 0 and j == sz-1) or (i == sz-1 and j == 0):
					continue
				_draw_at(curr_pos.x + i - int(sz / 2.0), curr_pos.y + j - int(sz / 2.0), _color)
		curr_pos += add_buffer

var fill_points = []
func _bucket_fill(pos : Vector2, check_color : Color):
	if pos.x < 0 or pos.x >= data_size_x or pos.y < 0 or pos.y >= data_size_y:
		return
	fill_points.clear()
	var points = []
	points.push_back(pos)
	while not points.is_empty():
		var next_point = points.pop_front()
		if next_point.x < 0 or next_point.y >= data_size_x or next_point.y < 0 or next_point.y >= data_size_y:
			continue
		var curr_color = _get_color_at(next_point.x, next_point.y)
		if curr_color == check_color and not next_point in fill_points:
			_draw_at(next_point.x, next_point.y, _color)
			fill_points.push_back(next_point)
			# _update_canvas()
			points.push_back(next_point + Vector2(1, 0))
			points.push_back(next_point + Vector2(-1, 0))
			points.push_back(next_point + Vector2(0, 1))
			points.push_back(next_point + Vector2(0, -1))

func _is_pixel_transparent(pos : Vector2):
	return data[(pos.y * data_size_x + pos.x) * 4 + 3] == 0

func _draw_at(x: int, y: int, color: Color) -> void:
	if x < 0 or x >= data_size_x or y < 0 or y >= data_size_y:
		return
	data[(y * data_size_x + x) * 4 + 0] = color.r8
	data[(y * data_size_x + x) * 4 + 1] = color.g8
	data[(y * data_size_x + x) * 4 + 2] = color.b8
	data[(y * data_size_x + x) * 4 + 3] = color.a8

func _get_color_at(x, y):
	if x < 0 or x >= data_size_x or y < 0 or y >= data_size_y:
		return Color(0.5, 0.5, 0.5, 0.5)
	var r = data[(y * data_size_x + x) * 4 + 0]
	var g = data[(y * data_size_x + x) * 4 + 1]
	var b = data[(y * data_size_x + x) * 4 + 2]
	var a = data[(y * data_size_x + x) * 4 + 3]
	return Color(r, g, b, a)

func _draw_at_sz(x: int, y: int, color: Color, sz: int) -> void:
	if (x >= 0 and x < data_size_x) and (y >= 0 and y <= data_size_y) and $SendToServer.disabled:
		$SendToServer.disabled = false
		$SendToServer.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	for i in range(sz):
		for j in range(sz):
			if i == 0 and j == 0 or (i == sz-1 and j == sz-1):
				continue
			if (i == 0 and j == sz-1) or (i == sz-1 and j == 0):
				continue
			_draw_at(x + i - int(sz / 2.0), y + j - int(sz / 2.0), color)
			

func get_image() -> Image:
	var image := Image.new()
	image.set_data(data_size_x, data_size_y, false, Image.FORMAT_RGBA8, data)
	return image

func _update_canvas() -> void:
	var image := get_image()
	var image_tex := ImageTexture.create_from_image(image)
	canvas.texture = image_tex
	has_updated_canvas = true
	drawn_since_reset = true

func _get_canvas_mouse_x():
	var mouse_pos := canvas.get_local_mouse_position() / canvas.size
	return int(mouse_pos.x * canvas.size.x / scale_x)

func _get_canvas_mouse_y():
	var mouse_pos := canvas.get_local_mouse_position() / canvas.size
	return int(mouse_pos.y * canvas.size.y / scale_y)

func _on_palette_color_selected(color: Color) -> void:
	_color.r = color.r
	_color.g = color.g
	_color.b = color.b

func _on_pencil_tool_tool_selected(tool_id):
	current_tool = tool_id
	_color.a = 1.0

func _on_eraser_tool_tool_selected(tool_id):
	current_tool = tool_id
	_color.a = 0.0

func _on_bucket_tool_tool_selected(tool_id):
	_color.a = 1.0
	current_tool = tool_id

func _on_bomb_tool_tool_selected(_tool_id):
	image_stack.clear()
	data = []
	for i in range(data_size_x * data_size_y):
		data.append(0)
		data.append(0)
		data.append(0)
		data.append(0)
	$AnimationPlayer.play("shake")
	var image := Image.new()
	image.set_data(data_size_x, data_size_y, false, Image.FORMAT_RGBA8, data)
	canvas.texture = ImageTexture.create_from_image(image)
	$SendToServer.disabled = true
	$SendToServer.mouse_default_cursor_shape = CURSOR_ARROW

func _on_undo_tool_tool_selected(_tool_id):
	if !image_stack.is_empty():
		var last_image : Image = image_stack.pop_back()
		if drawn_since_reset:
			drawn_since_reset = false
			if image_stack.is_empty():
				_reset_canvas()
				return
			else:
				last_image = image_stack.pop_back()
		data = Array(last_image.get_data())
		canvas.texture = ImageTexture.create_from_image(last_image)
	else:
		_reset_canvas()
