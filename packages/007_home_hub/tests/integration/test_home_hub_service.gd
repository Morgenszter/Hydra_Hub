class_name HomeHubServiceTest
extends RefCounted
## Provides Home Hub service composition tests.


#region Tests

static func run() -> void:
	var service := HomeHubService.new()
	var configuration := HomeHubConfiguration.new()
	var provider := DemoHomeOverviewProvider.new()

	var result := service.configure(
		configuration,
		provider
	)

	assert(result.is_success())
	assert(service.get_overview() != null)

#endregion