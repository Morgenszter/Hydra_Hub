shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.42;
uniform float softness : hint_range(0.01, 1.0) = 0.45;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv);
	float vignette = smoothstep(
		softness,
		1.0,
		distance_from_center * 1.7
	);

	COLOR = vec4(
		0.0,
		0.01,
		0.02,
		vignette * strength
	);
}