class_name AutomationAction
extends ValueObject
## Represents an immutable action executed by an automation rule.


#region State

var _action_id: StringName
var _executor_id: StringName
var _action_name: StringName
var _arguments: Dictionary[StringName, Variant]
var _requires_approval: bool

#endregion


#region Construction

## Creates an automation action.
func _init(
	action_id: StringName,
	executor_id: StringName,
	action_name: StringName,
	arguments: Dictionary[StringName, Variant] = {},
	requires_approval: bool = false
) -> void:
	assert(
		not action_id.is_empty(),
		"AutomationAction requires action_id."
	)
	assert(
		not executor_id.is_empty(),
		"AutomationAction requires executor_id."
	)
	assert(
		not action_name.is_empty(),
		"AutomationAction requires action_name."
	)

	_action_id = action_id
	_executor_id = executor_id
	_action_name = action_name
	_arguments = arguments.duplicate(true)
	_requires_approval = requires_approval

#endregion


#region Public API

func get_action_id() -> StringName:
	return _action_id


func get_executor_id() -> StringName:
	return _executor_id


func get_action_name() -> StringName:
	return _action_name


func get_arguments() -> Dictionary[StringName, Variant]:
	return _arguments.duplicate(true)


func requires_approval() -> bool:
	return _requires_approval

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_action_id,
		_executor_id,
		_action_name,
		_arguments,
		_requires_approval,
	]

#endregion