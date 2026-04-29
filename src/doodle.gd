extends Control

var _color: Color = Color(0, 0, 0)
@onready var canvas: TextureRect = $Canvas

var data_size_x: int = 64
var data_size_y: int = 64
var data: Array[int]

@onready var scale_x: float = canvas.size.x / data_size_x
@onready var scale_y: float = canvas.size.x / data_size_x

@export var starting_button : PaletteButton = null

var brush_size: int = 4
var last_pressed_pos = Vector2(0, 0)
var last_pressed = false
var current_tool = ""

func _ready() -> void:
	for i in range(data_size_x * data_size_y):
		data.append(0)
		data.append(0)
		data.append(0)
		data.append(0)
	_update_canvas()
	for pb : PaletteButton in $JonPalette.get_children():
		pb.color_picked.connect(_on_palette_color_selected)
	starting_button.button_pressed = true
	_color = starting_button.color
	$PencilTool.button_pressed = true

func _process(_delta: float) -> void:
	var x = _get_canvas_mouse_x()
	var y = _get_canvas_mouse_y()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_draw_at_sz(x, y, _color, brush_size)
		_update_canvas()
		if last_pressed:
			var curr_pos = Vector2(x, y)
			if curr_pos.distance_to(last_pressed_pos) > (brush_size / 4):
				_draw_line(curr_pos, last_pressed_pos)
		last_pressed_pos = Vector2(x, y)
		last_pressed = true
	else:
		last_pressed = false

func _draw_line(start_pos : Vector2, end_pos : Vector2):
	var direction = start_pos.direction_to(end_pos)
	var add_buffer = direction * (brush_size / 4)
	var curr_pos = start_pos + add_buffer
	var sz = brush_size
	while curr_pos.distance_to(end_pos) > (brush_size / 4):
		for i in range(sz):
			for j in range(sz):
				if i == 0 and j == 0 or (i == sz-1 and j == sz-1):
					continue
				if (i == 0 and j == sz-1) or (i == sz-1 and j == 0):
					continue
				_draw_at(curr_pos.x + i - sz / 2, curr_pos.y + j - sz / 2, _color)
		curr_pos += add_buffer

func _draw_at(x: int, y: int, color: Color) -> void:
	if x < 0 or x >= data_size_x or y < 0 or y >= data_size_y:
		return
	data[(y * data_size_x + x) * 4 + 0] = color.r8
	data[(y * data_size_x + x) * 4 + 1] = color.g8
	data[(y * data_size_x + x) * 4 + 2] = color.b8
	data[(y * data_size_x + x) * 4 + 3] = color.a8

func _draw_at_sz(x: int, y: int, color: Color, sz: int) -> void:
	for i in range(sz):
		for j in range(sz):
			if i == 0 and j == 0 or (i == sz-1 and j == sz-1):
				continue
			if (i == 0 and j == sz-1) or (i == sz-1 and j == 0):
				continue
			_draw_at(x + i - sz / 2, y + j - sz / 2, color)

func get_image() -> Image:
	var image := Image.new()
	image.set_data(data_size_x, data_size_y, false, Image.FORMAT_RGBA8, data)
	return image

func _update_canvas() -> void:
	var image := get_image()
	var image_tex := ImageTexture.create_from_image(image)
	canvas.texture = image_tex

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
