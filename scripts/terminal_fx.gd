class_name TerminalFX
extends ColorRect


@export_group("Initial State")

@export var enabled_on_ready: bool = false
@export var auto_glitch: bool = true


@export_group("Auto Glitch")

@export_range(0.1, 20.0, 0.1)
var glitch_interval_min: float = 1.5

@export_range(0.1, 20.0, 0.1)
var glitch_interval_max: float = 4.5

@export_range(0.01, 1.0, 0.01)
var glitch_duration_min: float = 0.04

@export_range(0.01, 1.0, 0.01)
var glitch_duration_max: float = 0.09


@export_group("Glitch Strength")

@export_range(0.0, 0.10, 0.0005)
var glitch_shift_min: float = 0.003

@export_range(0.0, 0.10, 0.0005)
var glitch_shift_max: float = 0.012

@export_range(0.0, 0.05, 0.0005)
var chromatic_shift_min: float = 0.001

@export_range(0.0, 0.05, 0.0005)
var chromatic_shift_max: float = 0.006

@export_range(0.001, 0.50, 0.001)
var glitch_band_height_min: float = 0.025

@export_range(0.001, 0.50, 0.001)
var glitch_band_height_max: float = 0.11


var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _shader_material: ShaderMaterial

var _operational: bool = false
var _fx_enabled: bool = false
var _loop_running: bool = false

var _loop_revision: int = 0
var _pulse_revision: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

	_rng.randomize()

	_prepare_material()
	set_fx_enabled(enabled_on_ready)

	if auto_glitch:
		_start_auto_glitch_loop()


func _exit_tree() -> void:
	_loop_revision += 1
	_pulse_revision += 1


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
		_pulse_revision += 1
		_reset_glitch_parameters()


func is_fx_enabled() -> bool:
	return _fx_enabled


func is_operational() -> bool:
	return _operational


func pulse_glitch(
	custom_strength: float = -1.0,
	custom_duration: float = -1.0
) -> void:
	if not _operational:
		return

	if not _fx_enabled:
		return

	if not is_inside_tree():
		return

	_pulse_revision += 1

	var current_revision: int = _pulse_revision

	var shift_min: float = minf(
		glitch_shift_min,
		glitch_shift_max
	)

	var shift_max: float = maxf(
		glitch_shift_min,
		glitch_shift_max
	)

	var chromatic_min: float = minf(
		chromatic_shift_min,
		chromatic_shift_max
	)

	var chromatic_max: float = maxf(
		chromatic_shift_min,
		chromatic_shift_max
	)

	var band_min: float = minf(
		glitch_band_height_min,
		glitch_band_height_max
	)

	var band_max: float = maxf(
		glitch_band_height_min,
		glitch_band_height_max
	)

	var duration_min: float = minf(
		glitch_duration_min,
		glitch_duration_max
	)

	var duration_max: float = maxf(
		glitch_duration_min,
		glitch_duration_max
	)

	var glitch_strength: float = custom_strength

	if glitch_strength < 0.0:
		glitch_strength = _rng.randf_range(
			shift_min,
			shift_max
		)

	var glitch_duration: float = custom_duration

	if glitch_duration < 0.0:
		glitch_duration = _rng.randf_range(
			duration_min,
			duration_max
		)

	var chromatic_strength: float = _rng.randf_range(
		chromatic_min,
		chromatic_max
	)

	var band_height: float = _rng.randf_range(
		band_min,
		band_max
	)

	var band_position: float = _rng.randf_range(
		0.08,
		0.92
	)

	_set_shader_parameter(
		&"glitch_amount",
		maxf(glitch_strength, 0.0)
	)

	_set_shader_parameter(
		&"chromatic_amount",
		chromatic_strength
	)

	_set_shader_parameter(
		&"glitch_band_height",
		band_height
	)

	_set_shader_parameter(
		&"glitch_band_y",
		band_position
	)

	await get_tree().create_timer(
		maxf(glitch_duration, 0.01)
	).timeout

	if not is_inside_tree():
		return

	if current_revision != _pulse_revision:
		return

	_reset_glitch_parameters()


func pulse_warning_glitch() -> void:
	await pulse_glitch(
		0.014,
		0.07
	)


func pulse_error_glitch() -> void:
	await pulse_glitch(
		0.026,
		0.11
	)


func set_scanline_strength(value: float) -> void:
	_set_shader_parameter(
		&"scanline_strength",
		clampf(value, 0.0, 0.30)
	)


func set_sweep_strength(value: float) -> void:
	_set_shader_parameter(
		&"sweep_strength",
		clampf(value, 0.0, 0.50)
	)


func set_noise_strength(value: float) -> void:
	_set_shader_parameter(
		&"noise_strength",
		clampf(value, 0.0, 0.20)
	)


func set_flicker_strength(value: float) -> void:
	_set_shader_parameter(
		&"flicker_strength",
		clampf(value, 0.0, 0.20)
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
			"TerminalFX wymaga ShaderMaterial z terminal_fx.gdshader."
		)

		return

	_shader_material = (
		source_material.duplicate() as ShaderMaterial
	)

	if _shader_material == null:
		_operational = false
		visible = false

		push_error(
			"Nie udało się zduplikować ShaderMaterial dla TerminalFX."
		)

		return

	material = _shader_material
	_operational = true

	_reset_glitch_parameters()


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


func _reset_glitch_parameters() -> void:
	if not _operational:
		return

	_set_shader_parameter(
		&"glitch_amount",
		0.0
	)

	_set_shader_parameter(
		&"chromatic_amount",
		0.0
	)

	_set_shader_parameter(
		&"glitch_band_y",
		0.5
	)

	_set_shader_parameter(
		&"glitch_band_height",
		0.06
	)


# -------------------------------------------------------------------
# AUTO GLITCH
# -------------------------------------------------------------------

func _start_auto_glitch_loop() -> void:
	if _loop_running:
		return

	_loop_running = true
	_loop_revision += 1

	var current_revision: int = _loop_revision

	while (
		is_inside_tree()
		and current_revision == _loop_revision
	):
		var interval_min: float = minf(
			glitch_interval_min,
			glitch_interval_max
		)

		var interval_max: float = maxf(
			glitch_interval_min,
			glitch_interval_max
		)

		var wait_time: float = _rng.randf_range(
			interval_min,
			interval_max
		)

		await get_tree().create_timer(
			maxf(wait_time, 0.1)
		).timeout

		if not is_inside_tree():
			break

		if current_revision != _loop_revision:
			break

		if _fx_enabled:
			await pulse_glitch()

	if current_revision == _loop_revision:
		_loop_running = false
