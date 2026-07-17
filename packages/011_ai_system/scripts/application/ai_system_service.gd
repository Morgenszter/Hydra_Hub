class_name AiSystemService
extends Node
## Coordinates AI conversations and provider execution.


#region Signals

signal conversation_created(conversation: AiConversation)
signal message_added(
	conversation: AiConversation,
	message: AiMessage
)
signal execution_state_changed(
	conversation: AiConversation,
	state: AiExecutionState.Value
)
signal completion_received(
	conversation: AiConversation,
	response: AiCompletionResponse
)
signal execution_failed(
	conversation: AiConversation,
	error: DomainError
)

#endregion


#region State

var _configuration: AiSystemConfiguration
var _providers: Dictionary[StringName, AiModelProviderPort] = {}
var _conversations: Dictionary[StringName, AiConversation] = {}
var _active_conversation_id: StringName = &""
var _active_request_id: StringName = &""

#endregion


#region Public API

## Configures AI System.
func configure(
	configuration: AiSystemConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI System configuration cannot be null."
			)
		)

	if configuration.provider_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"AI System configuration requires provider_id."
			)
		)

	if configuration.model_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"AI System configuration requires model_id."
			)
		)

	_configuration = configuration

	return Result.success()


## Registers an AI model provider.
func register_provider(
	provider: AiModelProviderPort
) -> Result:
	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI model provider cannot be null."
			)
		)

	var provider_id := provider.get_provider_id()

	if provider_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"AI model provider requires provider_id."
			)
		)

	if _providers.has(provider_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_ALREADY_REGISTERED,
				"AI model provider is already registered.",
				{&"provider_id": provider_id}
			)
		)

	_providers[provider_id] = provider

	return Result.success()


## Creates and activates a conversation.
func create_conversation(
	title: String = "NEW CONVERSATION"
) -> Result:
	if _configuration == null:
		return _not_configured()

	var conversation := AiConversation.new(
		EntityId.generate(),
		title
	)
	var conversation_id := conversation.get_id().get_value()

	_conversations[conversation_id] = conversation
	_active_conversation_id = conversation_id

	if not _configuration.system_prompt.strip_edges().is_empty():
		var system_message := AiMessage.new(
			AiMessageRole.Value.SYSTEM,
			_configuration.system_prompt
		)
		conversation.add_message(system_message)
		message_added.emit(conversation, system_message)

	_publish_events(conversation)
	conversation_created.emit(conversation)

	return Result.success(conversation)


## Sends a user message through the configured provider.
func send_message(
	content: String
) -> Result:
	if _configuration == null:
		return _not_configured()

	if content.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI user message cannot be empty."
			)
		)

	var provider := _providers.get(
		_configuration.provider_id
	) as AiModelProviderPort

	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Configured AI provider is not registered.",
				{&"provider_id": _configuration.provider_id}
			)
		)

	if not provider.is_available():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Configured AI provider is unavailable.",
				{&"provider_id": provider.get_provider_id()}
			)
		)

	if (
		provider.uses_external_processing()
		and not _configuration.allow_external_processing
	):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"External AI processing is disabled.",
				{&"provider_id": provider.get_provider_id()}
			)
		)

	var conversation := get_active_conversation()

	if conversation == null:
		var creation_result := create_conversation()

		if creation_result.is_failure():
			return creation_result

		conversation = creation_result.get_value()

	var user_message := AiMessage.new(
		AiMessageRole.Value.USER,
		content
	)
	var message_result := conversation.add_message(user_message)

	if message_result.is_failure():
		return message_result

	message_added.emit(conversation, user_message)

	var queue_result := conversation.queue_execution()

	if queue_result.is_failure():
		return queue_result

	_emit_state(conversation)

	var request_messages := _build_context_messages(conversation)
	var request := AiCompletionRequest.new(
		conversation.get_id().get_value(),
		_configuration.model_id,
		request_messages,
		_configuration.maximum_output_tokens,
		_configuration.temperature,
		_configuration.top_p
	)

	_active_request_id = request.get_request_id()

	var generation_result := conversation.start_generation()

	if generation_result.is_failure():
		return generation_result

	_emit_state(conversation)
	_publish_events(conversation)

	var completion_result := provider.complete(request)
	_active_request_id = &""

	if completion_result.is_failure():
		var error := completion_result.get_error()
		conversation.fail(error)
		_publish_events(conversation)
		_emit_state(conversation)
		execution_failed.emit(conversation, error)

		return completion_result

	var response := (
		completion_result.get_value()
		as AiCompletionResponse
	)

	var conversation_result := conversation.complete(response)

	if conversation_result.is_failure():
		return conversation_result

	_publish_events(conversation)
	_emit_state(conversation)
	message_added.emit(
		conversation,
		response.get_message()
	)
	completion_received.emit(conversation, response)

	return Result.success(response)


## Cancels the active request.
func cancel_active_request() -> Result:
	var conversation := get_active_conversation()

	if conversation == null:
		return Result.success()

	if not _active_request_id.is_empty():
		var provider := _providers.get(
			_configuration.provider_id
		) as AiModelProviderPort

		if provider != null:
			provider.cancel(_active_request_id)

	_active_request_id = &""
	conversation.cancel()
	_publish_events(conversation)
	_emit_state(conversation)

	return Result.success()


## Returns the active conversation.
func get_active_conversation() -> AiConversation:
	if _active_conversation_id.is_empty():
		return null

	return _conversations.get(_active_conversation_id)


## Returns all conversations.
func get_conversations() -> Array[AiConversation]:
	var result: Array[AiConversation] = []

	for conversation: AiConversation in _conversations.values():
		result.append(conversation)

	return result

#endregion


#region Private methods

func _build_context_messages(
	conversation: AiConversation
) -> Array[AiMessage]:
	var messages := conversation.get_messages()
	var maximum_messages := _configuration.maximum_history_messages

	if messages.size() <= maximum_messages:
		return messages

	var result: Array[AiMessage] = []

	if _configuration.preserve_system_messages:
		for message in messages:
			if message.get_role() == AiMessageRole.Value.SYSTEM:
				result.append(message)

	var start_index := maxi(
		0,
		messages.size() - maximum_messages
	)

	for index in range(start_index, messages.size()):
		var message := messages[index]

		if message not in result:
			result.append(message)

	return result


func _emit_state(
	conversation: AiConversation
) -> void:
	execution_state_changed.emit(
		conversation,
		conversation.get_execution_state()
	)


func _publish_events(
	conversation: AiConversation
) -> void:
	var events := conversation.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"AI System is not configured."
		)
	)

#endregion