class_name NotificationConfiguration
extends Resource
## Stores Notification Center runtime configuration.


#region Retention

@export_group("Retention")
@export_range(1, 10000, 1) var maximum_history: int = 500
@export_range(1.0, 86400.0, 1.0) var default_duration_seconds: float = 8.0

#endregion


#region Behavior

@export_group("Behavior")
@export var automatically_expire_notifications: bool = true
@export var automatically_acknowledge_expired: bool = false
@export var play_notification_audio: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export_range(1, 10, 1) var maximum_visible_toasts: int = 4
@export var show_acknowledged_notifications: bool = true

#endregion