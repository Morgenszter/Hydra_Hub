class_name NotificationCenterPanel
extends PanelBase
## Displays Notification Center history.


#region Constants

const TOAST_WIDTH: float = 760.0
const TOAST_HEIGHT: float = 126.0
const TOAST_START_X: float = 56.0
const TOAST_START_Y: float = 174.0
const TOAST_GAP: float = 18.0

#endregion


#region Nodes

@onready var _notification_layer: Control = %NotificationLayer
@onready var _summary_label: RichTextLabel = %SummaryLabel

#endregion


#region State

var _service: NotificationCenterService
var _toast_scene: PackedScene = preload(
	"res://packages/014_notification_center/scenes/notification_toast.tscn"
)

#endregion


#region Public API

## Binds the panel to Notification Center.
func bind_service(
	service: NotificationCenterService
) -> void:
	assert(
		service != null,
		"Notification Center service cannot be null."
	)

	_disconnect_service()
	_service = service

	_service.notification_created.connect(
		_on_notification_changed
	)
	_service.notification_delivered.connect(
		_on_notification_changed
	)
	_service.notification_updated.connect(
		_on_notification_changed
	)
	_service.notification_removed.connect(
		_on_notification_removed
	)

	rebuild_notifications()


## Rebuilds notification history.
func rebuild_notifications() -> void:
	if _service == null:
		return

	var notifications := _service.get_notifications()

	for child in _notification_layer.get_children():
		child.queue_free()

	for index in notifications.size():
		var toast := (
			_toast_scene.instantiate()
			as NotificationToast
		)

		toast.position = Vector2(
			TOAST_START_X,
			TOAST_START_Y + (
				index * (TOAST_HEIGHT + TOAST_GAP)
			)
		)
		toast.size = Vector2(
			TOAST_WIDTH,
			TOAST_HEIGHT
		)

		_notification_layer.add_child(toast)
		toast.apply_notification(notifications[index])
		toast.acknowledged.connect(
			_on_acknowledged
		)
		toast.dismissed.connect(_on_dismissed)

	var active_count := 0

	for notification in notifications:
		if notification.get_state() == NotificationState.Value.DELIVERED:
			active_count += 1

	_summary_label.text = (
		"NOTIFICATIONS  //  %d    ACTIVE  //  %d"
		% [
			notifications.size(),
			active_count,
		]
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.notification_created.is_connected(
		_on_notification_changed
	):
		_service.notification_created.disconnect(
			_on_notification_changed
		)

	if _service.notification_delivered.is_connected(
		_on_notification_changed
	):
		_service.notification_delivered.disconnect(
			_on_notification_changed
		)

	if _service.notification_updated.is_connected(
		_on_notification_changed
	):
		_service.notification_updated.disconnect(
			_on_notification_changed
		)

	if _service.notification_removed.is_connected(
		_on_notification_removed
	):
		_service.notification_removed.disconnect(
			_on_notification_removed
		)


func _on_notification_changed(
	_notification: HydraNotification
) -> void:
	rebuild_notifications()


func _on_notification_removed(
	_notification_id: StringName
) -> void:
	rebuild_notifications()


func _on_acknowledged(
	notification_id: StringName
) -> void:
	_service.acknowledge(notification_id)


func _on_dismissed(
	notification_id: StringName
) -> void:
	_service.dismiss(notification_id)

#endregion