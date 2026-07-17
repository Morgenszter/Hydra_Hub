@tool
extends ColorRect
class_name CornerFrameFX

enum CornerSlot {
	LEFT_BOTTOM,
	RIGHT_TOP,
	LEFT_TOP
}

enum ScreenShape {
	RECTANGLE,
	OCTAGON
}

const SCREEN_SHADER: Shader = preload("res://ui/shaders/corner_frame_fx.gdshader")

const SCREEN_Z_INDEX := 1
const FRAME_Z_INDEX := 2
const SHADER_INPUT_COLOR := Color(1.0, 1.0, 1.0, 1.0)

var _corner_slot: int = CornerSlot.LEFT_BOTTOM
var _screen_shape: int = ScreenShape.OCTAGON

var _screen_padding: float = 0.12
var _octagon_cut: float = 0.245
var _edge_softness: float = 0.018
var _edge_glow_width: float = 0.055

var _screen_opacity: float = 0.42
var _glow_strength: float = 0.70
var _scanline_strength: float = 0.16
var _sweep_strength: float = 0.35
var _noise_strength: float = 0.055

var _debug_force_visible: bool = false
var _apply_required_rect_on_ready: bool = true
var _start_enabled: bool = false
var _start_panel_active: bool = false
var _start_offline: bool = false

var _material: ShaderMaterial = null

var _fx_enabled: bool = false
var _panel_active: bool = false
var _offline: bool = false

var _activation_serial: int = 0

var _submit_tween: Tween = null
var _warning_tween: Tween = null
var _error_tween: Tween = null
var _boot_tween: Tween = null


@export_group("Screen FX")

@export var debug_force_visible: bool:
	get:
		return _debug_force_visible
	set(value):
		_debug_force_visible = value
		_push_uniforms()


@export_enum("Rectangle", "Octagon")
var screen_shape: int:
	get:
		return _screen_shape
	set(value):
		_screen_shape = clampi(value, ScreenShape.RECTANGLE, ScreenShape.OCTAGON)
		_push_uniforms()


@export_enum("Left Bottom", "Right Top", "Left Top")
var corner_slot: int:
	get:
		return _corner_slot
	set(value):
		_corner_slot = clampi(value, CornerSlot.LEFT_BOTTOM, CornerSlot.LEFT_TOP)
		_apply_slot_defaults()
		_push_uniforms()


@export_range(0.0, 0.35, 0.001)
var screen_padding: float:
	get:
		return _screen_padding
	set(value):
		_screen_padding = clampf(value, 0.0, 0.35)
		_push_uniforms()


@export_range(0.05, 0.45, 0.001)
var octagon_cut: float:
	get:
		return _octagon_cut
	set(value):
		_octagon_cut = clampf(value, 0.05, 0.45)
		_push_uniforms()


@export_range(0.001, 0.08, 0.001)
var edge_softness: float:
	get:
		return _edge_softness
	set(value):
		_edge_softness = clampf(value, 0.001, 0.08)
		_push_uniforms()


@export_range(0.0, 0.20, 0.001)
var edge_glow_width: float:
	get:
		return _edge_glow_width
	set(value):
		_edge_glow_width = clampf(value, 0.0, 0.20)
		_push_uniforms()


@export_range(0.0, 1.0, 0.01)
var screen_opacity: float:
	get:
		return _screen_opacity
	set(value):
		_screen_opacity = clampf(value, 0.0, 1.0)
		_push_uniforms()


@export_range(0.0, 3.0, 0.01)
var glow_strength: float:
	get:
		return _glow_strength
	set(value):
		_glow_strength = clampf(value, 0.0, 3.0)
		_push_uniforms()


@export_range(0.0, 1.0, 0.01)
var scanline_strength: float:
	get:
		return _scanline_strength
	set(value):
		_scanline_strength = clampf(value, 0.0, 1.0)
		_push_uniforms()


@export_range(0.0, 2.0, 0.01)
var sweep_strength: float:
	get:
		return _sweep_strength
	set(value):
		_sweep_strength = clampf(value, 0.0, 2.0)
		_push_uniforms()


