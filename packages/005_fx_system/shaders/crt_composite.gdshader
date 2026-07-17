shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.035;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_density : hint_range(100.0, 2000.0) = 900.0;
uniform float time_scale : hint_range(0.0, 10.0) = 1.0;

float random_value(vec2 coordinate) {
	return fract(
		sin(dot(coordinate, vec2(12.9898, 78.233))) * 43758.5453
	);
}

void fragment() {
	vec2 uv = UV;

	float scanline = sin(
		(uv.y * scanline_density) + (TIME * time_scale)
	);
	scanline = 0.5 + (0.5 * scanline);

	float noise = random_value(
		uv + vec2(TIME * 0.001, TIME * 0.002)
	);

	vec2 centered = uv - vec2(0.5);
	float vignette = smoothstep(
		0.25,
		0.75,
		length(centered)
	);

	float alpha =
		(scanline * scanline_intensity)
		+ (noise * noise_intensity)
		+ (vignette * vignette_intensity);

	COLOR = vec4(0.03, 0.18, 0.24, clamp(alpha, 0.0, 0.85));
}