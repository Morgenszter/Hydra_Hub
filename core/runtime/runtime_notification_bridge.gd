class_name RuntimeNotificationBridge
extends Node
## Converts selected domain events into user-facing notifications.


#region State

var _event_bus: Node
var _notification_center: NotificationCenterService

#endregion


#region Lifecycle

func _ready() -> void:
	_event_bus = get_node_or_null("/root/EventBus")
	_notification_center = get_node_or_null(
		"/root/NotificationCenter"
	) as NotificationCenterService

	if _event_bus == null or _notification_center == null:
		return

	if _event_bus.has_signal("event_published"):
		_event_bus.event_published.connect(
			_on_event_published
		)

#endregion


#region Event handling

func _on_event_published(event: DomainEvent) -> void:
	if event == null:
		return

	match event.get_event_name():
		&"hydra.device.connection_changed":
			_notify_device_connection(event)

		&"hydra.automation.execution.failed":
			_notify_automation_failure(event)

		&"hydra.ai.conversation.execution_failed":
			_notify_ai_failure(event)

		&"hydra.boot.step_failed":
			_notify_boot_failure(event)

#endregion


#region Notification mapping

func _notify_device_connection(event: DomainEvent) -> void:
	var current_state := String(
		event.get_payload_value(
			&"current_state",
			&"unknown"
		)
	)

	if current_state != "offline" and current_state != "error":
		return

	_submit(
		&"device_hub",
		&"device",
		"DEVICE LINK DEGRADED",
		"Device %s entered state %s."
		% [
			event.get_payload_value(
				&"device_id",
				&"unknown"
			),
			current_state.to_upper(),
		],
		NotificationPriority.Value.HIGH
	)


func _notify_automation_failure(event: DomainEvent) -> void:
	_submit(
		&"automation",
		&"automation",
		"AUTOMATION FAILURE",
		"Rule %s failed during execution."
		% event.get_payload_value(
			&"rule_id",
			&"unknown"
		),
		NotificationPriority.Value.URGENT
	)


func _notify_ai_failure(_event: DomainEvent) -> void:
	_submit(
		&"ai_system",
		&"ai",
		"AI LINK FAILURE",
		"The active AI request failed.",
		NotificationPriority.Value.HIGH
	)


func _notify_boot_failure(_event: DomainEvent) -> void:
	_submit(
		&"boot_loader",
		&"system",
		"BOOT SEQUENCE FAILURE",
		"A startup component reported a failure.",
		NotificationPriority.Value.CRITICAL
	)


func _submit(
	source_id: StringName,
	category: StringName,
	title: String,
	message: String,
	priority: NotificationPriority.Value
) -> void:
	if _notification_center == null:
		return

	_notification_center.notify(
		NotificationRequest.new(
			source_id,
			category,
			title,
			message,
			priority,
			10.0
		)
	)

#endregion