class_name AiConversation
extends AggregateRoot
## Owns one conversational context and its execution lifecycle.


#region Events

const EVENT_MESSAGE_ADDED: StringName = \
	&"hydra.ai.conversation.message_added"
const EVENT_STATE_CHANGED: StringName = \
	&"hydra.ai.conversation.state_changed"
const EVENT_COMPLETION_RECEIVED: StringName = \
	&"hydra.ai.conversation.completion_received"
const EVENT_EXECUTION_FAILED: StringName = \
	&"hydra.ai.conversation.execution_failed"

#endregion


#region State

var _title: String
var _messages: Array[AiMessage] = []
var _execution_state: AiExecutionState.Value = \
	AiExecutionState.Value.IDLE
var _last_error: DomainError
var _total_input_tokens: int = 0
var _total_output_tokens: int = 0

#endregion


#region Construction

## Creates an empty AI conversation.
func _init(
	id: EntityId,
	title: String = "NEW CONVERSATION"
) -> void:
	super(id)

	_title = title.strip_edges()

	if _title.is_empty():
		_title = "NEW CONVERSATION"

#endregion


#region Public API

func get_title() -> String:
	return _title


func get_messages() -> Array[AiMessage]:
	return _messages.duplicate()


func get_execution_state() -> AiExecutionState.Value:
	return _execution_state


func get_last_error() -> DomainError:
	return _last_error


func get_total_input_tokens() -> int:
	return _total_input_tokens


func get_total_output_tokens() -> int:
	return _total_output_tokens


## Adds a message to the conversation.
func add_message(message: AiMessage) -> Result:
	if message == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI conversation message cannot be null."
			)
		)

	_messages.append(message)
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_MESSAGE_ADDED,
			{
				&"conversation_id": get_id().as_string(),
				&"message_id": message.get_message_id(),
				&"role": AiMessageRole.to_string_name(
					message.get_role()
				),
			}
		)
	)

	return Result.success(message)


## Marks the conversation as queued.
func queue_execution() -> Result:
	return _transition(
		AiExecutionState.Value.QUEUED,
		[
			AiExecutionState.Value.IDLE,
			AiExecutionState.Value.COMPLETED,
			AiExecutionState.Value.CANCELLED,
			AiExecutionState.Value.FAILED,
		]
	)


## Marks generation as active.
func start_generation() -> Result:
	return _transition(
		AiExecutionState.Value.GENERATING,
		[AiExecutionState.Value.QUEUED]
	)


## Applies a successful provider response.
func complete(
	response: AiCompletionResponse
) -> Result:
	if response == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI completion response cannot be null."
			)
		)

	if _execution_state != AiExecutionState.Value.GENERATING:
		return _invalid_transition(
			AiExecutionState.Value.COMPLETED
		)

	var message_result := add_message(response.get_message())

	if message_result.is_failure():
		return message_result

	_total_input_tokens += response.get_input_tokens()
	_total_output_tokens += response.get_output_tokens()
	_last_error = null
	_execution_state = AiExecutionState.Value.COMPLETED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_COMPLETION_RECEIVED,
			{
				&"conversation_id": get_id().as_string(),
				&"response_id": response.get_response_id(),
				&"provider_id": response.get_provider_id(),
				&"model_id": response.get_model_id(),
				&"input_tokens": response.get_input_tokens(),
				&"output_tokens": response.get_output_tokens(),
				&"finish_reason": response.get_finish_reason(),
			}
		)
	)

	_record_state_event()

	return Result.success(response)


## Cancels the current request.
func cancel() -> Result:
	if _execution_state == AiExecutionState.Value.CANCELLED:
		return Result.success()

	_execution_state = AiExecutionState.Value.CANCELLED
	increment_version()
	_record_state_event()

	return Result.success()


## Records a structured execution failure.
func fail(error: DomainError) -> Result:
	if error == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI execution failure cannot be null."
			)
		)

	_last_error = error
	_execution_state = AiExecutionState.Value.FAILED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_EXECUTION_FAILED,
			{
				&"conversation_id": get_id().as_string(),
				&"error": error.to_dictionary(),
			}
		)
	)

	_record_state_event()

	return Result.success()

#endregion


#region Private methods

func _transition(
	next_state: AiExecutionState.Value,
	allowed_states: Array[AiExecutionState.Value]
) -> Result:
	if _execution_state not in allowed_states:
		return _invalid_transition(next_state)

	_execution_state = next_state
	increment_version()
	_record_state_event()

	return Result.success()


func _invalid_transition(
	next_state: AiExecutionState.Value
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"AI conversation state transition is invalid.",
			{
				&"current_state":
					AiExecutionState.to_string_name(
						_execution_state
					),
				&"requested_state":
					AiExecutionState.to_string_name(
						next_state
					),
			}
		)
	)


func _record_state_event() -> void:
	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_CHANGED,
			{
				&"conversation_id": get_id().as_string(),
				&"state": AiExecutionState.to_string_name(
					_execution_state
				),
			}
		)
	)

#endregion