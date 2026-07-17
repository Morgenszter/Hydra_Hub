class_name DebugToolsServiceTest
extends RefCounted
## Provides Debug Tools service composition tests.


#region Tests

static func run() -> void:
	var service := DebugToolsService.new()
	var configuration := DebugToolsConfiguration.new()
	var registry := DebugCommandRegistry.new()

	assert(
		service.configure(
			configuration,
			registry
		).is_success()
	)

#endregion