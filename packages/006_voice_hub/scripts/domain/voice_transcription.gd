class_name VoiceTranscription
extends RefCounted
## Represents an immutable speech-to-text result.


#region State

var _text: String
var _language_code: String
var _confidence: float
var _provider_id: StringName
var _completed_at_unix_ms: int

#endregion


#region Construction

## Creates a transcription result.
func _init(
	text: String,
	language_code: String,
	confidence: float,
	provider_id: StringName
) -> void:
	assert(
		not text.strip_edges().is_empty(),
		"VoiceTranscription requires non-empty text."
	)
	assert(
		confidence >= 0.0 and confidence <= 1.0,
		"VoiceTranscription confidence must be between zero and one."
	)
	assert(
		not provider_id.is_empty(),
		"VoiceTranscription requires a provider identifier."
	)

	_text = text.strip_edges()
	_language_code = language_code.strip_edges()
	_confidence = confidence
	_provider_id = provider_id
	_completed_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)

#endregion


#region Public API

## Returns the normalized transcription text.
func get_text() -> String:
	return _text


## Returns the detected or requested language code.
func get_language_code() -> String:
	return _language_code


## Returns the provider confidence from zero to one.
func get_confidence() -> float:
	return _confidence


## Returns the provider identifier.
func get_provider_id() -> StringName:
	return _provider_id


## Returns the completion timestamp as Unix milliseconds.
func get_completed_at_unix_ms() -> int:
	return _completed_at_unix_ms

#endregion