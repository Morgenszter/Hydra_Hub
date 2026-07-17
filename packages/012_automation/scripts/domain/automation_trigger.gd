class_name AutomationTrigger
extends ValueObject
## Represents an immutable rule trigger definition.


#region State

var _trigger_id: StringName
var _event_name: StringName
var _filters: Dictionary[StringName, Variant]

#endregion


#region Construction

## Creates an event-based automation trigger.
func _init(
	trigger_id: StringName,
	event_name: StringName,
	filters: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not trigger_id.is_empty(),
		"AutomationTrigger requires trigger_id."
	)
	assert(
		not event_name.is_empty(),
		"AutomationTrigger requires event_name."
	)

	_trigger_id = trigger_id
	_event_name = event_name
	_filters = filters.duplicate(true)

#endregion


#region Public API

func get_trigger_id() -> StringName:
	return _trigger_id


func get_event_name() -> StringName:
	return _event_name


func get_filters() -> Dictionary[StringName, Variant]:
	return _filters.duplicate(true)


## Returns whether a domain event satisfies this trigger.
func matches(event: DomainEvent) -> bool:
	if event == null:
		return false

	if event.get_event_name() != _event_name:
		return false

	for key in _filters:
		if event.get_payload_value(key) != _filters[key]:
			return false

	return true

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_trigger_id,
		_event_name,
		_filters,
	]

#endregion