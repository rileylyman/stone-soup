extends TextureButton

@export var send_bar: SendBar = null

@onready var http_request: HTTPRequest = $HTTPRequest

signal sent(success: bool)

func _on_pressed() -> void:
	var image: Image = get_parent().get_image()
	var png_bytes: PackedByteArray = image.save_png_to_buffer()
	http_request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 201:
			sent.emit(true)
		else:
			print("Error when sending image: ", result, " ", response_code)
			sent.emit(false)
	)

	http_request.request_raw(FoodManager.ServerAddr, ["Content-Type: image/png"], HTTPClient.METHOD_POST, png_bytes)
	send_bar.fill()
	var success = await sent
	if not send_bar.fill_complete:
		await send_bar.fill_complete_signal
	if success:
		await send_bar.success()
		get_parent()._reset_canvas()
		get_parent().image_stack.clear()
	else:
		await send_bar.fail()
