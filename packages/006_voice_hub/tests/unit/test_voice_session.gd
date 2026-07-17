class_name VoiceSessionTest
extends RefCounted
## Provides executable VoiceSession domain tests.


#region Tests

static func run() -> void:
	_test_valid_capture_lifecycle()
	_test_invalid_transition()
	_test_failure_state()


static func _test_valid_capture_lifecycle() -> void:
	var session := VoiceSession.new(EntityId.generate())

	assert(session.arm().is_success())
	assert(
		session.get_state()
		== VoiceSessionState.Value.ARMED
	)

	assert(session.start_listening().is_success())
	assert(
		session.get_state()
		== VoiceSessionState.Value.LISTENING
	)

	assert(session.start_processing().is_success())

	var transcription := VoiceTranscription.new(
		"Test transcription",
		"en-US",
		0.95,
		&"test_provider"
	)

	assert(
		session.complete_transcription(
			transcription
		).is_success()
	)
	assert(
		session.get_state()
		== VoiceSessionState.Value.COMPLETED
	)
	assert(session.get_transcription() == transcription)
	assert(not session.pull_domain_events().is_empty())


static func _test_invalid_transition() -> void:
	var session := VoiceSession.new(EntityId.generate())
	var result := session.start_processing()

	assert(result.is_failure())
	assert(
		result.get_error().get_code()
		== HydraErrors.INVALID_STATE
	)


static func _test_failure_state() -> void:
	var session := VoiceSession.new(EntityId.generate())
	var error := DomainError.new(
		HydraErrors.UNKNOWN,
		"Test failure."
	)

	assert(session.fail(error).is_success())
	assert(
		session.get_state()
		== VoiceSessionState.Value.FAILED
	)
	assert(session.get_failure() == error)

#endregion