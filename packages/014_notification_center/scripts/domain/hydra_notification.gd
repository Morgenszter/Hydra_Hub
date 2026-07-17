class_name HydraNotification
extends AggregateRoot
## Owns one notification lifecycle.


#region Events

const EVENT_CREATED: StringName = \
	&"hydra.notification.created"
const EVENT_DELIVERED: StringName = \
	&"hydra.notification.delivered"
const EVENT_ACKNOWLEDGED: StringName = \
	&"hydra.notification.acknowledged"
const EVENT_EXPIRED: StringName = \
	&"hydra.notification.expired"
const EVENT_DISMISSED: StringName = \
	&"hydra.notification.dismissed"

#endregion


#region State

var _request: NotificationRequest
var _state: NotificationState.Value = NotificationState.Value.PENDING
var _created_at_unix_ms: int
var _delivered_at_unix_ms: int = 0
var _completed_at_unix_ms: int = 0

#endregion


#region Construction

## Creates a notification aggregate.
func _init(
	id: EntityId,
	request: NotificationRequest
) -> void:
	super(id)

	assert(
		request != null,
		"HydraNotification requires request."
	)

	_request = request
	_created_at_unix_ms = _now()

	_record_domain_event(
		DomainEvent.new(
			EVENT_CREATED,
			{
				&"notification_id": get_id().as_string(),
				&"source_id": request.get_source_id(),
				&"priority":
					NotificationPriority.to_string_name(
						request.get_priority()
					),
			}
		)
	)

#endregion


#region Public API

func get_request() -> NotificationRequest:
	return _request


func get_state() -> NotificationState.Value:
	return _state


func get_created_at_unix_ms() -> int:
	return _created_at_unix_ms


func get_delivered_at_unix_ms() -> int:
	return _delivered_at_unix_ms


func get_completed_at_unix_ms() -> int:
	return _completed_at_unix_ms


## Marks the notification as delivered.
func deliver() -> Result:
	if _state != NotificationState.Value.PENDING:
		return _invalid_state("deliver")

	_state = NotificationState.Value.DELIVERED
	_delivered_at_unix_ms = _now()
	increment_version()
	_record_state_event(EVENT_DELIVERED)

	return Result.success()


## Acknowledges the notification.
func acknowledge() -> Result:
	if _state not in [
		NotificationState.Value.DELIVERED,
		NotificationState.Value.EXPIRED,
	]:
		return _invalid_state("acknowledge")

	_state = NotificationState.Value.ACKNOWLEDGED
	_completed_at_unix_ms = _now()
	increment_version()
	_record_state_event(EVENT_ACKNOWLEDGED)

	return Result.success()


## Expires the notification.
func expire() -> Result:
	if _state != NotificationState.Value.DELIVERED:
		return _invalid_state("expire")

	_state = NotificationState.Value.EXPIRED
	_completed_at_unix_ms = _now()
	increment_version()
	_record_state_event(EVENT_EXPIRED)

	return Result.success()


## Dismisses the notification.
func dismiss() -> Result:
	if _state == NotificationState.Value.DISMISSED:
		return Result.success()

	_state = NotificationState.Value.DISMISSED
	_completed_at_unix_ms = _now()
	increment_version()
	_record_state_event(EVENT_DISMISSED)

	return Result.success()

#endregion


#region Private methods

func _record_state_event(
	event_name: StringName
) -> void:
	_record_domain_event(
		DomainEvent.new(
			event_name,
			{
				&"notification_id": get_id().as_string(),
				&"state": NotificationState.to_string_name(_state),
			}
		)
	)


func _invalid_state(
	operation: String
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Notification operation is invalid.",
			{
				&"operation": operation,
				&"state": NotificationState.to_string_name(_state),
			}
		)
	)


func _now() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)

#endregion