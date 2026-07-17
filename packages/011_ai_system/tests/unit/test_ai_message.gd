class_name AiMessageTest
extends RefCounted
## Provides AiMessage value-object tests.


#region Tests

static func run() -> void:
	var message := AiMessage.new(
		AiMessageRole.Value.USER,
		"System status."
	)

	assert(not message.get_message_id().is_empty())
	assert(message.get_role() == AiMessageRole.Value.USER)
	assert(message.get_content() == "System status.")
	assert(message.to_dictionary()[&"role"] == &"user")

#endregion