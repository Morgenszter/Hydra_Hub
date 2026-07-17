class_name VoiceHubService
extends Node
## Coordinates voice capture, transcription and speech synthesis.
##
## Provider implementations are injected explicitly. Presentation classes
## communicate with this service through its public methods and signals.


#region Signals

signal session_state_changed(
	state: VoiceSessionState.Value
)
signal input_level_changed(level_db: float)
signal transcription_completed(
	transcription: VoiceTranscription
)
signal speech_started()
signal speech_completed()
signal operation_failed(error: DomainError)

#endregion


#region State

var _configuration: VoiceHubConfiguration
var _capture: VoiceCapturePort
var _speech_to_text: SpeechToTextPort
var _text_to_speech: TextToSpeechPort
var _session: VoiceSession
var _speech_player: AudioStreamPlayer

#endregion


#region Lifecycle

func _ready() -> void:
	_speech_player = AudioStreamPlayer.new()
	_speech_player.name = "VoiceSpeechPlayer"
	add_child(_speech_player)

	_speech_player.finished.connect(
		_on_speech_finished
	)

#endregion


#region Public API

## Configures Voice Hub and injects provider implementations.
func configure(
	configuration: VoiceHubConfiguration,
	capture: VoiceCapturePort,
	speech_to_text: SpeechToTextPort,
	text_to_speech: TextToSpeechPort
) -> Result:
	if configuration == null:
		return _failure(
			HydraErrors.VALUE_REQUIRED,
			"Voice Hub configuration cannot be null."
		)

	if capture == null:
		return _failure(
			HydraErrors.VALUE_REQUIRED,
			"Voice capture service cannot be null."
		)

	if speech_to_text == null:
		return _failure(
			HydraErrors.VALUE_REQUIRED,
			"Speech-to-text provider cannot be null."
		)

	if text_to_speech == null:
		return _failure(
			HydraErrors.VALUE_REQUIRED,
			"Text-to-speech provider cannot be null."
		)

	var capture_result := capture.configure(configuration)

	if capture_result.is_failure():
		return capture_result

	_disconnect_capture_signals()

	_configuration = configuration
	_capture = capture
	_speech_to_text = speech_to_text
	_text_to_speech = text_to_speech

	_connect_capture_signals()

	return Result.success()


## Creates and arms a new voice session.
func arm_session() -> Result:
	_session = VoiceSession.new(EntityId.generate())

	var result := _session.arm()
	_publish_session_events()
	_emit_current_state()

	return result


## Starts microphone capture for the active session.
func start_listening() -> Result:
	if _session == null:
		var arm_result := arm_session()

		if arm_result.is_failure():
			return arm_result

	var transition_result := _session.start_listening()

	if transition_result.is_failure():
		return transition_result

	var capture_result := _capture.start_capture()

	if capture_result.is_failure():
		_session.fail(capture_result.get_error())
		_publish_session_events()
		_emit_current_state()
		operation_failed.emit(capture_result.get_error())

		return capture_result

	_publish_session_events()
	_emit_current_state()

	return Result.success()


## Stops capture and synchronously invokes the configured transcription provider.
func stop_and_transcribe() -> Result:
	if _session == null:
		return _failure(
			HydraErrors.INVALID_STATE,
			"No active voice session exists."
		)

	var processing_result := _session.start_processing()

	if processing_result.is_failure():
		return processing_result

	_publish_session_events()
	_emit_current_state()

	var capture_result := _capture.stop_capture()

	if capture_result.is_failure():
		return _fail_session(capture_result.get_error())

	var frames: PackedVector2Array = capture_result.get_value()

	if frames.is_empty():
		return _fail_session(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Voice capture did not return audio frames."
			)
		)

	if (
		not _configuration.allow_external_processing
		and _speech_to_text.get_provider_id() != &"local"
	):
		return _fail_session(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"External voice processing is disabled.",
				{
					&"provider_id":
						_speech_to_text.get_provider_id(),
				}
			)
		)

	var request := VoiceTranscriptionRequest.new(
		frames,
		_configuration.sample_rate_hz,
		_configuration.language_code,
		_session.get_id().get_value()
	)

	var transcription_result := _speech_to_text.transcribe(request)

	if transcription_result.is_failure():
		return _fail_session(
			transcription_result.get_error()
		)

	var transcription: VoiceTranscription = \
		transcription_result.get_value()

	var completion_result := _session.complete_transcription(
		transcription
	)

	if completion_result.is_failure():
		return completion_result

	_publish_session_events()
	_emit_current_state()
	transcription_completed.emit(transcription)

	return Result.success(transcription)


