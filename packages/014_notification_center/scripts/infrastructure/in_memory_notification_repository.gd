class_name InMemoryNotificationRepository
extends NotificationRepositoryPort
## Stores notifications in memory.


#region State

var _notifications: Dictionary[StringName, HydraNotification] = {}

#endregion


#region NotificationRepositoryPort

func save(notification: HydraNotification) -> Result:
	if notification == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Notification cannot be null."
			)
		)

	_notifications[
		notification.get_id().get_value()
	] = notification

	return Result.success(notification)


func find_by_id(notification_id: StringName) -> Result:
	var notification := _notifications.get(
		notification_id
	) as HydraNotification

	if notification == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Notification was not found.",
				{&"notification_id": notification_id}
			)
		)

	return Result.success(notification)


func find_all() -> Result:
	var result: Array[HydraNotification] = []

	for notification: HydraNotification in _notifications.values():
		result.append(notification)

	result.sort_custom(
		func(left: HydraNotification, right: HydraNotification) -> bool:
			return (
				left.get_created_at_unix_ms()
				> right.get_created_at_unix_ms()
			)
	)

	return Result.success(result)


func remove(notification_id: StringName) -> Result:
	_notifications.erase(notification_id)

	return Result.success()

#endregion