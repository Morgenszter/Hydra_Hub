shader_type canvas_item;

uniform float opacity : hint_range(0.0, 1.0) = 0.14;
uniform float density : hint_range(100.0, 2000.0) = 1080.0;
uniform float speed : hint_range(-10.0, 10.0) = 0.35;

void fragment() {
	float scanline = sin(
		(UV.y * density) + (TIME * speed)
	);

	float line_strength = smoothstep(
		0.15,
		1.0,
		scanline
	);

	COLOR = vec4(
		0.05,
		0.40,
		0.58,
		line_strength * opacity
	);
}