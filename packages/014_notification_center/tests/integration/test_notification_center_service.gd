class_name NotificationCenterServiceTest
extends RefCounted
## Provides Notification Center composition tests.


#region Tests

static func run() -> void:
	var service := NotificationCenterService.new()
	var configuration := NotificationConfiguration.new()
	var repository := InMemoryNotificationRepository.new()

	assert(
		service.configure(
			configuration,
			repository
		).is_success()
	)

#endregion