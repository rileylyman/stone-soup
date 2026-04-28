@tool
extends CheckButton
class_name PaletteButton

signal color_picked(c)

@export var color : Color = Color.BLACK :
	set(v):
		if has_node("ColorRect"):
			get_node("ColorRect").color = v
		color = v
	get():
		return color

func unpress(ref):
	print(ref.name)
	if ref != self:
		button_pressed = false

func _on_pressed():
	get_tree().call_group("PaletteButtons", "unpress", self)
	color_picked.emit(color)
