@abstract
class_name SpeechToTextPort
extends RefCounted
## Defines a provider-independent speech-to-text boundary.


#region Public API

## Returns the stable provider identifier.
@abstract
func get_provider_id() -> StringName


## Returns `true` when the provider is configured and available.
@abstract
func is_available() -> bool


## Transcribes captured speech.
@abstract
func transcribe(
	request: VoiceTranscriptionRequest
) -> Result

#endregion