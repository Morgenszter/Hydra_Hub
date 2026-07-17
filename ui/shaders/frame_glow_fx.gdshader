shader_type canvas_item;
render_mode blend_add, unshaded;

uniform bool fx_enabled = true;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.75, 1.0);

uniform float glow_strength : hint_range(0.0, 5.0) = 1.2;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.08;

uniform float pulse_strength : hint_range(0.0, 1.0) = 0.25;
uniform float pulse_speed : hint_range(0.1, 8.0) = 2.0;

void fragment() {
	if (!fx_enabled) {
		COLOR = vec4(0.0);
	} else {
		vec4 tex = texture(TEXTURE, UV);

		float mask = smoothstep(alpha_cutoff, 1.0, tex.a);
		float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_strength;

		float alpha = mask * glow_strength * pulse * 0.35;

		COLOR = vec4(glow_color.rgb, alpha);
	}
}