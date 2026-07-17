class_name AutomationCondition
extends ValueObject
## Represents an immutable condition evaluated against execution context.


#region State

var _condition_id: StringName
var _property_path: StringName
var _operator: AutomationOperator.Value
var _expected_value: Variant

#endregion


#region Construction

## Creates an automation condition.
func _init(
	condition_id: StringName,
	property_path: StringName,
	operator: AutomationOperator.Value,
	expected_value: Variant = null
) -> void:
	assert(
		not condition_id.is_empty(),
		"AutomationCondition requires condition_id."
	)
	assert(
		not property_path.is_empty(),
		"AutomationCondition requires property_path."
	)

	_condition_id = condition_id
	_property_path = property_path
	_operator = operator
	_expected_value = expected_value

#endregion


#region Public API

func get_condition_id() -> StringName:
	return _condition_id


func get_property_path() -> StringName:
	return _property_path


func get_operator() -> AutomationOperator.Value:
	return _operator


func get_expected_value() -> Variant:
	return _expected_value


## Evaluates this condition against flattened execution data.
func evaluate(
	values: Dictionary[StringName, Variant]
) -> bool:
	if not values.has(_property_path):
		return false

	var actual_value: Variant = values[_property_path]

	match _operator:
		AutomationOperator.Value.EQUALS:
			return actual_value == _expected_value
		AutomationOperator.Value.NOT_EQUALS:
			return actual_value != _expected_value
		AutomationOperator.Value.GREATER_THAN:
			return _compare_numbers(actual_value, _expected_value, 1)
		AutomationOperator.Value.GREATER_THAN_OR_EQUAL:
			return _compare_numbers(actual_value, _expected_value, 2)
		AutomationOperator.Value.LESS_THAN:
			return _compare_numbers(actual_value, _expected_value, -1)
		AutomationOperator.Value.LESS_THAN_OR_EQUAL:
			return _compare_numbers(actual_value, _expected_value, -2)
		AutomationOperator.Value.CONTAINS:
			return String(actual_value).contains(String(_expected_value))
		AutomationOperator.Value.NOT_CONTAINS:
			return not String(actual_value).contains(
				String(_expected_value)
			)
		AutomationOperator.Value.IS_TRUE:
			return bool(actual_value)
		AutomationOperator.Value.IS_FALSE:
			return not bool(actual_value)
		_:
			return false

#endregion


#region Private methods

func _compare_numbers(
	actual_value: Variant,
	expected_value: Variant,
	mode: int
) -> bool:
	if (
		not actual_value is int
		and not actual_value is float
	):
		return false

	if (
		not expected_value is int
		and not expected_value is float
	):
		return false

	var actual := float(actual_value)
	var expected := float(expected_value)

	match mode:
		1:
			return actual > expected
		2:
			return actual >= expected
		-1:
			return actual < expected
		-2:
			return actual <= expected
		_:
			return false

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_condition_id,
		_property_path,
		_operator,
		_expected_value,
	]

#endregion