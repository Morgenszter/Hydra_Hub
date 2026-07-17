class_name AutomationOperator
extends RefCounted
## Defines normalized condition comparison operators.


#region Values

enum Value {
	EQUALS,
	NOT_EQUALS,
	GREATER_THAN,
	GREATER_THAN_OR_EQUAL,
	LESS_THAN,
	LESS_THAN_OR_EQUAL,
	CONTAINS,
	NOT_CONTAINS,
	IS_TRUE,
	IS_FALSE,
}

#endregion


#region Public API

## Returns a stable operator identifier.
static func to_string_name(operator: Value) -> StringName:
	match operator:
		Value.EQUALS:
			return &"equals"
		Value.NOT_EQUALS:
			return &"not_equals"
		Value.GREATER_THAN:
			return &"greater_than"
		Value.GREATER_THAN_OR_EQUAL:
			return &"greater_than_or_equal"
		Value.LESS_THAN:
			return &"less_than"
		Value.LESS_THAN_OR_EQUAL:
			return &"less_than_or_equal"
		Value.CONTAINS:
			return &"contains"
		Value.NOT_CONTAINS:
			return &"not_contains"
		Value.IS_TRUE:
			return &"is_true"
		Value.IS_FALSE:
			return &"is_false"
		_:
			return &"unknown"

#endregion