## Synthesizes and plays speech using the configured provider.
func speak(
	text: String,
	voice_id: StringName = &"default",
	speech_rate: float = 1.0
) -> Result:
	if _configuration == null:
		return _failure(
			HydraErrors.INVALID_STATE,
			"Voice Hub is not configured."
		)

	if (
		not _configuration.allow_external_processing
		and _text_to_speech.get_provider_id() != &"local"
	):
		return _failure(
			HydraErrors.INVALID_STATE,
			"External voice processing is disabled."
		)

	if _session == null:
		_session = VoiceSession.new(EntityId.generate())

	var request := VoiceSynthesisRequest.new(
		text,
		_configuration.language_code,
		voice_id,
		speech_rate,
		_session.get_id().get_value()
	)

	var synthesis_result := _text_to_speech.synthesize(request)

	if synthesis_result.is_failure():
		return _fail_session(
			synthesis_result.get_error()
		)

	var stream: AudioStream = synthesis_result.get_value()

	if stream == null:
		return _fail_session(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Text-to-speech provider returned no audio stream."
			)
		)

	var state_result := _session.start_speaking()

	if state_result.is_failure():
		return state_result

	_speech_player.stream = stream
	_speech_player.play()

	_publish_session_events()
	_emit_current_state()
	speech_started.emit()

	return Result.success()


## Cancels the active voice operation.
func cancel() -> Result:
	if _capture != null:
		_capture.cancel_capture()

	if _speech_player != null:
		_speech_player.stop()

	if _session == null:
		return Result.success()

	var result := _session.cancel()
	_publish_session_events()
	_emit_current_state()

	return result


## Returns the active session.
func get_session() -> VoiceSession:
	return _session

#endregion


#region Private methods

func _connect_capture_signals() -> void:
	if _capture == null:
		return

	if not _capture.input_level_changed.is_connected(
		_on_input_level_changed
	):
		_capture.input_level_changed.connect(
			_on_input_level_changed
		)

	if not _capture.capture_failed.is_connected(
		_on_capture_failed
	):
		_capture.capture_failed.connect(
			_on_capture_failed
		)


func _disconnect_capture_signals() -> void:
	if _capture == null:
		return

	if _capture.input_level_changed.is_connected(
		_on_input_level_changed
	):
		_capture.input_level_changed.disconnect(
			_on_input_level_changed
		)

	if _capture.capture_failed.is_connected(
		_on_capture_failed
	):
		_capture.capture_failed.disconnect(
			_on_capture_failed
		)


func _publish_session_events() -> void:
	if _session == null:
		return

	if not Engine.has_singleton("EventBus"):
		_session.clear_domain_events()
		return

	var event_bus := Engine.get_singleton("EventBus")

	for event in _session.pull_domain_events():
		event_bus.publish(event)


func _emit_current_state() -> void:
	if _session == null:
		return

	session_state_changed.emit(_session.get_state())


func _failure(
	code: StringName,
	message: String
) -> Result:
	var error := DomainError.new(code, message)
	operation_failed.emit(error)

	return Result.failure(error)


func _fail_session(error: DomainError) -> Result:
	if _session != null:
		_session.fail(error)
		_publish_session_events()
		_emit_current_state()

	operation_failed.emit(error)

	return Result.failure(error)


func _on_input_level_changed(level_db: float) -> void:
	input_level_changed.emit(level_db)


func _on_capture_failed(error: DomainError) -> void:
	_fail_session(error)


func _on_speech_finished() -> void:
	if _session != null:
		_session.complete_speaking()
		_publish_session_events()
		_emit_current_state()

	speech_completed.emit()

#endregion