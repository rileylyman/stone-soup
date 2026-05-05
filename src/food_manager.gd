class_name FoodManager
extends Node2D

const Food = preload("res://src/food.tscn")
const ServerAddr = "http://167.172.15.13/images"
# const ServerAddr = "http://127.0.0.1:8000/images"

@export var poll_interval := 2.0

class FoodHandle:
	var id: String
	var food: Area2D
	var time_remaining_s: float

var foods: Array[FoodHandle]
var last_window_size = Vector2i(480, 400)

func _ready() -> void:
	_periodic_poll()

func _periodic_poll() -> void:
	while true:
		await _list_request()
		for i in range(foods.size() - 1, -1, -1):
			if foods[i].time_remaining_s <= 0.0:
				foods[i].food.queue_free()
				foods.remove_at(i)
		await get_tree().create_timer(poll_interval).timeout

func _list_request() -> void:
	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
			print("Error when listing: ", result, " ", response_code)
			return

		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var response = json.get_data()
		for food_info in response:
			await _update_food(food_info["id"], food_info["time_remaining_s"])
	)

	req.request(ServerAddr, [], HTTPClient.METHOD_GET)
	await req.request_completed
	req.queue_free()

func _update_food(id: String, time_remaining_s: float) -> void:
	var idx := foods.find_custom(func(f): return f.id == id)
	if idx >= 0:
		foods[idx].time_remaining_s = time_remaining_s
		return
	
	var new_handle = FoodHandle.new()
	new_handle.id = id
	new_handle.time_remaining_s = time_remaining_s

	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
			print("Error when getting image: ", id, " ", result, " ", response_code)
			return
		var png = Image.new()
		png.load_png_from_buffer(body)
		var food = add_food(png)
		new_handle.food = food
	)

	req.request(ServerAddr + "/" + id, [], HTTPClient.METHOD_GET)
	await req.request_completed
	req.queue_free()

	if new_handle.food != null:
		foods.append(new_handle)

func _process(delta: float):
	if Input.is_action_just_pressed("add_item"):
		add_food(null)
	for food in foods:
		food.time_remaining_s -= delta

func add_food(image: Image) -> Area2D:
	var next_food : Area2D = Food.instantiate()
	if image != null:
		next_food.get_node("Sprite2D").texture = ImageTexture.create_from_image(image)
	next_food.position = get_viewport_rect().size / 2
	$Food.add_child(next_food)
	return next_food

func _on_window_check_timer_timeout():
	if last_window_size != DisplayServer.window_get_size():
		last_window_size = DisplayServer.window_get_size()
		for food in $Food.get_children():
			food.position = get_viewport_rect().size / 2
		print("Resetting positions..")
