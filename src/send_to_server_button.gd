extends Button

@onready var http_request: HTTPRequest = $HTTPRequest


func _on_pressed() -> void:
	var image: Image = get_parent().get_image()
	var png_bytes: PackedByteArray = image.save_png_to_buffer()
	http_request.request_raw("http://localhost:8000/images", ["Content-Type: image/png"], HTTPClient.METHOD_POST, png_bytes)
