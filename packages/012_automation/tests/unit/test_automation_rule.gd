class_name AutomationRuleTest
extends RefCounted
## Provides AutomationRule aggregate tests.


#region Tests

static func run() -> void:
	var trigger := AutomationTrigger.new(
		&"test_trigger",
		&"hydra.test.event"
	)
	var action := AutomationAction.new(
		&"test_action",
		&"demo",
		&"test"
	)
	var rule := AutomationRule.new(
		EntityId.generate(),
		&"test_rule",
		"TEST RULE",
		"Test automation rule.",
		trigger,
		[],
		[action],
		0.0
	)

	assert(rule.enable().is_success())
	assert(
		rule.get_state()
		== AutomationRuleState.Value.ENABLED
	)

	var event := DomainEvent.new(
		&"hydra.test.event"
	)

	assert(rule.matches(event))
	assert(rule.conditions_satisfied({}))
	assert(rule.cooldown_expired(1000))
	assert(not rule.pull_domain_events().is_empty())

#endregion