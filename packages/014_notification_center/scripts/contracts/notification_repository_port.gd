@abstract
class_name NotificationRepositoryPort
extends RefCounted
## Defines notification persistence operations.


#region Public API

@abstract
func save(notification: HydraNotification) -> Result


@abstract
func find_by_id(notification_id: StringName) -> Result


@abstract
func find_all() -> Result


@abstract
func remove(notification_id: StringName) -> Result

#endregion