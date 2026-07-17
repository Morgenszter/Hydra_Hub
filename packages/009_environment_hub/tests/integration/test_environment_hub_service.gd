class_name EnvironmentHubServiceTest
extends RefCounted
## Provides Environment Hub service composition tests.


#region Tests

static func run() -> void:
	var service := EnvironmentHubService.new()
	var configuration := EnvironmentHubConfiguration.new()
	configuration.thresholds = EnvironmentThresholds.new()
	var provider := DemoEnvironmentProvider.new()

	var result := service.configure(
		configuration,
		provider
	)

	assert(result.is_success())

#endregion