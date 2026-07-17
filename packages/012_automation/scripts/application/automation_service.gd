class_name AutomationService
extends Node
## Coordinates automation rule registration and execution.


#region Signals

signal rule_registered(rule: AutomationRule)
signal rule_updated(rule: AutomationRule)
signal execution_started(
	rule: AutomationRule,
	record: AutomationExecutionRecord
)
signal execution_completed(
	rule: AutomationRule,
	record: AutomationExecutionRecord
)
signal execution_failed(
	rule: AutomationRule,
	record: AutomationExecutionRecord
)
signal operation_failed(error: DomainError)

#endregion


#region State

var _configuration: AutomationConfiguration
var _repository: AutomationRuleRepositoryPort
var _executors: Dictionary[StringName, AutomationActionExecutorPort] = {}
var _history: Array[AutomationExecutionRecord] = []
var _active_execution_count: int = 0
var _event_bus: Node

#endregion


#region Public API

## Configures Automation.
func configure(
	configuration: AutomationConfiguration,
	repository: AutomationRuleRepositoryPort
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Automation configuration cannot be null."
			)
		)

	if repository == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Automation rule repository cannot be null."
			)
		)

	_configuration = configuration
	_repository = repository

	return Result.success()


## Connects Automation to EventBus.
func start() -> Result:
	if _configuration == null or _repository == null:
		return _not_configured()

	if not _configuration.enabled:
		return Result.success()

	_event_bus = get_node_or_null("/root/EventBus")

	if _event_bus == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Automation requires EventBus autoload."
			)
		)

	return Result.success()


## Registers an action executor.
func register_executor(
	executor: AutomationActionExecutorPort
) -> Result:
	if executor == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Automation executor cannot be null."
			)
		)

	var executor_id := executor.get_executor_id()

	if executor_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Automation executor requires executor_id."
			)
		)

	if _executors.has(executor_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_ALREADY_REGISTERED,
				"Automation executor is already registered.",
				{&"executor_id": executor_id}
			)
		)

	_executors[executor_id] = executor

	return Result.success()


## Registers a rule.
func register_rule(
	rule: AutomationRule
) -> Result:
	if _configuration == null or _repository == null:
		return _not_configured()

	var all_result := _repository.find_all()

	if all_result.is_failure():
		return all_result

	var rules: Array = all_result.get_value()

	if rules.size() >= _configuration.maximum_rules:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Automation rule limit has been reached."
			)
		)

	if rule.get_actions().size() > _configuration.maximum_actions_per_rule:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Automation rule contains too many actions.",
				{&"rule_id": rule.get_rule_id()}
			)
		)

	var save_result := _repository.save(rule)

	if save_result.is_failure():
		return save_result

	_publish_rule_events(rule)
	rule_registered.emit(rule)

	return Result.success(rule)


## Evaluates every registered rule against an event.
func process_event(
	event: DomainEvent,
	values: Dictionary[StringName, Variant] = {},
	recursion_depth: int = 0
) -> Result:
	if _configuration == null or _repository == null:
		return _not_configured()

	if not _configuration.enabled:
		return Result.success([])

	if recursion_depth > _configuration.maximum_recursion_depth:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Automation recursion depth exceeded."
			)
		)

	var rules_result := _repository.find_all()

	if rules_result.is_failure():
		return rules_result

	var executed_records: Array[AutomationExecutionRecord] = []
	var rules: Array = rules_result.get_value()

	for rule: AutomationRule in rules:
		if not rule.matches(event):
			continue

		if not rule.conditions_satisfied(values):
			continue

		var current_time := int(
			Time.get_unix_time_from_system() * 1000.0
		)

		if not rule.cooldown_expired(current_time):
			continue

		var context := AutomationExecutionContext.new(
			rule.get_rule_id(),
			event,
			values,
			event.get_event_id() if event != null else &"",
			recursion_depth
		)
		var execution_result := execute_rule(rule, context)

		if execution_result.is_success():
			executed_records.append(
				execution_result.get_value()
			)

	return Result.success(executed_records)


## Executes one rule.
func execute_rule(
	rule: AutomationRule,
	context: AutomationExecutionContext
) -> Result:
	if rule == null or context == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Automation execution requires rule and context."
			)
		)

	if (
		_active_execution_count
		>= _configuration.maximum_concurrent_executions
	):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Automation concurrent execution limit was reached."
			)
		)

	var record := AutomationExecutionRecord.new(
		context.get_execution_id(),
		rule.get_rule_id(),
		context.get_created_at_unix_ms()
	)

	_active_execution_count += 1
	record.mark_running()
	rule.record_execution_started(context)
	_publish_rule_events(rule)
	execution_started.emit(rule, record)

	for action in rule.get_actions():
		var executor := _executors.get(
			action.get_executor_id()
		) as AutomationActionExecutorPort

		if executor == null:
			var missing_executor_error := DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Automation action executor is not registered.",
				{
					&"executor_id": action.get_executor_id(),
					&"action_id": action.get_action_id(),
				}
			)

			return _fail_execution(
				rule,
				record,
				missing_executor_error
			)

		if not executor.can_execute(action):
			var rejected_action_error := DomainError.new(
				HydraErrors.INVALID_STATE,
				"Automation executor rejected the action.",
				{
					&"executor_id": action.get_executor_id(),
					&"action_id": action.get_action_id(),
				}
			)

			return _fail_execution(
				rule,
				record,
				rejected_action_error
			)

		var action_result := executor.execute(action, context)

		if action_result.is_failure():
			return _fail_execution(
				rule,
				record,
				action_result.get_error()
			)

		record.mark_action_completed()

	record.mark_succeeded()
	rule.record_execution_completed(record)
	_active_execution_count -= 1

	_add_history(record)
	_repository.save(rule)
	_publish_rule_events(rule)
	execution_completed.emit(rule, record)

	return Result.success(record)


## Returns all rules.
func get_rules() -> Array[AutomationRule]:
	if _repository == null:
		return []

	var result := _repository.find_all()

	if result.is_failure():
		return []

	return result.get_value()


## Returns execution history.
func get_history() -> Array[AutomationExecutionRecord]:
	return _history.duplicate()

#endregion


#region Private methods

func _fail_execution(
	rule: AutomationRule,
	record: AutomationExecutionRecord,
	error: DomainError
) -> Result:
	record.mark_failed(error)
	rule.record_execution_failed(record)
	_active_execution_count = maxi(
		0,
		_active_execution_count - 1
	)

	_add_history(record)
	_repository.save(rule)
	_publish_rule_events(rule)
	execution_failed.emit(rule, record)
	operation_failed.emit(error)

	return Result.failure(error)


func _add_history(
	record: AutomationExecutionRecord
) -> void:
	_history.append(record)

	while (
		_history.size()
		> _configuration.maximum_history_records
	):
		_history.pop_front()


func _publish_rule_events(
	rule: AutomationRule
) -> void:
	var events := rule.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Automation is not configured."
		)
	)

#endregion