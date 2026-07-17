class_name NotificationCenterService
extends Node
## Coordinates notification submission and lifecycle.


#region Signals

signal notification_created(notification: HydraNotification)
signal notification_delivered(notification: HydraNotification)
signal notification_updated(notification: HydraNotification)
signal notification_removed(notification_id: StringName)

#endregion


#region State

var _configuration: NotificationConfiguration
var _repository: NotificationRepositoryPort
var _expiration_timers: Dictionary[StringName, Timer] = {}

#endregion


#region Public API

## Configures Notification Center.
func configure(
	configuration: NotificationConfiguration,
	repository: NotificationRepositoryPort
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Notification configuration cannot be null."
			)
		)

	if repository == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Notification repository cannot be null."
			)
		)

	_configuration = configuration
	_repository = repository

	return Result.success()


## Submits and delivers a notification.
func notify(
	request: NotificationRequest
) -> Result:
	if _configuration == null or _repository == null:
		return _not_configured()

	if request == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Notification request cannot be null."
			)
		)

	var notification := HydraNotification.new(
		EntityId.generate(),
		request
	)

	_repository.save(notification)
	_publish_events(notification)
	notification_created.emit(notification)

	var delivery_result := notification.deliver()

	if delivery_result.is_failure():
		return delivery_result

	_repository.save(notification)
	_publish_events(notification)
	notification_delivered.emit(notification)

	if _configuration.automatically_expire_notifications:
		_schedule_expiration(notification)

	_trim_history()

	return Result.success(notification)


## Acknowledges a notification.
func acknowledge(
	notification_id: StringName
) -> Result:
	var result := _find(notification_id)

	if result.is_failure():
		return result

	var notification := result.get_value() as HydraNotification
	var state_result := notification.acknowledge()

	if state_result.is_failure():
		return state_result

	_cancel_expiration(notification_id)
	_repository.save(notification)
	_publish_events(notification)
	notification_updated.emit(notification)

	return Result.success(notification)


## Dismisses a notification.
func dismiss(
	notification_id: StringName
) -> Result:
	var result := _find(notification_id)

	if result.is_failure():
		return result

	var notification := result.get_value() as HydraNotification
	var state_result := notification.dismiss()

	if state_result.is_failure():
		return state_result

	_cancel_expiration(notification_id)
	_repository.save(notification)
	_publish_events(notification)
	notification_updated.emit(notification)

	return Result.success(notification)


## Removes a notification from history.
func remove(
	notification_id: StringName
) -> Result:
	_cancel_expiration(notification_id)

	var result := _repository.remove(notification_id)

	if result.is_success():
		notification_removed.emit(notification_id)

	return result


## Returns all notifications.
func get_notifications() -> Array[HydraNotification]:
	if _repository == null:
		return []

	var result := _repository.find_all()

	if result.is_failure():
		return []

	return result.get_value()

#endregion


#region Private methods

func _find(notification_id: StringName) -> Result:
	if _repository == null:
		return _not_configured()

	return _repository.find_by_id(notification_id)


func _schedule_expiration(
	notification: HydraNotification
) -> void:
	var notification_id := notification.get_id().get_value()
	var duration := notification.get_request().get_duration_seconds()

	if duration <= 0.0:
		duration = _configuration.default_duration_seconds

	var timer := Timer.new()
	timer.name = "NotificationExpiration_%s" % notification_id
	timer.one_shot = true
	timer.wait_time = duration
	timer.timeout.connect(
		_on_expiration_timeout.bind(notification_id)
	)
	add_child(timer)

	_expiration_timers[notification_id] = timer
	timer.start()


func _cancel_expiration(
	notification_id: StringName
) -> void:
	var timer := _expiration_timers.get(
		notification_id
	) as Timer

	if timer == null:
		return

	timer.stop()
	timer.queue_free()
	_expiration_timers.erase(notification_id)


func _on_expiration_timeout(
	notification_id: StringName
) -> void:
	_expiration_timers.erase(notification_id)

	var result := _repository.find_by_id(notification_id)

	if result.is_failure():
		return

	var notification := result.get_value() as HydraNotification

	if notification.get_state() != NotificationState.Value.DELIVERED:
		return

	notification.expire()

	if _configuration.automatically_acknowledge_expired:
		notification.acknowledge()

	_repository.save(notification)
	_publish_events(notification)
	notification_updated.emit(notification)


func _trim_history() -> void:
	var notifications := get_notifications()

	while notifications.size() > _configuration.maximum_history:
		var oldest := notifications.pop_back()
		remove(oldest.get_id().get_value())


func _publish_events(
	notification: HydraNotification
) -> void:
	var events := notification.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Notification Center is not configured."
		)
	)

#endregion