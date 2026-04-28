class_name FoodManager
extends Node2D

const Food = preload("res://src/food.tscn")
const ServerAddr = "http://167.172.15.13/images"

@export var poll_interval := 2.0

class FoodHandle:
	var id: String
	var food: PathFollow2D
	var seen: bool

var foods: Array[FoodHandle]

func _ready() -> void:
	_periodic_poll()

func _periodic_poll() -> void:
	while true:
		for food in foods:
			food.seen = false
		await _list_request()
		for i in range(foods.size() - 1, -1, -1):
			if not foods[i].seen:
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
			_update_food(food_info["id"])
	)

	req.request(ServerAddr, [], HTTPClient.METHOD_GET)
	await req.request_completed

func _update_food(id: String) -> void:
	var idx := foods.find_custom(func(f): return f.id == id)
	if idx >= 0:
		foods[idx].seen = true
		return
	
	var new_handle = FoodHandle.new()
	new_handle.id = id
	new_handle.seen = true

	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
			print("Error when getting image: ", result, " ", response_code)
			return
		var png = Image.new()
		png.load_png_from_buffer(body)
		var food = add_food(png)
		new_handle.food = food
	)

	req.request(ServerAddr + "/" + id, [], HTTPClient.METHOD_GET)
	await req.request_completed

	if new_handle.food != null:
		foods.append(new_handle)

func _process(_delta: float):
	if Input.is_action_just_pressed("add_item"):
		add_food(null)

func add_food(image: Image) -> PathFollow2D:
	var next_food : PathFollow2D = Food.instantiate()
	if image != null:
		next_food.get_node("Sprite2D").texture = ImageTexture.create_from_image(image)
	$Paths.get_child(randi() % $Paths.get_child_count()).add_child(next_food)
	next_food.progress_ratio = randf()
	return next_food
