class_name PaletteOption
extends Control

const SELECTED_BORDER_WIDTH: int = 2

signal selected(option: PaletteOption)

@onready var margin_container: MarginContainer = $MarginContainer
@onready var color_rect: ColorRect = $MarginContainer/Color
@onready var pcolor: Color = color_rect.color

func set_palette_color(_color: Color) -> void:
	color_rect.color = _color
	pcolor = _color

func select() -> void:
	margin_container.add_theme_constant_override("margin_left", SELECTED_BORDER_WIDTH)
	margin_container.add_theme_constant_override("margin_right", SELECTED_BORDER_WIDTH)
	margin_container.add_theme_constant_override("margin_top", SELECTED_BORDER_WIDTH)
	margin_container.add_theme_constant_override("margin_bottom", SELECTED_BORDER_WIDTH)

func deselect() -> void:
	margin_container.add_theme_constant_override("margin_left", 0)
	margin_container.add_theme_constant_override("margin_right", 0)
	margin_container.add_theme_constant_override("margin_top", 0)
	margin_container.add_theme_constant_override("margin_bottom", 0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected.emit(self)
