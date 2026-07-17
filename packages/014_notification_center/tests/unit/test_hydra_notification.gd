class_name HydraNotificationTest
extends RefCounted
## Provides HydraNotification lifecycle tests.


#region Tests

static func run() -> void:
	var request := NotificationRequest.new(
		&"test",
		&"system",
		"TEST",
		"Test notification.",
		NotificationPriority.Value.NORMAL,
		5.0
	)
	var notification := HydraNotification.new(
		EntityId.generate(),
		request
	)

	assert(notification.deliver().is_success())
	assert(
		notification.get_state()
		== NotificationState.Value.DELIVERED
	)
	assert(notification.acknowledge().is_success())
	assert(
		notification.get_state()
		== NotificationState.Value.ACKNOWLEDGED
	)

#endregion