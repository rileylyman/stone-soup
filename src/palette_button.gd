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
	if ref != self:
		button_pressed = false

func _on_pressed():
	get_tree().call_group("PaletteButtons", "unpress", self)
	color_picked.emit(color)

func _on_toggled(toggled_on):
	if Engine.is_editor_hint():
		return
	var is_any_other_toggled = false
	for pb : PaletteButton in get_tree().get_nodes_in_group("PaletteButtons"):
		if pb.button_pressed:
			is_any_other_toggled = true
	if !is_any_other_toggled and not toggled_on:
		button_pressed = true
