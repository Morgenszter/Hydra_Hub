shader_type canvas_item;

uniform vec4 hologram_color : source_color = vec4(
	0.196,
	0.847,
	1.0,
	1.0
);
uniform float scan_speed : hint_range(0.0, 10.0) = 1.5;
uniform float distortion : hint_range(0.0, 0.1) = 0.008;
uniform float glow_strength : hint_range(0.0, 4.0) = 1.25;

void fragment() {
	vec2 uv = UV;
	float wave = sin((uv.y * 70.0) + (TIME * scan_speed));
	uv.x += wave * distortion;

	vec4 source = texture(TEXTURE, uv);
	float scan = 0.75 + (0.25 * wave);

	vec3 color = source.rgb * hologram_color.rgb;
	color *= scan * glow_strength;

	COLOR = vec4(color, source.a * hologram_color.a);
}