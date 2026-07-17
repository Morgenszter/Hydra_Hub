class_name VoiceSynthesisRequest
extends RefCounted
## Represents an immutable text-to-speech request.


#region State

var _request_id: StringName
var _text: String
var _language_code: String
var _voice_id: StringName
var _speech_rate: float
var _correlation_id: StringName

#endregion


#region Construction

## Creates a synthesis request.
func _init(
	text: String,
	language_code: String,
	voice_id: StringName,
	speech_rate: float = 1.0,
	correlation_id: StringName = &""
) -> void:
	assert(
		not text.strip_edges().is_empty(),
		"VoiceSynthesisRequest requires text."
	)
	assert(
		not language_code.strip_edges().is_empty(),
		"VoiceSynthesisRequest requires a language code."
	)
	assert(
		not voice_id.is_empty(),
		"VoiceSynthesisRequest requires a voice identifier."
	)
	assert(
		speech_rate >= 0.5 and speech_rate <= 2.0,
		"VoiceSynthesisRequest speech rate must be between 0.5 and 2.0."
	)

	_request_id = StringName(UUID.v4())
	_text = text.strip_edges()
	_language_code = language_code.strip_edges()
	_voice_id = voice_id
	_speech_rate = speech_rate
	_correlation_id = correlation_id

	if _correlation_id.is_empty():
		_correlation_id = _request_id

#endregion


#region Public API

## Returns the unique request identifier.
func get_request_id() -> StringName:
	return _request_id


## Returns the text to synthesize.
func get_text() -> String:
	return _text


## Returns the requested language code.
func get_language_code() -> String:
	return _language_code


## Returns the requested provider voice identifier.
func get_voice_id() -> StringName:
	return _voice_id


## Returns the speech-rate multiplier.
func get_speech_rate() -> float:
	return _speech_rate


## Returns the distributed tracing correlation identifier.
func get_correlation_id() -> StringName:
	return _correlation_id

#endregion