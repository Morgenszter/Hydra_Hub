class_name AutomationServiceTest
extends RefCounted
## Provides Automation service composition tests.


#region Tests

static func run() -> void:
	var service := AutomationService.new()
	var configuration := AutomationConfiguration.new()
	var repository := InMemoryAutomationRuleRepository.new()
	var executor := DemoAutomationActionExecutor.new()

	assert(
		service.configure(
			configuration,
			repository
		).is_success()
	)
	assert(service.register_executor(executor).is_success())

#endregion