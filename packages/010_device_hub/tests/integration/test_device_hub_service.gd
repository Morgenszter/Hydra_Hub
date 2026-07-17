class_name DeviceHubServiceTest
extends RefCounted
## Provides Device Hub service composition tests.


#region Tests

static func run() -> void:
	var service := DeviceHubService.new()
	var configuration := DeviceHubConfiguration.new()
	var provider := DemoDeviceProvider.new()

	assert(service.configure(configuration).is_success())
	assert(service.register_provider(provider).is_success())

#endregion