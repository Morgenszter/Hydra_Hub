class_name AutomationConditionTest
extends RefCounted
## Provides AutomationCondition tests.


#region Tests

static func run() -> void:
	var greater_condition := AutomationCondition.new(
		&"temperature",
		&"temperature",
		AutomationOperator.Value.GREATER_THAN,
		25.0
	)

	assert(
		greater_condition.evaluate(
			{&"temperature": 27.0}
		)
	)
	assert(
		not greater_condition.evaluate(
			{&"temperature": 22.0}
		)
	)

	var contains_condition := AutomationCondition.new(
		&"status",
		&"status",
		AutomationOperator.Value.CONTAINS,
		"ALERT"
	)

	assert(
		contains_condition.evaluate(
			{&"status": "CRITICAL ALERT"}
		)
	)

#endregion