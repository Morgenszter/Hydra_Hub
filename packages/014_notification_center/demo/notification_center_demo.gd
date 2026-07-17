class_name NotificationCenterDemo
extends Control
## Demonstrates Notification Center.


#region Nodes

@onready var _panel: NotificationCenterPanel = %NotificationCenterPanel

#endregion


#region State

var _service: NotificationCenterService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = NotificationCenterService.new()
	_service.name = "NotificationCenterService"
	add_child(_service)

	var configuration := NotificationConfiguration.new()
	var repository := InMemoryNotificationRepository.new()

	_service.configure(configuration, repository)
	_panel.bind_service(_service)

	_service.notify(
		NotificationRequest.new(
			&"diagnostics",
			&"system",
			"SYSTEM ONLINE",
			"HYDRA core services are operational.",
			NotificationPriority.Value.NORMAL,
			12.0
		)
	)

	_service.notify(
		NotificationRequest.new(
			&"security",
			&"security",
			"SECURITY CHANNEL",
			"Perimeter monitoring is active.",
			NotificationPriority.Value.HIGH,
			16.0
		)
	)

#endregion