class_name Palette
extends HBoxContainer

signal color_selected(color: Color)

@onready var palette: Array[PaletteOption]

func _ready() -> void:
	var pal_lines := FileAccess.open("res://arne-16.pal", FileAccess.READ).get_as_text().split("\n")
	var color_list: Array[Color] = []
	for line in pal_lines.slice(3):
		if not line:
			continue
		var rgb := line.split(" ")
		color_list.append(Color(float(rgb[0]) / 256.0, float(rgb[1]) / 256.0, float(rgb[2]) / 256.0))

	for palette_option in get_children():
		if palette_option is PaletteOption:
			palette.append(palette_option)

	for i in range(palette.size()):
		palette[i].deselect()
		palette[i].selected.connect(_on_palette_option_selected)
		palette[i].set_palette_color(color_list[i])
	_on_palette_option_selected(palette[0])


func _on_palette_option_selected(option: PaletteOption) -> void:
	for palette_option in palette:
		palette_option.deselect()
	option.select()

	print("selected %s with color %s" % [option.name, option.pcolor])
	color_selected.emit(option.pcolor)
