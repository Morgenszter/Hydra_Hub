shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture
	: hint_screen_texture, repeat_disable, filter_linear;


group_uniforms Color;

uniform vec4 phosphor_color
	: source_color = vec4(0.22, 1.0, 0.72, 1.0);

uniform float tint_strength
	: hint_range(0.0, 1.0, 0.001) = 0.08;

uniform float brightness
	: hint_range(0.5, 1.5, 0.001) = 1.0;

uniform float contrast
	: hint_range(0.5, 2.0, 0.001) = 1.04;


group_uniforms CRT;

uniform float scanline_count
	: hint_range(50.0, 1000.0, 1.0) = 420.0;

uniform float scanline_strength
	: hint_range(0.0, 0.30, 0.001) = 0.055;

uniform float scanline_speed
	: hint_range(-5.0, 5.0, 0.001) = 0.14;

uniform float flicker_strength
	: hint_range(0.0, 0.20, 0.001) = 0.014;

uniform float flicker_rate
	: hint_range(1.0, 120.0, 1.0) = 32.0;

uniform float noise_strength
	: hint_range(0.0, 0.20, 0.001) = 0.010;

uniform float noise_rate
	: hint_range(1.0, 120.0, 1.0) = 26.0;

uniform float noise_resolution
	: hint_range(50.0, 1500.0, 1.0) = 520.0;

uniform float vignette_strength
	: hint_range(0.0, 1.0, 0.001) = 0.12;


group_uniforms Sweep;

uniform float sweep_speed
	: hint_range(0.0, 2.0, 0.001) = 0.10;

uniform float sweep_width
	: hint_range(0.001, 0.30, 0.001) = 0.035;

uniform float sweep_strength
	: hint_range(0.0, 0.50, 0.001) = 0.075;


group_uniforms Glitch;

uniform float glitch_amount
	: hint_range(0.0, 0.10, 0.0001) = 0.0;

uniform float glitch_band_y
	: hint_range(0.0, 1.0, 0.001) = 0.5;

uniform float glitch_band_height
	: hint_range(0.001, 0.50, 0.001) = 0.06;

uniform float glitch_softness
	: hint_range(0.001, 0.10, 0.001) = 0.012;

uniform float glitch_frequency
	: hint_range(1.0, 120.0, 1.0) = 55.0;

uniform float chromatic_amount
	: hint_range(0.0, 0.05, 0.0001) = 0.0;

group_uniforms;


const float TAU_VALUE = 6.28318530718;


float hash_21(vec2 coordinates) {
	return fract(
		sin(
			dot(
				coordinates,
				vec2(12.9898, 78.233)
			)
		) * 43758.5453123
	);
}


void fragment() {
	vec2 sampled_uv = SCREEN_UV;

	float glitch_time = floor(TIME * glitch_frequency);

	float band_distance = abs(
		UV.y - glitch_band_y
	);

	float band_mask = 1.0 - smoothstep(
		glitch_band_height,
		glitch_band_height + glitch_softness,
		band_distance
	);

	float direction_random = hash_21(
		vec2(
			glitch_time,
			glitch_band_y * 1000.0
		)
	);

	float glitch_direction = (
		direction_random > 0.5
		? 1.0
		: -1.0
	);

	float row_noise = hash_21(
		vec2(
			floor(UV.y * 160.0),
			glitch_time
		)
	) * 2.0 - 1.0;

	float horizontal_shift = (
		glitch_direction
		+ row_noise * 0.35
	) * glitch_amount * band_mask;

	sampled_uv.x += horizontal_shift;

	sampled_uv = clamp(
		sampled_uv,
		vec2(0.0),
		vec2(1.0)
	);

	float chromatic_shift = (
		chromatic_amount
		* band_mask
	);

	vec2 red_uv = clamp(
		sampled_uv
		+ vec2(chromatic_shift, 0.0),
		vec2(0.0),
		vec2(1.0)
	);

	vec2 blue_uv = clamp(
		sampled_uv
		- vec2(chromatic_shift, 0.0),
		vec2(0.0),
		vec2(1.0)
	);

	vec4 screen_color = texture(
		screen_texture,
		sampled_uv
	);

	screen_color.r = texture(
		screen_texture,
		red_uv
	).r;

	screen_color.b = texture(
		screen_texture,
		blue_uv
	).b;

	float scanline_wave = 0.5 + 0.5 * sin(
		(
			UV.y * scanline_count
			+ TIME * scanline_speed
		) * TAU_VALUE
	);

	float scanline_multiplier = 1.0 - (
		(1.0 - scanline_wave)
		* scanline_strength
	);

	float flicker_random = hash_21(
		vec2(
			floor(TIME * flicker_rate),
			19.731
		)
	);

	float flicker = (
		flicker_random * 2.0 - 1.0
	) * flicker_strength;

	vec2 noise_grid = floor(
		UV * vec2(
			noise_resolution,
			noise_resolution * 0.5625
		)
	);

	float noise_value = hash_21(
		noise_grid
		+ vec2(
			floor(TIME * noise_rate),
			37.0
		)
	);

	float pixel_noise = (
		noise_value * 2.0 - 1.0
	) * noise_strength;

	float sweep_position = fract(
		TIME * sweep_speed
	);

	float sweep_distance = abs(
		UV.y - sweep_position
	);

	sweep_distance = min(
		sweep_distance,
		1.0 - sweep_distance
	);

	float sweep_mask = 1.0 - smoothstep(
		0.0,
		sweep_width,
		sweep_distance
	);

	vec2 centered_uv = UV * 2.0 - 1.0;

	float edge_distance = clamp(
		dot(centered_uv, centered_uv) * 0.5,
		0.0,
		1.0
	);

	float vignette = 1.0 - (
		smoothstep(
			0.20,
			1.0,
			edge_distance
		) * vignette_strength
	);

	screen_color.rgb = (
		screen_color.rgb - vec3(0.5)
	) * contrast + vec3(0.5);

	screen_color.rgb *= brightness;
	screen_color.rgb *= scanline_multiplier;
	screen_color.rgb *= vignette;
	screen_color.rgb += flicker;

	screen_color.rgb += (
		phosphor_color.rgb
		* sweep_mask
		* sweep_strength
	);

	screen_color.rgb += (
		phosphor_color.rgb
		* pixel_noise
	);

	screen_color.rgb = mix(
		screen_color.rgb,
		screen_color.rgb * phosphor_color.rgb,
		tint_strength
	);

	screen_color.rgb = clamp(
		screen_color.rgb,
		vec3(0.0),
		vec3(1.0)
	);

	COLOR = vec4(
		screen_color.rgb,
		1.0
	);
}