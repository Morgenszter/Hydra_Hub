class_name DomainEvent
extends RefCounted
## Represents an immutable fact emitted by a domain aggregate.


#region State

var _event_id: StringName
var _event_name: StringName
var _occurred_at_unix_ms: int
var _payload: Dictionary[StringName, Variant]

#endregion


#region Construction

func _init(
	event_name: StringName,
	payload: Dictionary[StringName, Variant] = {}
) -> void:
	assert(not event_name.is_empty(), "DomainEvent name cannot be empty.")

	_event_id = StringName(UUID.v4())
	_event_name = event_name
	_occurred_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	_payload = payload.duplicate(true)

#endregion


#region Public API

func get_event_id() -> StringName:
	return _event_id


func get_event_name() -> StringName:
	return _event_name


func get_occurred_at_unix_ms() -> int:
	return _occurred_at_unix_ms


func get_payload() -> Dictionary[StringName, Variant]:
	return _payload.duplicate(true)

#endregion
