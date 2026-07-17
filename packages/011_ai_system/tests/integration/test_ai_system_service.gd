class_name AiSystemServiceTest
extends RefCounted
## Provides AI System service composition tests.


#region Tests

static func run() -> void:
	var service := AiSystemService.new()
	var configuration := AiSystemConfiguration.new()
	var provider := LocalDemoAiProvider.new()

	assert(service.configure(configuration).is_success())
	assert(service.register_provider(provider).is_success())

	var conversation_result := service.create_conversation(
		"TEST"
	)

	assert(conversation_result.is_success())

#endregion