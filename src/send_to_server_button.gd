extends Button

@onready var http_request: HTTPRequest = $HTTPRequest


func _on_pressed() -> void:
	var image: Image = get_parent().get_image()
	var data = JSON.stringify(image.data)

	http_request.request("http://localhost:8000/images", ["Content-Type: application/json"], HTTPClient.METHOD_POST, data)
