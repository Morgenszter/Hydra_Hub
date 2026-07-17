class_name VoiceTranscriptionRequest
extends RefCounted
## Represents an immutable speech-to-text request.


#region State

var _request_id: StringName
var _audio_frames: PackedVector2Array
var _sample_rate_hz: int
var _language_code: String
var _correlation_id: StringName

#endregion


#region Construction

## Creates a transcription request from captured stereo audio frames.
func _init(
	audio_frames: PackedVector2Array,
	sample_rate_hz: int,
	language_code: String,
	correlation_id: StringName = &""
) -> void:
	assert(
		not audio_frames.is_empty(),
		"VoiceTranscriptionRequest requires audio frames."
	)
	assert(
		sample_rate_hz > 0,
		"VoiceTranscriptionRequest requires a positive sample rate."
	)
	assert(
		not language_code.strip_edges().is_empty(),
		"VoiceTranscriptionRequest requires a language code."
	)

	_request_id = StringName(UUID.v4())
	_audio_frames = audio_frames.duplicate()
	_sample_rate_hz = sample_rate_hz
	_language_code = language_code.strip_edges()
	_correlation_id = correlation_id

	if _correlation_id.is_empty():
		_correlation_id = _request_id

#endregion


#region Public API

## Returns the unique request identifier.
func get_request_id() -> StringName:
	return _request_id


## Returns a defensive copy of captured audio frames.
func get_audio_frames() -> PackedVector2Array:
	return _audio_frames.duplicate()


## Returns the source audio sample rate.
func get_sample_rate_hz() -> int:
	return _sample_rate_hz


## Returns the requested language code.
func get_language_code() -> String:
	return _language_code


## Returns the distributed tracing correlation identifier.
func get_correlation_id() -> StringName:
	return _correlation_id


## Returns the approximate audio duration in seconds.
func get_duration_seconds() -> float:
	return float(_audio_frames.size()) / float(_sample_rate_hz)

#endregion