@export_range(0.0, 0.35, 0.001)
var noise_strength: float:
	get:
		return _noise_strength
	set(value):
		_noise_strength = clampf(value, 0.0, 0.35)
		_push_uniforms()


@export var apply_required_rect_on_ready: bool:
	get:
		return _apply_required_rect_on_ready
	set(value):
		_apply_required_rect_on_ready = value
		_configure_node()


@export var start_enabled: bool:
	get:
		return _start_enabled
	set(value):
		_start_enabled = value
		set_fx_enabled(value)


@export var start_panel_active: bool:
	get:
		return _start_panel_active
	set(value):
		_start_panel_active = value
		set_panel_active(value)


@export var start_offline: bool:
	get:
		return _start_offline
	set(value):
		_start_offline = value
		set_offline(value)


func _enter_tree() -> void:
	_configure_node()
	_ensure_material()
	_push_uniforms()


func _ready() -> void:
	_configure_node()
	_ensure_material()

	_fx_enabled = _start_enabled
	_panel_active = _start_panel_active
	_offline = _start_offline

	_push_uniforms()


func configure_as_overlay(slot: int) -> void:
	_corner_slot = clampi(slot, CornerSlot.LEFT_BOTTOM, CornerSlot.LEFT_TOP)
	_apply_slot_defaults()
	_configure_node()
	_ensure_material()
	_push_uniforms()


func activate_delayed(delay_seconds: float, active_after_enable: bool = true) -> void:
	if Engine.is_editor_hint():
		return

	_activation_serial += 1
	var serial := _activation_serial

	if delay_seconds > 0.0:
		await get_tree().create_timer(delay_seconds).timeout

	if serial != _activation_serial:
		return

	set_fx_enabled(true)
	set_panel_active(active_after_enable)
	pulse_boot()


func shutdown() -> void:
	_activation_serial += 1
	set_panel_active(false)
	set_fx_enabled(false)
	_reset_pulses()


func set_fx_enabled(value: bool) -> void:
	_fx_enabled = value
	visible = true
	_push_uniforms()

	if not value:
		_reset_pulses()


func set_panel_active(value: bool) -> void:
	_panel_active = value
	_push_uniforms()


func set_offline(value: bool) -> void:
	_offline = value
	_push_uniforms()


