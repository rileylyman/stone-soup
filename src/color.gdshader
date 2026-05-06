shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.0);

void vertex() {
}

void fragment() {
	vec4 current = texture(TEXTURE, UV);
	COLOR = mix(current, color, float(int(current.a != 0.0)));
}