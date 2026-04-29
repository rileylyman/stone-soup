extends CheckButton

signal tool_selected(tool_id)

@export var tool_name = ""

func unpress(ref):
	if ref != self:
		button_pressed = false

func _on_pressed():
	get_tree().call_group("Tools", "unpress", self)
	tool_selected.emit(tool_name)

func _on_toggled(toggled_on):
	var is_any_other_toggled = false
	for tool : CheckButton in get_tree().get_nodes_in_group("Tools"):
		if tool.button_pressed:
			is_any_other_toggled = true
	if !is_any_other_toggled and not toggled_on:
		button_pressed = true