func pulse_boot() -> void:
	if Engine.is_editor_hint():
		return

	if not _fx_enabled:
		return

	_kill_boot_tween()
	_set_shader_float(&"boot_pulse", 1.0)

	_boot_tween = create_tween()
	_boot_tween.tween_method(
		func(value: float) -> void:
			_set_shader_float(&"boot_pulse", value),
		1.0,
		0.0,
		0.55
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func pulse_link() -> void:
	if Engine.is_editor_hint():
		return

	if not _fx_enabled:
		return

	_kill_submit_tween()
	_set_shader_float(&"submit_pulse", 1.0)

	_submit_tween = create_tween()
	_submit_tween.tween_method(
		func(value: float) -> void:
			_set_shader_float(&"submit_pulse", value),
		1.0,
		0.0,
		0.34
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func pulse_warning() -> void:
	if Engine.is_editor_hint():
		return

	if not _fx_enabled:
		return

	_kill_warning_tween()
	_set_shader_float(&"warning_pulse", 1.0)

	_warning_tween = create_tween()
	_warning_tween.tween_method(
		func(value: float) -> void:
			_set_shader_float(&"warning_pulse", value),
		1.0,
		0.0,
		0.48
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func pulse_error() -> void:
	if Engine.is_editor_hint():
		return

	if not _fx_enabled:
		return

	_kill_error_tween()
	_set_shader_float(&"error_pulse", 1.0)
	_set_shader_float(&"noise_seed", randf() * 999.0)

	_error_tween = create_tween()
	_error_tween.tween_method(
		func(value: float) -> void:
			_set_shader_float(&"error_pulse", value),
		1.0,
		0.0,
		0.32
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func is_fx_enabled() -> bool:
	return _fx_enabled


func is_panel_active() -> bool:
	return _panel_active


func is_offline() -> bool:
	return _offline


func _apply_slot_defaults() -> void:
	if _corner_slot == CornerSlot.LEFT_BOTTOM:
		_screen_shape = ScreenShape.OCTAGON
		_screen_padding = 0.12
		_octagon_cut = 0.245
	else:
		_screen_shape = ScreenShape.RECTANGLE
		_screen_padding = 0.10
		_octagon_cut = 0.245


func _configure_node() -> void:
	visible = true
	z_index = SCREEN_Z_INDEX
	z_as_relative = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	color = SHADER_INPUT_COLOR
	modulate = Color.WHITE
	self_modulate = Color.WHITE

	if _apply_required_rect_on_ready:
		anchor_left = 0.0
		anchor_top = 0.0
		anchor_right = 1.0
		anchor_bottom = 1.0

		offset_left = 0.0
		offset_top = 0.0
		offset_right = 0.0
		offset_bottom = 0.0

	_configure_parent_frame_above()


func _configure_parent_frame_above() -> void:
	var parent_node := get_parent()

	if parent_node == null:
		return

	var frame := parent_node.get_node_or_null("Frame") as CanvasItem

	if frame == null:
		return

	frame.z_index = FRAME_Z_INDEX
	frame.z_as_relative = true

	if frame is Control:
		var frame_control := frame as Control
		frame_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame_control.focus_mode = Control.FOCUS_NONE


func _ensure_material() -> void:
	if _material != null:
		material = _material
		return

	_material = ShaderMaterial.new()
	_material.shader = SCREEN_SHADER
	material = _material


func _push_uniforms() -> void:
	_ensure_material()

	_set_shader_bool(&"debug_force_visible", _debug_force_visible)
	_set_shader_bool(&"fx_enabled", _fx_enabled)
	_set_shader_bool(&"panel_active", _panel_active)
	_set_shader_bool(&"offline", _offline)

	_set_shader_int(&"screen_shape", _screen_shape)

	_set_shader_float(&"screen_padding", _screen_padding)
	_set_shader_float(&"octagon_cut", _octagon_cut)
	_set_shader_float(&"edge_softness", _edge_softness)
	_set_shader_float(&"edge_glow_width", _edge_glow_width)

	_set_shader_float(&"screen_opacity", _screen_opacity)
	_set_shader_float(&"glow_strength", _glow_strength)
	_set_shader_float(&"scanline_strength", _scanline_strength)
	_set_shader_float(&"sweep_strength", _sweep_strength)
	_set_shader_float(&"noise_strength", _noise_strength)

	_set_shader_float(&"boot_pulse", 0.0)
	_set_shader_float(&"submit_pulse", 0.0)
	_set_shader_float(&"warning_pulse", 0.0)
	_set_shader_float(&"error_pulse", 0.0)

	_set_shader_float(&"time_offset", randf() * 32.0)
	_set_shader_float(&"noise_seed", randf() * 999.0)


func _set_shader_bool(parameter: StringName, value: bool) -> void:
	if _material == null:
		return

	_material.set_shader_parameter(parameter, value)


func _set_shader_int(parameter: StringName, value: int) -> void:
	if _material == null:
		return

	_material.set_shader_parameter(parameter, value)


func _set_shader_float(parameter: StringName, value: float) -> void:
	if _material == null:
		return

	_material.set_shader_parameter(parameter, value)


func _reset_pulses() -> void:
	_kill_boot_tween()
	_kill_submit_tween()
	_kill_warning_tween()
	_kill_error_tween()

	_set_shader_float(&"boot_pulse", 0.0)
	_set_shader_float(&"submit_pulse", 0.0)
	_set_shader_float(&"warning_pulse", 0.0)
	_set_shader_float(&"error_pulse", 0.0)


func _kill_boot_tween() -> void:
	if is_instance_valid(_boot_tween):
		_boot_tween.kill()

	_boot_tween = null


func _kill_submit_tween() -> void:
	if is_instance_valid(_submit_tween):
		_submit_tween.kill()

	_submit_tween = null


func _kill_warning_tween() -> void:
	if is_instance_valid(_warning_tween):
		_warning_tween.kill()

	_warning_tween = null


func _kill_error_tween() -> void:
	if is_instance_valid(_error_tween):
		_error_tween.kill()

	_error_tween = null
