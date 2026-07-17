class_name AiCompletionRequest
extends RefCounted
## Represents an immutable provider-neutral completion request.


#region State

var _request_id: StringName
var _conversation_id: StringName
var _model_id: StringName
var _messages: Array[AiMessage]
var _maximum_output_tokens: int
var _temperature: float
var _top_p: float
var _correlation_id: StringName

#endregion


#region Construction

## Creates a completion request.
func _init(
	conversation_id: StringName,
	model_id: StringName,
	messages: Array[AiMessage],
	maximum_output_tokens: int,
	temperature: float,
	top_p: float,
	correlation_id: StringName = &""
) -> void:
	assert(
		not conversation_id.is_empty(),
		"AiCompletionRequest requires conversation_id."
	)
	assert(
		not model_id.is_empty(),
		"AiCompletionRequest requires model_id."
	)
	assert(
		not messages.is_empty(),
		"AiCompletionRequest requires messages."
	)
	assert(
		maximum_output_tokens > 0,
		"AiCompletionRequest requires a positive output-token limit."
	)
	assert(
		temperature >= 0.0 and temperature <= 2.0,
		"AiCompletionRequest temperature must be between zero and two."
	)
	assert(
		top_p >= 0.0 and top_p <= 1.0,
		"AiCompletionRequest top_p must be between zero and one."
	)

	_request_id = StringName(UUID.v4())
	_conversation_id = conversation_id
	_model_id = model_id
	_messages = messages.duplicate()
	_maximum_output_tokens = maximum_output_tokens
	_temperature = temperature
	_top_p = top_p
	_correlation_id = correlation_id

	if _correlation_id.is_empty():
		_correlation_id = _request_id

#endregion


#region Public API

func get_request_id() -> StringName:
	return _request_id


func get_conversation_id() -> StringName:
	return _conversation_id


func get_model_id() -> StringName:
	return _model_id


func get_messages() -> Array[AiMessage]:
	return _messages.duplicate()


func get_maximum_output_tokens() -> int:
	return _maximum_output_tokens


func get_temperature() -> float:
	return _temperature


func get_top_p() -> float:
	return _top_p


func get_correlation_id() -> StringName:
	return _correlation_id

#endregion