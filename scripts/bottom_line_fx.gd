class_name BottomLineFX
extends ColorRect


@export_group("Initial State")

@export var enabled_on_ready: bool = false

@export_range(0.0, 1.0, 0.01)
var idle_activity: float = 0.22

@export_range(0.0, 1.0, 0.01)
var input_activity: float = 1.0


@export_group("Transitions")

@export_range(0.01, 2.0, 0.01)
var activity_transition_duration: float = 0.18

@export_range(0.01, 1.0, 0.01)
var submit_attack_duration: float = 0.04

@export_range(0.01, 2.0, 0.01)
var submit_release_duration: float = 0.24

@export_range(0.01, 1.0, 0.01)
var warning_attack_duration: float = 0.05

@export_range(0.01, 2.0, 0.01)
var warning_release_duration: float = 0.38

@export_range(0.01, 1.0, 0.01)
var error_attack_duration: float = 0.025

@export_range(0.0, 1.0, 0.01)
var error_hold_duration: float = 0.07

@export_range(0.01, 2.0, 0.01)
var error_release_duration: float = 0.48


var _shader_material: ShaderMaterial

var _operational: bool = false
var _fx_enabled: bool = false
var _input_active: bool = false

var _activity_tween: Tween
var _submit_tween: Tween
var _alert_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

	_prepare_material()
	set_fx_enabled(enabled_on_ready)


func _exit_tree() -> void:
	_kill_all_tweens()


# -------------------------------------------------------------------
# PUBLIC API
# -------------------------------------------------------------------

func set_fx_enabled(value: bool) -> void:
	_fx_enabled = value

	visible = (
		_fx_enabled
		and _operational
	)

	if not _fx_enabled:
		_kill_all_tweens()

		_set_shader_parameter(
			&"activity",
			idle_activity
		)

		_set_shader_parameter(
			&"submit_pulse",
			0.0
		)

		_set_shader_parameter(
			&"alert_level",
			0.0
		)

		return

	_set_shader_parameter(
		&"activity",
		input_activity
		if _input_active
		else idle_activity
	)


func is_fx_enabled() -> bool:
	return _fx_enabled


func is_operational() -> bool:
	return _operational


func set_input_active(value: bool) -> void:
	_input_active = value

	if not _operational:
		return

	if not _fx_enabled:
		return

	_kill_tween(_activity_tween)

	var target_activity: float = (
		input_activity
		if _input_active
		else idle_activity
	)

	var current_activity: float = float(
		_shader_material.get_shader_parameter(
			&"activity"
		)
	)

	_activity_tween = create_tween()

	_activity_tween.set_trans(
		Tween.TRANS_CUBIC
	)

	_activity_tween.set_ease(
		Tween.EASE_OUT
	)

	_activity_tween.tween_method(
		_set_activity_value,
		current_activity,
		target_activity,
		activity_transition_duration
	)


func pulse_submit() -> void:
	if not _can_play_effect():
		return

	_kill_tween(_submit_tween)

	_set_shader_parameter(
		&"submit_pulse",
		0.0
	)

	_submit_tween = create_tween()

	_submit_tween.set_trans(
		Tween.TRANS_CUBIC
	)

	_submit_tween.set_ease(
		Tween.EASE_OUT
	)

	_submit_tween.tween_method(
		_set_submit_value,
		0.0,
		1.0,
		submit_attack_duration
	)

	_submit_tween.tween_method(
		_set_submit_value,
		1.0,
		0.0,
		submit_release_duration
	)


func pulse_warning() -> void:
	if not _can_play_effect():
		return

	_kill_tween(_alert_tween)

	_set_shader_parameter(
		&"alert_level",
		0.0
	)

	_alert_tween = create_tween()

	_alert_tween.set_trans(
		Tween.TRANS_CUBIC
	)

	_alert_tween.set_ease(
		Tween.EASE_OUT
	)

	_alert_tween.tween_method(
		_set_alert_value,
		0.0,
		0.58,
		warning_attack_duration
	)

	_alert_tween.tween_method(
		_set_alert_value,
		0.58,
		0.0,
		warning_release_duration
	)


func pulse_error() -> void:
	if not _can_play_effect():
		return

	_kill_tween(_alert_tween)

	_set_shader_parameter(
		&"alert_level",
		0.0
	)

	_alert_tween = create_tween()

	_alert_tween.set_trans(
		Tween.TRANS_EXPO
	)

	_alert_tween.set_ease(
		Tween.EASE_OUT
	)

	_alert_tween.tween_method(
		_set_alert_value,
		0.0,
		1.0,
		error_attack_duration
	)

	if error_hold_duration > 0.0:
		_alert_tween.tween_interval(
			error_hold_duration
		)

	_alert_tween.tween_method(
		_set_alert_value,
		1.0,
		0.0,
		error_release_duration
	)


func reset_effects() -> void:
	_kill_all_tweens()

	_set_shader_parameter(
		&"activity",
		input_activity
		if _input_active
		else idle_activity
	)

	_set_shader_parameter(
		&"submit_pulse",
		0.0
	)

	_set_shader_parameter(
		&"alert_level",
		0.0
	)


# -------------------------------------------------------------------
# MATERIAL
# -------------------------------------------------------------------

func _prepare_material() -> void:
	var source_material: ShaderMaterial = (
		material as ShaderMaterial
	)

	if source_material == null:
		_operational = false
		visible = false

		push_error(
			"BottomLineFX wymaga ShaderMaterial z bottom_line_fx.gdshader."
		)

		return

	_shader_material = (
		source_material.duplicate() as ShaderMaterial
	)

	if _shader_material == null:
		_operational = false
		visible = false

		push_error(
			"Nie udało się zduplikować ShaderMaterial dla BottomLineFX."
		)

		return

	material = _shader_material
	_operational = true

	_set_shader_parameter(
		&"activity",
		idle_activity
	)

	_set_shader_parameter(
		&"submit_pulse",
		0.0
	)

	_set_shader_parameter(
		&"alert_level",
		0.0
	)


func _set_shader_parameter(
	parameter_name: StringName,
	value: Variant
) -> void:
	if not _operational:
		return

	if _shader_material == null:
		return

	_shader_material.set_shader_parameter(
		parameter_name,
		value
	)


# -------------------------------------------------------------------
# TWEEN CALLBACKS
# -------------------------------------------------------------------

func _set_activity_value(value: float) -> void:
	_set_shader_parameter(
		&"activity",
		clampf(value, 0.0, 1.0)
	)


func _set_submit_value(value: float) -> void:
	_set_shader_parameter(
		&"submit_pulse",
		clampf(value, 0.0, 1.0)
	)


func _set_alert_value(value: float) -> void:
	_set_shader_parameter(
		&"alert_level",
		clampf(value, 0.0, 1.0)
	)


# -------------------------------------------------------------------
# INTERNAL
# -------------------------------------------------------------------

func _can_play_effect() -> bool:
	return (
		_operational
		and _fx_enabled
		and visible
		and is_inside_tree()
	)


func _kill_all_tweens() -> void:
	_kill_tween(_activity_tween)
	_kill_tween(_submit_tween)
	_kill_tween(_alert_tween)

	_activity_tween = null
	_submit_tween = null
	_alert_tween = null


func _kill_tween(tween: Tween) -> void:
	if tween == null:
		return

	if tween.is_valid():
		tween.kill()
