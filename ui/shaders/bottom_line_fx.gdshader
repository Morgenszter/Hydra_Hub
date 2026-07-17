shader_type canvas_item;
render_mode unshaded, blend_add;


group_uniforms Colors;

uniform vec4 base_color
	: source_color = vec4(0.12, 0.80, 0.62, 1.0);

uniform vec4 accent_color
	: source_color = vec4(0.45, 1.00, 0.82, 1.0);

uniform vec4 warning_color
	: source_color = vec4(1.00, 0.68, 0.20, 1.0);

uniform vec4 error_color
	: source_color = vec4(1.00, 0.18, 0.25, 1.0);


group_uniforms Line;

uniform float opacity
	: hint_range(0.0, 1.0, 0.001) = 0.38;

uniform float line_width
	: hint_range(0.001, 0.50, 0.001) = 0.055;

uniform float edge_glow_width
	: hint_range(0.001, 0.50, 0.001) = 0.18;

uniform float horizontal_fade
	: hint_range(0.0, 0.50, 0.001) = 0.08;


group_uniforms Animation;

uniform float sweep_speed
	: hint_range(0.0, 5.0, 0.001) = 0.42;

uniform float sweep_width
	: hint_range(0.001, 0.50, 0.001) = 0.11;

uniform float sweep_strength
	: hint_range(0.0, 3.0, 0.001) = 1.15;

uniform float pulse_speed
	: hint_range(0.0, 10.0, 0.001) = 1.8;

uniform float pulse_strength
	: hint_range(0.0, 1.0, 0.001) = 0.16;

uniform float noise_strength
	: hint_range(0.0, 1.0, 0.001) = 0.025;

uniform float noise_rate
	: hint_range(1.0, 120.0, 1.0) = 35.0;


group_uniforms Runtime;

uniform float activity
	: hint_range(0.0, 1.0, 0.001) = 0.25;

uniform float submit_pulse
	: hint_range(0.0, 1.0, 0.001) = 0.0;

uniform float alert_level
	: hint_range(0.0, 1.0, 0.001) = 0.0;

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


float wrapped_distance(float value_a, float value_b) {
	float distance_value = abs(value_a - value_b);

	return min(
		distance_value,
		1.0 - distance_value
	);
}


void fragment() {
	float warning_mix = smoothstep(
		0.10,
		0.62,
		alert_level
	);

	float error_mix = smoothstep(
		0.62,
		1.0,
		alert_level
	);

	vec3 active_color = mix(
		base_color.rgb,
		warning_color.rgb,
		warning_mix
	);

	active_color = mix(
		active_color,
		error_color.rgb,
		error_mix
	);

	active_color = mix(
		active_color,
		accent_color.rgb,
		submit_pulse * 0.72
	);

	float center_distance = abs(
		UV.y - 0.5
	);

	float core_line = 1.0 - smoothstep(
		line_width,
		line_width + 0.025,
		center_distance
	);

	float line_glow = 1.0 - smoothstep(
		line_width,
		line_width + edge_glow_width,
		center_distance
	);

	float left_fade = smoothstep(
		0.0,
		horizontal_fade,
		UV.x
	);

	float right_fade = smoothstep(
		0.0,
		horizontal_fade,
		1.0 - UV.x
	);

	float horizontal_mask = (
		left_fade * right_fade
	);

	float sweep_position = fract(
		TIME * sweep_speed
	);

	float sweep_distance = wrapped_distance(
		UV.x,
		sweep_position
	);

	float sweep = 1.0 - smoothstep(
		sweep_width,
		sweep_width + 0.045,
		sweep_distance
	);

	float ambient_pulse = (
		0.5
		+ 0.5
		* sin(
			TIME
			* pulse_speed
			* TAU_VALUE
		)
	);

	float time_step = floor(
		TIME * noise_rate
	);

	float noise = hash_21(
		vec2(
			floor(UV.x * 420.0),
			time_step
		)
	);

	noise = (
		noise * 2.0 - 1.0
	) * noise_strength;

	float input_activity = mix(
		0.42,
		1.0,
		activity
	);

	float core_intensity = (
		core_line
		* (
			0.70
			+ activity * 0.55
		)
	);

	float glow_intensity = (
		line_glow
		* (
			0.20
			+ ambient_pulse
			* pulse_strength
		)
	);

	float sweep_intensity = (
		sweep
		* line_glow
		* sweep_strength
		* input_activity
	);

	float submit_intensity = (
		submit_pulse
		* line_glow
		* 1.85
	);

	float alert_intensity = (
		alert_level
		* (
			core_line * 0.80
			+ line_glow * 0.55
		)
	);

	float final_intensity = (
		core_intensity
		+ glow_intensity
		+ sweep_intensity
		+ submit_intensity
		+ alert_intensity
		+ noise
	);

	final_intensity *= horizontal_mask;

	float final_alpha = clamp(
		final_intensity * opacity,
		0.0,
		1.0
	);

	vec3 final_color = active_color * max(
		final_intensity,
		0.0
	);

	COLOR = vec4(
		final_color,
		final_alpha
	);
}