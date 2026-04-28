extends Button

@onready var http_request: HTTPRequest = $HTTPRequest

func _on_pressed() -> void:
	var image: Image = get_parent().get_image()
	var png_bytes: PackedByteArray = image.save_png_to_buffer()
	http_request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
		print("result: ", result)
		print("response_code: ", response_code)
	)
	# var req = http_request.request_raw("http://67.205.182.218/images", ["Content-Type: image/png"], HTTPClient.METHOD_POST, png_bytes)
	var req = http_request.request_raw(FoodManager.ServerAddr, ["Content-Type: image/png"], HTTPClient.METHOD_POST, png_bytes)
