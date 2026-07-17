@abstract
class_name TextToSpeechPort
extends RefCounted
## Defines a provider-independent text-to-speech boundary.


#region Public API

## Returns the stable provider identifier.
@abstract
func get_provider_id() -> StringName


## Returns `true` when the provider is configured and available.
@abstract
func is_available() -> bool


## Synthesizes speech and returns an AudioStream in a Result.
@abstract
func synthesize(
	request: VoiceSynthesisRequest
) -> Result

#endregion