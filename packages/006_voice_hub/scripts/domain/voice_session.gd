class_name VoiceSession
extends AggregateRoot
## Represents one complete user voice interaction.
##
## VoiceSession owns the interaction state and publishes immutable domain
## events whenever its lifecycle changes.


#region Event names

const EVENT_STATE_CHANGED: StringName = \
	&"hydra.voice.session.state_changed"
const EVENT_TRANSCRIPTION_COMPLETED: StringName = \
	&"hydra.voice.session.transcription_completed"
const EVENT_SESSION_FAILED: StringName = \
	&"hydra.voice.session.failed"

#endregion


#region State

var _state: VoiceSessionState.Value = VoiceSessionState.Value.IDLE
var _transcription: VoiceTranscription
var _failure: DomainError

#endregion


#region Construction

## Creates a new idle voice session.
func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

## Returns the current session state.
func get_state() -> VoiceSessionState.Value:
	return _state


## Returns the completed transcription, when available.
func get_transcription() -> VoiceTranscription:
	return _transcription


## Returns the current failure, when available.
func get_failure() -> DomainError:
	return _failure


## Arms the session for audio capture.
func arm() -> Result:
	return _transition(
		VoiceSessionState.Value.ARMED,
		[
			VoiceSessionState.Value.IDLE,
			VoiceSessionState.Value.COMPLETED,
			VoiceSessionState.Value.CANCELLED,
		]
	)


## Starts microphone capture.
func start_listening() -> Result:
	return _transition(
		VoiceSessionState.Value.LISTENING,
		[VoiceSessionState.Value.ARMED]
	)


## Marks audio as captured and starts processing.
func start_processing() -> Result:
	return _transition(
		VoiceSessionState.Value.PROCESSING,
		[VoiceSessionState.Value.LISTENING]
	)


## Completes speech-to-text processing.
func complete_transcription(
	transcription: VoiceTranscription
) -> Result:
	if transcription == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Voice transcription cannot be null."
			)
		)

	if _state != VoiceSessionState.Value.PROCESSING:
		return _invalid_transition(
			VoiceSessionState.Value.COMPLETED
		)

	_transcription = transcription
	_failure = null
	_state = VoiceSessionState.Value.COMPLETED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_TRANSCRIPTION_COMPLETED,
			{
				&"session_id": get_id().as_string(),
				&"text": transcription.get_text(),
				&"language_code": transcription.get_language_code(),
				&"confidence": transcription.get_confidence(),
				&"provider_id": transcription.get_provider_id(),
			}
		)
	)

	_record_state_changed_event()

	return Result.success()


## Marks synthesized voice output as active.
func start_speaking() -> Result:
	return _transition(
		VoiceSessionState.Value.SPEAKING,
		[
			VoiceSessionState.Value.IDLE,
			VoiceSessionState.Value.COMPLETED,
		]
	)


## Completes synthesized voice output.
func complete_speaking() -> Result:
	return _transition(
		VoiceSessionState.Value.COMPLETED,
		[VoiceSessionState.Value.SPEAKING]
	)


## Cancels the current interaction.
func cancel() -> Result:
	if _state == VoiceSessionState.Value.CANCELLED:
		return Result.success()

	if _state == VoiceSessionState.Value.FAILED:
		return _invalid_transition(
			VoiceSessionState.Value.CANCELLED
		)

	_state = VoiceSessionState.Value.CANCELLED
	increment_version()
	_record_state_changed_event()

	return Result.success()


## Records a structured session failure.
func fail(error: DomainError) -> Result:
	if error == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Voice session failure cannot be null."
			)
		)

	_failure = error
	_state = VoiceSessionState.Value.FAILED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_SESSION_FAILED,
			{
				&"session_id": get_id().as_string(),
				&"error": error.to_dictionary(),
			}
		)
	)

	_record_state_changed_event()

	return Result.success()

#endregion


#region Private methods

func _transition(
	next_state: VoiceSessionState.Value,
	allowed_states: Array[VoiceSessionState.Value]
) -> Result:
	if _state not in allowed_states:
		return _invalid_transition(next_state)

	_state = next_state
	increment_version()
	_record_state_changed_event()

	return Result.success()


func _invalid_transition(
	next_state: VoiceSessionState.Value
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Voice session state transition is invalid.",
			{
				&"current_state": VoiceSessionState.to_string_name(
					_state
				),
				&"requested_state": VoiceSessionState.to_string_name(
					next_state
				),
			}
		)
	)


func _record_state_changed_event() -> void:
	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_CHANGED,
			{
				&"session_id": get_id().as_string(),
				&"state": VoiceSessionState.to_string_name(_state),
			}
		)
	)

#endregion