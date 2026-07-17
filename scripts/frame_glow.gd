@tool
extends TextureRect
class_name FrameGlowFX

const FRAME_GLOW_SHADER: Shader = preload("res://ui/shaders/frame_glow_fx.gdshader")

@export var start_enabled: bool = true:
	set(value):
		start_enabled = value
		_set_shader_bool(&"fx_enabled", value)

@export_range(0.0, 5.0, 0.1) var glow_strength: float = 1.2:
	set(value):
		glow_strength = value
		_set_shader_float(&"glow_strength", value)

@export_range(0.0, 1.0, 0.01) var alpha_cutoff: float = 0.08:
	set(value):
		alpha_cutoff = value
		_set_shader_float(&"alpha_cutoff", value)

@export_range(0.0, 1.0, 0.01) var pulse_strength: float = 0.25:
	set(value):
		pulse_strength = value
		_set_shader_float(&"pulse_strength", value)

@export_range(0.1, 8.0, 0.1) var pulse_speed: float = 2.0:
	set(value):
		pulse_speed = value
		_set_shader_float(&"pulse_speed", value)

@export var glow_color: Color = Color(0.0, 1.0, 0.75, 1.0):
	set(value):
		glow_color = value
		_set_shader_color(&"glow_color", value)

var _material: ShaderMaterial = null


func _enter_tree() -> void:
	_setup()


func _ready() -> void:
	_setup()


func set_fx_enabled(value: bool) -> void:
	start_enabled = value


func pulse_link() -> void:
	glow_strength = 2.2
	var tween := create_tween()
	tween.tween_property(self, "glow_strength", 1.2, 0.35)


func pulse_warning() -> void:
	glow_color = Color(1.0, 0.65, 0.1, 1.0)
	glow_strength = 2.5

	var tween := create_tween()
	tween.tween_property(self, "glow_strength", 1.2, 0.45)
	tween.tween_callback(func() -> void:
		glow_color = Color(0.0, 1.0, 0.75, 1.0)
	)


func pulse_error() -> void:
	glow_color = Color(1.0, 0.05, 0.03, 1.0)
	glow_strength = 3.0

	var tween := create_tween()
	tween.tween_property(self, "glow_strength", 1.2, 0.30)
	tween.tween_callback(func() -> void:
		glow_color = Color(0.0, 1.0, 0.75, 1.0)
	)


func shutdown() -> void:
	set_fx_enabled(false)


func activate_delayed(delay_seconds: float, _active_after_enable: bool = true) -> void:
	if Engine.is_editor_hint():
		return

	if delay_seconds > 0.0:
		await get_tree().create_timer(delay_seconds).timeout

	set_fx_enabled(true)
	pulse_link()


func set_offline(value: bool) -> void:
	if value:
		glow_color = Color(0.1, 0.35, 0.35, 1.0)
		glow_strength = 0.45
	else:
		glow_color = Color(0.0, 1.0, 0.75, 1.0)
		glow_strength = 1.2


func _setup() -> void:
	visible = true
	z_index = 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	modulate = Color.WHITE
	self_modulate = Color.WHITE

	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	stretch_mode = TextureRect.STRETCH_SCALE

	_ensure_material()
	_push_uniforms()


func _ensure_material() -> void:
	if _material != null:
		material = _material
		return

	_material = ShaderMaterial.new()
	_material.shader = FRAME_GLOW_SHADER
	material = _material


func _push_uniforms() -> void:
	_set_shader_bool(&"fx_enabled", start_enabled)
	_set_shader_float(&"glow_strength", glow_strength)
	_set_shader_float(&"alpha_cutoff", alpha_cutoff)
	_set_shader_float(&"pulse_strength", pulse_strength)
	_set_shader_float(&"pulse_speed", pulse_speed)
	_set_shader_color(&"glow_color", glow_color)


func _set_shader_bool(parameter: StringName, value: bool) -> void:
	if _material == null:
		return

	_material.set_shader_parameter(parameter, value)


func _set_shader_float(parameter: StringName, value: float) -> void:
	if _material == null:
		return

	_material.set_shader_parameter(parameter, value)


func _set_shader_color(parameter: StringName, value: Color) -> void:
	if _material == null:
		return

	_material.set_shader_parameter(parameter, value)
