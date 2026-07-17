class_name NotificationToast
extends WidgetBase
## Displays one transient notification.


#region Signals

signal acknowledged(notification_id: StringName)
signal dismissed(notification_id: StringName)

#endregion


#region Nodes

@onready var _indicator: ColorRect = %Indicator
@onready var _title_label: RichTextLabel = %TitleLabel
@onready var _message_label: RichTextLabel = %MessageLabel
@onready var _priority_label: RichTextLabel = %PriorityLabel

#endregion


#region State

var _notification: HydraNotification

#endregion


#region Public API

## Applies a notification.
func apply_notification(
	notification: HydraNotification
) -> void:
	assert(
		notification != null,
		"NotificationToast requires notification."
	)

	_notification = notification

	if not is_node_ready():
		return

	var request := notification.get_request()
	var priority := request.get_priority()

	_indicator.color = NotificationPriority.to_color(priority)
	_title_label.text = request.get_title()
	_message_label.text = request.get_message()
	_priority_label.text = String(
		NotificationPriority.to_string_name(priority)
	).to_upper()


## Emits an acknowledgement request.
func request_acknowledgement() -> void:
	if _notification != null:
		acknowledged.emit(
			_notification.get_id().get_value()
		)


## Emits a dismissal request.
func request_dismissal() -> void:
	if _notification != null:
		dismissed.emit(
			_notification.get_id().get_value()
		)

#endregion