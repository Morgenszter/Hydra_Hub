class_name AiCompletionResponse
extends RefCounted
## Represents an immutable AI provider response.


#region State

var _response_id: StringName
var _request_id: StringName
var _provider_id: StringName
var _model_id: StringName
var _message: AiMessage
var _input_tokens: int
var _output_tokens: int
var _completed_at_unix_ms: int
var _finish_reason: StringName

#endregion


#region Construction

## Creates an AI completion response.
func _init(
	request_id: StringName,
	provider_id: StringName,
	model_id: StringName,
	message: AiMessage,
	input_tokens: int,
	output_tokens: int,
	finish_reason: StringName
) -> void:
	assert(
		not request_id.is_empty(),
		"AiCompletionResponse requires request_id."
	)
	assert(
		not provider_id.is_empty(),
		"AiCompletionResponse requires provider_id."
	)
	assert(
		not model_id.is_empty(),
		"AiCompletionResponse requires model_id."
	)
	assert(
		message != null,
		"AiCompletionResponse requires message."
	)
	assert(
		input_tokens >= 0 and output_tokens >= 0,
		"AI token counts cannot be negative."
	)

	_response_id = StringName(UUID.v4())
	_request_id = request_id
	_provider_id = provider_id
	_model_id = model_id
	_message = message
	_input_tokens = input_tokens
	_output_tokens = output_tokens
	_completed_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	_finish_reason = finish_reason

#endregion


#region Public API

func get_response_id() -> StringName:
	return _response_id


func get_request_id() -> StringName:
	return _request_id


func get_provider_id() -> StringName:
	return _provider_id


func get_model_id() -> StringName:
	return _model_id


func get_message() -> AiMessage:
	return _message


func get_input_tokens() -> int:
	return _input_tokens


func get_output_tokens() -> int:
	return _output_tokens


func get_total_tokens() -> int:
	return _input_tokens + _output_tokens


func get_completed_at_unix_ms() -> int:
	return _completed_at_unix_ms


func get_finish_reason() -> StringName:
	return _finish_reason

#endregion