class_name AiConversationTest
extends RefCounted
## Provides AiConversation aggregate tests.


#region Tests

static func run() -> void:
	var conversation := AiConversation.new(
		EntityId.generate(),
		"TEST CONVERSATION"
	)
	var message := AiMessage.new(
		AiMessageRole.Value.USER,
		"Test request."
	)

	assert(conversation.add_message(message).is_success())
	assert(conversation.get_messages().size() == 1)
	assert(conversation.queue_execution().is_success())
	assert(conversation.start_generation().is_success())
	assert(
		conversation.get_execution_state()
		== AiExecutionState.Value.GENERATING
	)
	assert(not conversation.pull_domain_events().is_empty())

#endregion