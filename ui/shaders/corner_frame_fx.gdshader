shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform bool debug_force_visible = false;

uniform bool fx_enabled = false;
uniform bool panel_active = false;
uniform bool offline = false;

uniform int screen_shape = 1;

uniform float screen_padding : hint_range(0.0, 0.35) = 0.12;
uniform float octagon_cut : hint_range(0.05, 0.45) = 0.245;
uniform float edge_softness : hint_range(0.001, 0.08) = 0.018;
uniform float edge_glow_width : hint_range(0.0, 0.20) = 0.055;

uniform float screen_opacity : hint_range(0.0, 1.0) = 0.42;
uniform float glow_strength : hint_range(0.0, 3.0) = 0.70;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.16;
uniform float sweep_strength : hint_range(0.0, 2.0) = 0.35;
uniform float noise_strength : hint_range(0.0, 0.35) = 0.055;

uniform float boot_pulse = 0.0;
uniform float submit_pulse = 0.0;
uniform float warning_pulse = 0.0;
uniform float error_pulse = 0.0;

uniform float time_offset = 0.0;
uniform float noise_seed = 0.0;

uniform vec4 base_color : source_color = vec4(0.02, 0.95, 0.62, 1.0);
uniform vec4 cyan_color : source_color = vec4(0.05, 0.85, 1.0, 1.0);
uniform vec4 warning_color : source_color = vec4(1.0, 0.68, 0.12, 1.0);
uniform vec4 error_color : source_color = vec4(1.0, 0.08, 0.04, 1.0);
uniform vec4 offline_color : source_color = vec4(0.06, 0.24, 0.26, 1.0);

float hash12(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 74.7);
	return fract(p.x * p.y);
}

float band(float value, float center, float width) {
	float d = abs(value - center);
	return 1.0 - smoothstep(0.0, width, d);
}

vec2 padded_uv(vec2 uv, float padding) {
	float scale_value = max(0.001, 1.0 - padding * 2.0);
	return (uv - vec2(padding)) / scale_value;
}

float rect_screen_mask(vec2 uv, float padding, float softness) {
	float left = smoothstep(padding, padding + softness, uv.x);
	float right = smoothstep(padding, padding + softness, 1.0 - uv.x);
	float top = smoothstep(padding, padding + softness, uv.y);
	float bottom = smoothstep(padding, padding + softness, 1.0 - uv.y);

	return left * right * top * bottom;
}

float rect_edge_distance(vec2 uv, float padding) {
	vec2 puv = padded_uv(uv, padding);
	return min(min(puv.x, 1.0 - puv.x), min(puv.y, 1.0 - puv.y));
}

float octagon_signed_distance(vec2 uv, float cut_value) {
	float d_left = uv.x;
	float d_right = 1.0 - uv.x;
	float d_top = uv.y;
	float d_bottom = 1.0 - uv.y;

	float inv_sqrt_two = 0.70710678118;

	float d_left_top = (uv.x + uv.y - cut_value) * inv_sqrt_two;
	float d_right_top = ((1.0 - uv.x) + uv.y - cut_value) * inv_sqrt_two;
	float d_left_bottom = (uv.x + (1.0 - uv.y) - cut_value) * inv_sqrt_two;
	float d_right_bottom = ((1.0 - uv.x) + (1.0 - uv.y) - cut_value) * inv_sqrt_two;

	float d_axis = min(min(d_left, d_right), min(d_top, d_bottom));
	float d_diagonal = min(min(d_left_top, d_right_top), min(d_left_bottom, d_right_bottom));

	return min(d_axis, d_diagonal);
}

float octagon_screen_mask(vec2 uv, float padding, float cut_value, float softness) {
	vec2 puv = padded_uv(uv, padding);
	float rect = rect_screen_mask(uv, padding, softness);
	float d = octagon_signed_distance(puv, cut_value);
	float oct = smoothstep(-softness, softness, d);

	return rect * oct;
}

