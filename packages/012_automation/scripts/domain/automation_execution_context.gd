class_name AutomationExecutionContext
extends RefCounted
## Contains immutable data used during one rule execution.


#region State

var _execution_id: StringName
var _rule_id: StringName
var _trigger_event: DomainEvent
var _values: Dictionary[StringName, Variant]
var _correlation_id: StringName
var _recursion_depth: int
var _created_at_unix_ms: int

#endregion


#region Construction

## Creates an automation execution context.
func _init(
	rule_id: StringName,
	trigger_event: DomainEvent,
	values: Dictionary[StringName, Variant] = {},
	correlation_id: StringName = &"",
	recursion_depth: int = 0
) -> void:
	assert(
		not rule_id.is_empty(),
		"AutomationExecutionContext requires rule_id."
	)
	assert(
		recursion_depth >= 0,
		"Automation recursion depth cannot be negative."
	)

	_execution_id = StringName(UUID.v4())
	_rule_id = rule_id
	_trigger_event = trigger_event
	_values = values.duplicate(true)
	_correlation_id = correlation_id
	_recursion_depth = recursion_depth
	_created_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)

	if _correlation_id.is_empty():
		_correlation_id = _execution_id

#endregion


#region Public API

func get_execution_id() -> StringName:
	return _execution_id


func get_rule_id() -> StringName:
	return _rule_id


func get_trigger_event() -> DomainEvent:
	return _trigger_event


func get_values() -> Dictionary[StringName, Variant]:
	return _values.duplicate(true)


func get_correlation_id() -> StringName:
	return _correlation_id


func get_recursion_depth() -> int:
	return _recursion_depth


func get_created_at_unix_ms() -> int:
	return _created_at_unix_ms

#endregion