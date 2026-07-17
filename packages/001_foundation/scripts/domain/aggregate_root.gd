@abstract
class_name AggregateRoot
extends DomainEntity
## Base class for domain consistency boundaries.


#region State

var _domain_events: Array[DomainEvent] = []
var _version: int = 0

#endregion


#region Construction

func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

func get_version() -> int:
	return _version


func increment_version() -> void:
	_version += 1


func pull_domain_events() -> Array[DomainEvent]:
	var events := _domain_events.duplicate()
	_domain_events.clear()

	return events

#endregion


#region Protected API

func _record_domain_event(event: DomainEvent) -> void:
	assert(event != null, "DomainEvent cannot be null.")
	_domain_events.append(event)

#endregion