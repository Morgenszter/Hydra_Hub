class_name GodotVoiceCapture
extends VoiceCapturePort
## Captures microphone audio through an AudioEffectCapture instance.
##
## The project must contain an audio bus matching the configured bus name and
## that bus must contain AudioEffectCapture as its first effect.


#region Constants

const CAPTURE_EFFECT_INDEX: int = 0

#endregion


#region State

var _configuration: VoiceHubConfiguration
var _capture_effect: AudioEffectCapture
var _capturing: bool = false
var _captured_frames: PackedVector2Array = PackedVector2Array()

#endregion


#region Lifecycle

func _process(_delta: float) -> void:
	if not _capturing or _capture_effect == null:
		return

	var available_frames := _capture_effect.get_frames_available()

	if available_frames <= 0:
		return

	var frames := _capture_effect.get_buffer(available_frames)
	_append_frames(frames)
	_emit_input_level(frames)
	_enforce_duration_limit()

#endregion


#region VoiceCapturePort

func configure(configuration: VoiceHubConfiguration) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Voice capture configuration cannot be null."
			)
		)

	var bus_index := AudioServer.get_bus_index(
		configuration.input_bus_name
	)

	if bus_index < 0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Voice capture audio bus does not exist.",
				{
					&"bus_name": configuration.input_bus_name,
				}
			)
		)

	var effect := AudioServer.get_bus_effect(
		bus_index,
		CAPTURE_EFFECT_INDEX
	)

	if not effect is AudioEffectCapture:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Voice capture bus requires AudioEffectCapture.",
				{
					&"bus_name": configuration.input_bus_name,
					&"effect_index": CAPTURE_EFFECT_INDEX,
				}
			)
		)

	_configuration = configuration
	_capture_effect = effect as AudioEffectCapture

	return Result.success()


func start_capture() -> Result:
	if _configuration == null or _capture_effect == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Voice capture service is not configured."
			)
		)

	if _capturing:
		return Result.success()

	_captured_frames = PackedVector2Array()
	_capture_effect.clear_buffer()
	_capturing = true
	set_process(true)
	capture_started.emit()

	return Result.success()


func stop_capture() -> Result:
	if not _capturing:
		return Result.success(
			_captured_frames.duplicate()
		)

	_drain_capture_buffer()
	_capturing = false
	set_process(false)

	var result_frames := _captured_frames.duplicate()
	capture_stopped.emit(result_frames)

	return Result.success(result_frames)


func cancel_capture() -> void:
	_capturing = false
	set_process(false)
	_captured_frames = PackedVector2Array()

	if _capture_effect != null:
		_capture_effect.clear_buffer()


func is_capturing() -> bool:
	return _capturing

#endregion


#region Private methods

func _drain_capture_buffer() -> void:
	if _capture_effect == null:
		return

	var available_frames := _capture_effect.get_frames_available()

	if available_frames > 0:
		_append_frames(
			_capture_effect.get_buffer(available_frames)
		)


func _append_frames(frames: PackedVector2Array) -> void:
	_captured_frames.append_array(frames)


func _emit_input_level(frames: PackedVector2Array) -> void:
	if frames.is_empty():
		return

	var peak := 0.0

	for frame in frames:
		peak = maxf(
			peak,
			maxf(absf(frame.x), absf(frame.y))
		)

	var level_db := linear_to_db(maxf(peak, 0.000001))
	input_level_changed.emit(level_db)


func _enforce_duration_limit() -> void:
	var maximum_frames := int(
		_configuration.maximum_capture_seconds
		* float(_configuration.sample_rate_hz)
	)

	if _captured_frames.size() < maximum_frames:
		return

	stop_capture()

#endregion