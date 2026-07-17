class_name VoiceRequestsTest
extends RefCounted
## Provides executable tests for voice request models.


#region Tests

static func run() -> void:
	_test_transcription_request()
	_test_synthesis_request()


static func _test_transcription_request() -> void:
	var frames := PackedVector2Array([
		Vector2(0.1, 0.1),
		Vector2(0.2, 0.2),
	])

	var request := VoiceTranscriptionRequest.new(
		frames,
		48000,
		"pl-PL"
	)

	assert(not request.get_request_id().is_empty())
	assert(request.get_audio_frames().size() == 2)
	assert(request.get_sample_rate_hz() == 48000)
	assert(request.get_language_code() == "pl-PL")


static func _test_synthesis_request() -> void:
	var request := VoiceSynthesisRequest.new(
		"System operational.",
		"en-US",
		&"default",
		1.0
	)

	assert(not request.get_request_id().is_empty())
	assert(request.get_text() == "System operational.")
	assert(request.get_voice_id() == &"default")
	assert(is_equal_approx(request.get_speech_rate(), 1.0))

#endregion