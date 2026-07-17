class_name HydraEventBus
extends EventBusPort
## In-memory EventBus implementation used by the desktop runtime.


#region State

var _subscribers: Dictionary[StringName, Array] = {}

#endregion


#region Public API

func publish(event: DomainEvent) -> void:
	if event == null:
		return

	var event_name := event.get_event_name()
	var handlers: Array = _subscribers.get(event_name, []).duplicate()

	for handler: Callable in handlers:
		if handler.is_valid():
			handler.call(event)


func subscribe(
	event_name: StringName,
	handler: Callable
) -> Result:
	if event_name.is_empty() or not handler.is_valid():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Event subscription is invalid."
			)
		)

	if not _subscribers.has(event_name):
		_subscribers[event_name] = []

	var handlers: Array = _subscribers[event_name]

	if handler not in handlers:
		handlers.append(handler)

	return Result.success()


func unsubscribe(
	event_name: StringName,
	handler: Callable
) -> Result:
	if not _subscribers.has(event_name):
		return Result.success()

	var handlers: Array = _subscribers[event_name]
	handlers.erase(handler)

	if handlers.is_empty():
		_subscribers.erase(event_name)

	return Result.success()

#endregion