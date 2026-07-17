class_name LocalDemoAiProviderTest
extends RefCounted
## Provides deterministic local-provider tests.


#region Tests

static func run() -> void:
	var provider := LocalDemoAiProvider.new()
	var messages: Array[AiMessage] = [
		AiMessage.new(
			AiMessageRole.Value.USER,
			"Report status."
		),
	]
	var request := AiCompletionRequest.new(
		&"conversation_test",
		&"hydra-local-demo",
		messages,
		256,
		0.2,
		1.0
	)

	var result := provider.complete(request)

	assert(result.is_success())

	var response := result.get_value() as AiCompletionResponse

	assert(response != null)
	assert(response.get_provider_id() == &"local_demo")
	assert(
		response.get_message().get_role()
		== AiMessageRole.Value.ASSISTANT
	)
	assert(response.get_total_tokens() > 0)

#endregion