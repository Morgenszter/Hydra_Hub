class_name DisabledTextToSpeechProvider
extends TextToSpeechPort
## Safe provider used when text-to-speech processing is disabled.


#region Constants

const PROVIDER_ID: StringName = &"disabled"

#endregion


#region TextToSpeechPort

func get_provider_id() -> StringName:
	return PROVIDER_ID


func is_available() -> bool:
	return false


func synthesize(
	_request: VoiceSynthesisRequest
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Text-to-speech provider is disabled.",
			{
				&"provider_id": PROVIDER_ID,
			}
		)
	)

#endregion