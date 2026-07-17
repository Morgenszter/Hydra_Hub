class_name AutomationRule
extends AggregateRoot
## Owns one automation rule and its lifecycle.


#region Events

const EVENT_CREATED: StringName = &"hydra.automation.rule.created"
const EVENT_STATE_CHANGED: StringName = \
	&"hydra.automation.rule.state_changed"
const EVENT_EXECUTION_STARTED: StringName = \
	&"hydra.automation.execution.started"
const EVENT_EXECUTION_COMPLETED: StringName = \
	&"hydra.automation.execution.completed"
const EVENT_EXECUTION_FAILED: StringName = \
	&"hydra.automation.execution.failed"

#endregion


#region State

var _rule_id: StringName
var _display_name: String
var _description: String
var _state: AutomationRuleState.Value = AutomationRuleState.Value.DRAFT
var _trigger: AutomationTrigger
var _conditions: Array[AutomationCondition] = []
var _actions: Array[AutomationAction] = []
var _cooldown_seconds: float = 0.0
var _last_executed_at_unix_ms: int = 0
var _execution_count: int = 0

#endregion


#region Construction

## Creates an automation rule.
func _init(
	id: EntityId,
	rule_id: StringName,
	display_name: String,
	description: String,
	trigger: AutomationTrigger,
	conditions: Array[AutomationCondition],
	actions: Array[AutomationAction],
	cooldown_seconds: float
) -> void:
	super(id)

	assert(not rule_id.is_empty(), "AutomationRule requires rule_id.")
	assert(
		not display_name.strip_edges().is_empty(),
		"AutomationRule requires display_name."
	)
	assert(
		trigger != null,
		"AutomationRule requires trigger."
	)
	assert(
		not actions.is_empty(),
		"AutomationRule requires at least one action."
	)
	assert(
		cooldown_seconds >= 0.0,
		"AutomationRule cooldown cannot be negative."
	)

	_rule_id = rule_id
	_display_name = display_name.strip_edges()
	_description = description.strip_edges()
	_trigger = trigger
	_conditions = conditions.duplicate()
	_actions = actions.duplicate()
	_cooldown_seconds = cooldown_seconds

	_record_domain_event(
		DomainEvent.new(
			EVENT_CREATED,
			{
				&"rule_id": _rule_id,
				&"display_name": _display_name,
			}
		)
	)

#endregion


#region Public API

func get_rule_id() -> StringName:
	return _rule_id


func get_display_name() -> String:
	return _display_name


func get_description() -> String:
	return _description


func get_state() -> AutomationRuleState.Value:
	return _state


func get_trigger() -> AutomationTrigger:
	return _trigger


func get_conditions() -> Array[AutomationCondition]:
	return _conditions.duplicate()


func get_actions() -> Array[AutomationAction]:
	return _actions.duplicate()


func get_cooldown_seconds() -> float:
	return _cooldown_seconds


func get_last_executed_at_unix_ms() -> int:
	return _last_executed_at_unix_ms


func get_execution_count() -> int:
	return _execution_count


## Enables this rule.
func enable() -> Result:
	return _set_state(AutomationRuleState.Value.ENABLED)


## Disables this rule.
func disable() -> Result:
	return _set_state(AutomationRuleState.Value.DISABLED)


## Suspends this rule.
func suspend() -> Result:
	return _set_state(AutomationRuleState.Value.SUSPENDED)


## Marks this rule as failed.
func mark_failed() -> Result:
	return _set_state(AutomationRuleState.Value.FAILED)


## Returns whether this rule can respond to an event.
func matches(event: DomainEvent) -> bool:
	return (
		_state == AutomationRuleState.Value.ENABLED
		and _trigger.matches(event)
	)


## Returns whether all conditions are satisfied.
func conditions_satisfied(
	values: Dictionary[StringName, Variant]
) -> bool:
	for condition in _conditions:
		if not condition.evaluate(values):
			return false

	return true


## Returns whether cooldown has expired.
func cooldown_expired(
	current_time_unix_ms: int
) -> bool:
	if _last_executed_at_unix_ms <= 0:
		return true

	var elapsed_seconds := (
		float(
			current_time_unix_ms
			- _last_executed_at_unix_ms
		)
		/ 1000.0
	)

	return elapsed_seconds >= _cooldown_seconds


## Records execution start.
func record_execution_started(
	context: AutomationExecutionContext
) -> void:
	_record_domain_event(
		DomainEvent.new(
			EVENT_EXECUTION_STARTED,
			{
				&"rule_id": _rule_id,
				&"execution_id": context.get_execution_id(),
			}
		)
	)


## Records successful execution.
func record_execution_completed(
	record: AutomationExecutionRecord
) -> void:
	_last_executed_at_unix_ms = record.get_completed_at_unix_ms()
	_execution_count += 1
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_EXECUTION_COMPLETED,
			{
				&"rule_id": _rule_id,
				&"execution_id": record.get_execution_id(),
				&"completed_actions":
					record.get_completed_action_count(),
			}
		)
	)


## Records failed execution.
func record_execution_failed(
	record: AutomationExecutionRecord
) -> void:
	increment_version()

	var error_data: Variant = null

	if record.get_error() != null:
		error_data = record.get_error().to_dictionary()

	_record_domain_event(
		DomainEvent.new(
			EVENT_EXECUTION_FAILED,
			{
				&"rule_id": _rule_id,
				&"execution_id": record.get_execution_id(),
				&"error": error_data,
			}
		)
	)

#endregion


#region Private methods

func _set_state(
	next_state: AutomationRuleState.Value
) -> Result:
	if _state == next_state:
		return Result.success()

	var previous_state := _state
	_state = next_state
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_CHANGED,
			{
				&"rule_id": _rule_id,
				&"previous_state":
					AutomationRuleState.to_string_name(
						previous_state
					),
				&"current_state":
					AutomationRuleState.to_string_name(
						next_state
					),
			}
		)
	)

	return Result.success()

#endregion