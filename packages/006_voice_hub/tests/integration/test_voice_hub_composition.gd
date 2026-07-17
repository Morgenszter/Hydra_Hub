class_name VoiceHubCompositionTest
extends RefCounted
## Verifies safe Voice Hub composition with disabled providers.


#region Tests

static func run() -> void:
	var service := VoiceHubService.new()
	var capture := GodotVoiceCapture.new()
	var speech_to_text := DisabledSpeechToTextProvider.new()
	var text_to_speech := DisabledTextToSpeechProvider.new()

	assert(service != null)
	assert(capture != null)
	assert(not speech_to_text.is_available())
	assert(not text_to_speech.is_available())

#endregion