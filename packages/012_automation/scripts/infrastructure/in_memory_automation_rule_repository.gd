class_name InMemoryAutomationRuleRepository
extends AutomationRuleRepositoryPort
## Stores automation rules in memory for runtime and tests.


#region State

var _rules: Dictionary[StringName, AutomationRule] = {}

#endregion


#region AutomationRuleRepositoryPort

func save(rule: AutomationRule) -> Result:
	if rule == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Automation rule cannot be null."
			)
		)

	_rules[rule.get_rule_id()] = rule

	return Result.success(rule)


func remove(rule_id: StringName) -> Result:
	_rules.erase(rule_id)

	return Result.success()


func find_by_id(rule_id: StringName) -> Result:
	var rule := _rules.get(rule_id) as AutomationRule

	if rule == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Automation rule was not found.",
				{&"rule_id": rule_id}
			)
		)

	return Result.success(rule)


func find_all() -> Result:
	var result: Array[AutomationRule] = []

	for rule: AutomationRule in _rules.values():
		result.append(rule)

	result.sort_custom(
		func(left: AutomationRule, right: AutomationRule) -> bool:
			return left.get_display_name() < right.get_display_name()
	)

	return Result.success(result)

#endregion