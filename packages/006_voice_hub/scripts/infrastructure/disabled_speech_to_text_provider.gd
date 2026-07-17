class_name DisabledSpeechToTextProvider
extends SpeechToTextPort
## Safe provider used when speech-to-text processing is disabled.


#region Constants

const PROVIDER_ID: StringName = &"disabled"

#endregion


#region SpeechToTextPort

func get_provider_id() -> StringName:
	return PROVIDER_ID


func is_available() -> bool:
	return false


func transcribe(
	_request: VoiceTranscriptionRequest
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Speech-to-text provider is disabled.",
			{
				&"provider_id": PROVIDER_ID,
			}
		)
	)

#endregion