float octagon_edge_distance(vec2 uv, float padding, float cut_value) {
	vec2 puv = padded_uv(uv, padding);
	return octagon_signed_distance(puv, cut_value);
}

void fragment() {
	bool enabled = fx_enabled || debug_force_visible;

	if (!enabled) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv = UV;
		float t = TIME + time_offset;

		float mask = 0.0;
		float edge_distance = 0.0;

		if (screen_shape == 1) {
			mask = octagon_screen_mask(uv, screen_padding, octagon_cut, edge_softness);
			edge_distance = octagon_edge_distance(uv, screen_padding, octagon_cut);
		} else {
			mask = rect_screen_mask(uv, screen_padding, edge_softness);
			edge_distance = rect_edge_distance(uv, screen_padding);
		}

		float active_state = panel_active || debug_force_visible ? 1.0 : 0.0;
		float offline_state = offline ? 1.0 : 0.0;

		float boot = clamp(boot_pulse, 0.0, 1.0);
		float submit = clamp(submit_pulse, 0.0, 1.0);
		float warn = clamp(warning_pulse, 0.0, 1.0);
		float err = clamp(error_pulse, 0.0, 1.0);

		float screen_fill = mask;

		float edge = 1.0 - smoothstep(edge_glow_width, edge_glow_width + edge_softness, edge_distance);
		edge *= mask;

		float scan = 0.5 + 0.5 * sin((uv.y * 96.0 + t * 2.7) * 6.28318530718);
		scan = pow(scan, 8.0) * scanline_strength * mask;

		float sweep_center = fract(t * 0.28 + 0.15);
		float sweep = band(uv.x, sweep_center, 0.12) * sweep_strength * mask;

		float pulse = 0.65 + 0.35 * sin(t * 2.5);
		float active_glow = active_state * pulse * glow_strength * mask;

		float boot_flash = boot * mask * (0.55 + 0.45 * sin(t * 28.0));
		float submit_flash = submit * mask * (0.55 + 0.45 * sin(t * 22.0));
		float warn_flash = warn * mask * (0.50 + 0.50 * sin(t * 18.0));

		float glitch_row = floor(uv.y * 18.0);
		float glitch_tick = floor(t * 42.0 + noise_seed);
		float glitch_noise = hash12(vec2(glitch_row, glitch_tick));
		float glitch_gate = step(0.72, glitch_noise);
		float glitch_bar = glitch_gate * err * band(uv.x, hash12(vec2(glitch_tick, glitch_row)), 0.14) * mask;

		float micro_noise = hash12(floor(vec2(uv.x * 220.0, uv.y * 140.0 + t * 15.0)) + noise_seed);
		float noise = (micro_noise - 0.5) * noise_strength * mask;

		vec3 normal_color = mix(base_color.rgb, cyan_color.rgb, clamp(sweep + active_glow + submit_flash + boot_flash, 0.0, 1.0));
		vec3 warning_mix = mix(normal_color, warning_color.rgb, clamp(warn_flash + warn * 0.25, 0.0, 1.0));
		vec3 error_mix = mix(warning_mix, error_color.rgb, clamp(glitch_bar + err * 0.35, 0.0, 1.0));
		vec3 final_color = mix(error_mix, offline_color.rgb, offline_state);

		float offline_multiplier = mix(1.0, 0.35, offline_state);

		float alpha = 0.0;
		alpha += screen_fill * screen_opacity;
		alpha += edge * 0.22;
		alpha += scan;
		alpha += sweep * 0.24;
		alpha += active_glow * 0.18;
		alpha += boot_flash * 0.35;
		alpha += submit_flash * 0.28;
		alpha += warn_flash * 0.30;
		alpha += glitch_bar * 0.45;
		alpha += noise;

		if (debug_force_visible) {
			alpha += mask * 0.18;
		}

		alpha = clamp(alpha * offline_multiplier, 0.0, 0.72);

		COLOR = vec4(final_color, alpha);
	}
}