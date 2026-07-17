#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

function Write-HydraFile {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    $destination = Join-Path $RepositoryRoot $RelativePath
    $directory = Split-Path $destination -Parent

    if (-not (Test-Path $directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }

    if ((Test-Path $destination) -and -not $Force) {
        Write-Host "[SKIP]  $RelativePath" -ForegroundColor Yellow
        return
    }

    [System.IO.File]::WriteAllText(
        $destination,
        $Content.TrimStart(),
        $utf8WithoutBom
    )

    Write-Host "[WRITE] $RelativePath" -ForegroundColor Green
}

function Assert-HydraRepository {
    $projectFile = Join-Path $RepositoryRoot "project.godot"

    if (-not (Test-Path $projectFile)) {
        throw "Nie znaleziono project.godot w: $RepositoryRoot"
    }
}

Assert-HydraRepository

$files = [ordered]@{}

$files["packages/012_automation/package.cfg"] = @'
[package]

id="012_automation"
name="Automation"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system",
	"009_environment_hub",
	"010_device_hub",
	"011_ai_system"
)
'@

$files["packages/012_automation/README.md"] = @'
# Package 012 — Automation

Automation owns rule definitions, trigger evaluation, condition evaluation,
action execution and execution history.

The package coordinates other modules through ports and EventBus events. It does
not directly communicate with physical devices, AI providers or environmental
sensors.

## Safety

Rules are disabled by default after validation failure.

Destructive actions require an explicit approval policy.

Execution recursion and excessive trigger frequency are limited by runtime
configuration.
'@

$files["packages/012_automation/CHANGELOG.md"] = @'
# Automation changelog

## [0.1.0] - 2026-07-17

### Added

- Added automation trigger, condition and action models.
- Added automation rule aggregate.
- Added execution context and execution record.
- Added action executor and rule repository contracts.
- Added in-memory rule repository.
- Added deterministic action executor.
- Added Automation application service.
- Added rule card and Automation panel.
- Added demo scene and tests.
'@

$files["packages/012_automation/docs/architecture.md"] = @'
# Automation architecture

Automation is an orchestration package.

The domain layer owns rules, conditions, actions and execution history.

The application layer evaluates rules and coordinates action executors.

The infrastructure layer stores rules and adapts external execution targets.

The presentation layer edits and displays normalized rule state.
'@

$files["packages/012_automation/docs/safety.md"] = @'
# Automation safety

Automation must prevent unbounded recursive execution.

Every execution receives a correlation identifier and recursion depth.

A rule may define a cooldown interval.

The runtime limits concurrent executions and action count.

Actions affecting locks, alarms, security modes or external communication should
require explicit approval through a policy implementation.
'@

$files["packages/012_automation/resources/automation_configuration.gd"] = @'
class_name AutomationConfiguration
extends Resource
## Stores runtime limits and behavior for Automation.


#region Runtime

@export_group("Runtime")
@export var enabled: bool = true
@export_range(1, 128, 1) var maximum_rules: int = 64
@export_range(1, 64, 1) var maximum_actions_per_rule: int = 16
@export_range(1, 16, 1) var maximum_recursion_depth: int = 4
@export_range(1, 32, 1) var maximum_concurrent_executions: int = 4

#endregion


#region Timing

@export_group("Timing")
@export_range(0.0, 86400.0, 0.5) var default_cooldown_seconds: float = 5.0
@export_range(0.1, 60.0, 0.1) var scheduler_tick_seconds: float = 1.0
@export_range(1.0, 3600.0, 1.0) var execution_timeout_seconds: float = 30.0

#endregion


#region History

@export_group("History")
@export_range(1, 10000, 1) var maximum_history_records: int = 500
@export var persist_history: bool = false

#endregion
'@

$files["packages/012_automation/resources/default_automation_configuration.tres"] = @'
[gd_resource type="Resource" script_class="AutomationConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/012_automation/resources/automation_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
enabled = true
maximum_rules = 64
maximum_actions_per_rule = 16
maximum_recursion_depth = 4
maximum_concurrent_executions = 4
default_cooldown_seconds = 5.0
scheduler_tick_seconds = 1.0
execution_timeout_seconds = 30.0
maximum_history_records = 500
persist_history = false
'@

$files["packages/012_automation/scripts/domain/automation_operator.gd"] = @'
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
'@

$files["packages/012_automation/scripts/domain/automation_rule_state.gd"] = @'
class_name AutomationRuleState
extends RefCounted
## Defines lifecycle states for automation rules.


#region Values

enum Value {
	DRAFT,
	ENABLED,
	DISABLED,
	SUSPENDED,
	FAILED,
}

#endregion


#region Public API

## Returns a stable rule-state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.DRAFT:
			return &"draft"
		Value.ENABLED:
			return &"enabled"
		Value.DISABLED:
			return &"disabled"
		Value.SUSPENDED:
			return &"suspended"
		Value.FAILED:
			return &"failed"
		_:
			return &"unknown"


## Returns a presentation color for the state.
static func to_color(state: Value) -> Color:
	match state:
		Value.DRAFT:
			return Color("#6e8794")
		Value.ENABLED:
			return Color("#55f2a3")
		Value.DISABLED:
			return Color("#40515b")
		Value.SUSPENDED:
			return Color("#ffbf47")
		Value.FAILED:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion
'@

$files["packages/012_automation/scripts/domain/automation_execution_state.gd"] = @'
class_name AutomationExecutionState
extends RefCounted
## Defines automation execution states.


#region Values

enum Value {
	QUEUED,
	RUNNING,
	SUCCEEDED,
	FAILED,
	CANCELLED,
	SKIPPED,
}

#endregion


#region Public API

## Returns a stable execution-state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.QUEUED:
			return &"queued"
		Value.RUNNING:
			return &"running"
		Value.SUCCEEDED:
			return &"succeeded"
		Value.FAILED:
			return &"failed"
		Value.CANCELLED:
			return &"cancelled"
		Value.SKIPPED:
			return &"skipped"
		_:
			return &"unknown"

#endregion
'@

$files["packages/012_automation/scripts/domain/automation_trigger.gd"] = @'
class_name AutomationTrigger
extends ValueObject
## Represents an immutable rule trigger definition.


#region State

var _trigger_id: StringName
var _event_name: StringName
var _filters: Dictionary[StringName, Variant]

#endregion


#region Construction

## Creates an event-based automation trigger.
func _init(
	trigger_id: StringName,
	event_name: StringName,
	filters: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not trigger_id.is_empty(),
		"AutomationTrigger requires trigger_id."
	)
	assert(
		not event_name.is_empty(),
		"AutomationTrigger requires event_name."
	)

	_trigger_id = trigger_id
	_event_name = event_name
	_filters = filters.duplicate(true)

#endregion


#region Public API

func get_trigger_id() -> StringName:
	return _trigger_id


func get_event_name() -> StringName:
	return _event_name


func get_filters() -> Dictionary[StringName, Variant]:
	return _filters.duplicate(true)


## Returns whether a domain event satisfies this trigger.
func matches(event: DomainEvent) -> bool:
	if event == null:
		return false

	if event.get_event_name() != _event_name:
		return false

	for key in _filters:
		if event.get_payload_value(key) != _filters[key]:
			return false

	return true

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_trigger_id,
		_event_name,
		_filters,
	]

#endregion
'@

$files["packages/012_automation/scripts/domain/automation_condition.gd"] = @'
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
'@

$files["packages/012_automation/scripts/domain/automation_action.gd"] = @'
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
'@

$files["packages/012_automation/scripts/domain/automation_execution_context.gd"] = @'
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
'@

$files["packages/012_automation/scripts/domain/automation_execution_record.gd"] = @'
class_name AutomationExecutionRecord
extends RefCounted
## Stores the result of one automation execution.


#region State

var _execution_id: StringName
var _rule_id: StringName
var _state: AutomationExecutionState.Value
var _started_at_unix_ms: int
var _completed_at_unix_ms: int
var _completed_action_count: int
var _error: DomainError

#endregion


#region Construction

## Creates a queued execution record.
func _init(
	execution_id: StringName,
	rule_id: StringName,
	started_at_unix_ms: int
) -> void:
	assert(
		not execution_id.is_empty(),
		"AutomationExecutionRecord requires execution_id."
	)
	assert(
		not rule_id.is_empty(),
		"AutomationExecutionRecord requires rule_id."
	)

	_execution_id = execution_id
	_rule_id = rule_id
	_started_at_unix_ms = started_at_unix_ms
	_state = AutomationExecutionState.Value.QUEUED

#endregion


#region Public API

func get_execution_id() -> StringName:
	return _execution_id


func get_rule_id() -> StringName:
	return _rule_id


func get_state() -> AutomationExecutionState.Value:
	return _state


func get_started_at_unix_ms() -> int:
	return _started_at_unix_ms


func get_completed_at_unix_ms() -> int:
	return _completed_at_unix_ms


func get_completed_action_count() -> int:
	return _completed_action_count


func get_error() -> DomainError:
	return _error


func mark_running() -> void:
	_state = AutomationExecutionState.Value.RUNNING


func mark_action_completed() -> void:
	_completed_action_count += 1


func mark_succeeded() -> void:
	_state = AutomationExecutionState.Value.SUCCEEDED
	_completed_at_unix_ms = _now()


func mark_failed(error: DomainError) -> void:
	_state = AutomationExecutionState.Value.FAILED
	_error = error
	_completed_at_unix_ms = _now()


func mark_cancelled() -> void:
	_state = AutomationExecutionState.Value.CANCELLED
	_completed_at_unix_ms = _now()


func mark_skipped() -> void:
	_state = AutomationExecutionState.Value.SKIPPED
	_completed_at_unix_ms = _now()

#endregion


#region Private methods

func _now() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)

#endregion
'@

$files["packages/012_automation/scripts/domain/automation_rule.gd"] = @'
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
'@

$files["packages/012_automation/scripts/contracts/automation_action_executor_port.gd"] = @'
@abstract
class_name AutomationActionExecutorPort
extends RefCounted
## Defines a provider-independent action execution boundary.


#region Public API

## Returns the stable executor identifier.
@abstract
func get_executor_id() -> StringName


## Returns whether the executor can process an action.
@abstract
func can_execute(action: AutomationAction) -> bool


## Executes an automation action.
@abstract
func execute(
	action: AutomationAction,
	context: AutomationExecutionContext
) -> Result

#endregion
'@

$files["packages/012_automation/scripts/contracts/automation_rule_repository_port.gd"] = @'
@abstract
class_name AutomationRuleRepositoryPort
extends RefCounted
## Defines persistence operations for automation rules.


#region Public API

@abstract
func save(rule: AutomationRule) -> Result


@abstract
func remove(rule_id: StringName) -> Result


@abstract
func find_by_id(rule_id: StringName) -> Result


@abstract
func find_all() -> Result

#endregion
'@

$files["packages/012_automation/scripts/infrastructure/in_memory_automation_rule_repository.gd"] = @'
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
'@

$files["packages/012_automation/scripts/infrastructure/demo_automation_action_executor.gd"] = @'
class_name DemoAutomationActionExecutor
extends AutomationActionExecutorPort
## Executes deterministic local automation actions for demos.


#region Constants

const EXECUTOR_ID: StringName = &"demo"

#endregion


#region AutomationActionExecutorPort

func get_executor_id() -> StringName:
	return EXECUTOR_ID


func can_execute(action: AutomationAction) -> bool:
	return (
		action != null
		and action.get_executor_id() == EXECUTOR_ID
	)


func execute(
	action: AutomationAction,
	context: AutomationExecutionContext
) -> Result:
	if not can_execute(action):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Demo executor cannot process the action."
			)
		)

	if action.requires_approval():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Demo executor cannot approve protected actions."
			)
		)

	print(
		"AUTOMATION DEMO EXECUTION: ",
		action.get_action_name(),
		" | ",
		action.get_arguments(),
		" | EXECUTION ",
		context.get_execution_id()
	)

	return Result.success(
		{
			&"action_id": action.get_action_id(),
			&"status": &"completed",
		}
	)

#endregion
'@

$files["packages/012_automation/scripts/application/automation_service.gd"] = @'
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
'@

$files["packages/012_automation/scripts/presentation/automation_rule_card.gd"] = @'
class_name AutomationRuleCard
extends WidgetBase
## Displays one automation rule and exposes a state toggle.


#region Signals

signal toggle_requested(rule_id: StringName)
signal execute_requested(rule_id: StringName)

#endregion


#region Nodes

@onready var _indicator: ColorRect = %Indicator
@onready var _name_label: RichTextLabel = %NameLabel
@onready var _description_label: RichTextLabel = %DescriptionLabel
@onready var _state_label: RichTextLabel = %StateLabel
@onready var _trigger_label: RichTextLabel = %TriggerLabel
@onready var _stats_label: RichTextLabel = %StatsLabel

#endregion


#region State

var _rule: AutomationRule

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if _rule == null:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if not mouse_event.pressed:
			return

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			toggle_requested.emit(_rule.get_rule_id())
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			execute_requested.emit(_rule.get_rule_id())
			accept_event()

#endregion


#region Public API

## Applies an automation rule.
func apply_rule(rule: AutomationRule) -> void:
	assert(rule != null, "Automation rule card requires rule.")

	_rule = rule

	if not is_node_ready():
		return

	var state := rule.get_state()

	_indicator.color = AutomationRuleState.to_color(state)
	_name_label.text = rule.get_display_name()
	_description_label.text = rule.get_description()
	_state_label.text = String(
		AutomationRuleState.to_string_name(state)
	).to_upper()
	_trigger_label.text = (
		"TRIGGER  //  %s"
		% String(
			rule.get_trigger().get_event_name()
		).to_upper()
	)
	_stats_label.text = (
		"ACTIONS  //  %d    EXECUTIONS  //  %d"
		% [
			rule.get_actions().size(),
			rule.get_execution_count(),
		]
	)

#endregion
'@

$files["packages/012_automation/scripts/presentation/automation_panel.gd"] = @'
class_name AutomationPanel
extends PanelBase
## Main Automation management panel.


#region Constants

const CARD_WIDTH: float = 430.0
const CARD_HEIGHT: float = 170.0
const CARD_START_X: float = 54.0
const CARD_START_Y: float = 184.0
const CARD_HORIZONTAL_GAP: float = 24.0
const CARD_VERTICAL_GAP: float = 20.0
const CARD_COLUMNS: int = 2

#endregion


#region Nodes

@onready var _rule_layer: Control = %RuleLayer
@onready var _summary_label: RichTextLabel = %SummaryLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: AutomationService
var _rule_card_scene: PackedScene = preload(
	"res://packages/012_automation/scenes/automation_rule_card.tscn"
)

#endregion


#region Public API

## Binds the panel to Automation.
func bind_service(service: AutomationService) -> void:
	assert(service != null, "Automation service cannot be null.")

	_disconnect_service()
	_service = service

	_service.rule_registered.connect(_on_rule_registered)
	_service.rule_updated.connect(_on_rule_updated)
	_service.execution_completed.connect(_on_execution_completed)
	_service.execution_failed.connect(_on_execution_failed)
	_service.operation_failed.connect(_on_operation_failed)

	rebuild_rules()


## Rebuilds visible rule cards.
func rebuild_rules() -> void:
	if _service == null:
		return

	var rules := _service.get_rules()

	for child in _rule_layer.get_children():
		child.queue_free()

	for index in rules.size():
		var card := (
			_rule_card_scene.instantiate()
			as AutomationRuleCard
		)
		var column := index % CARD_COLUMNS
		var row := index / CARD_COLUMNS

		card.position = Vector2(
			CARD_START_X + (
				column * (
					CARD_WIDTH + CARD_HORIZONTAL_GAP
				)
			),
			CARD_START_Y + (
				row * (
					CARD_HEIGHT + CARD_VERTICAL_GAP
				)
			)
		)
		card.size = Vector2(CARD_WIDTH, CARD_HEIGHT)

		_rule_layer.add_child(card)
		card.apply_rule(rules[index])
		card.toggle_requested.connect(_on_toggle_requested)
		card.execute_requested.connect(_on_execute_requested)

	_update_summary(rules)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.rule_registered.is_connected(_on_rule_registered):
		_service.rule_registered.disconnect(_on_rule_registered)

	if _service.rule_updated.is_connected(_on_rule_updated):
		_service.rule_updated.disconnect(_on_rule_updated)

	if _service.execution_completed.is_connected(
		_on_execution_completed
	):
		_service.execution_completed.disconnect(
			_on_execution_completed
		)

	if _service.execution_failed.is_connected(
		_on_execution_failed
	):
		_service.execution_failed.disconnect(
			_on_execution_failed
		)

	if _service.operation_failed.is_connected(
		_on_operation_failed
	):
		_service.operation_failed.disconnect(
			_on_operation_failed
		)


func _update_summary(
	rules: Array[AutomationRule]
) -> void:
	var enabled_count := 0
	var failed_count := 0

	for rule in rules:
		if rule.get_state() == AutomationRuleState.Value.ENABLED:
			enabled_count += 1
		elif rule.get_state() == AutomationRuleState.Value.FAILED:
			failed_count += 1

	_summary_label.text = (
		"RULES  //  %d    ENABLED  //  %d    FAILED  //  %d"
		% [
			rules.size(),
			enabled_count,
			failed_count,
		]
	)


func _on_toggle_requested(rule_id: StringName) -> void:
	if _service == null:
		return

	for rule in _service.get_rules():
		if rule.get_rule_id() != rule_id:
			continue

		if rule.get_state() == AutomationRuleState.Value.ENABLED:
			rule.disable()
		else:
			rule.enable()

		rebuild_rules()
		return


func _on_execute_requested(rule_id: StringName) -> void:
	if _service == null:
		return

	for rule in _service.get_rules():
		if rule.get_rule_id() != rule_id:
			continue

		var context := AutomationExecutionContext.new(
			rule_id,
			null,
			{&"manual": true}
		)
		var result := _service.execute_rule(rule, context)

		if result.is_failure():
			_on_operation_failed(result.get_error())

		return


func _on_rule_registered(
	_rule: AutomationRule
) -> void:
	rebuild_rules()


func _on_rule_updated(
	_rule: AutomationRule
) -> void:
	rebuild_rules()


func _on_execution_completed(
	_rule: AutomationRule,
	_record: AutomationExecutionRecord
) -> void:
	_error_label.visible = false
	rebuild_rules()


func _on_execution_failed(
	_rule: AutomationRule,
	record: AutomationExecutionRecord
) -> void:
	if record.get_error() != null:
		_on_operation_failed(record.get_error())


func _on_operation_failed(error: DomainError) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]AUTOMATION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

#endregion
'@

$files["packages/012_automation/scenes/automation_rule_card.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/012_automation/scripts/presentation/automation_rule_card.gd" id="1"]

[node name="AutomationRuleCard" type="Control"]
custom_minimum_size = Vector2(430, 170)
layout_mode = 3
anchors_preset = 0
offset_right = 430.0
offset_bottom = 170.0
mouse_filter = 0
script = ExtResource("1")
widget_id = &"automation_rule_card"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.9)

[node name="Indicator" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 12.0
offset_top = 12.0
offset_right = 18.0
offset_bottom = 158.0
mouse_filter = 2
color = Color(0.25098, 0.317647, 0.356863, 1)

[node name="NameLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 12.0
offset_right = 320.0
offset_bottom = 42.0
bbcode_enabled = true
text = "[color=#32d8ff]AUTOMATION RULE[/color]"
fit_content = true
scroll_active = false

[node name="StateLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 330.0
offset_top = 12.0
offset_right = 412.0
offset_bottom = 42.0
text = "DRAFT"
fit_content = true
scroll_active = false

[node name="DescriptionLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 48.0
offset_right = 408.0
offset_bottom = 84.0
text = "Rule description."
scroll_active = false

[node name="TriggerLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 94.0
offset_right = 408.0
offset_bottom = 120.0
bbcode_enabled = true
text = "[color=#d6aa48]TRIGGER  //  UNKNOWN[/color]"
fit_content = true
scroll_active = false

[node name="StatsLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 132.0
offset_right = 408.0
offset_bottom = 160.0
text = "ACTIONS  //  0    EXECUTIONS  //  0"
fit_content = true
scroll_active = false
'@

$files["packages/012_automation/scenes/automation_panel.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/012_automation/scripts/presentation/automation_panel.gd" id="1"]

[node name="AutomationPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 1020.0
offset_bottom = 900.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"automation_panel"
starts_open = true

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.0117647, 0.0313725, 0.0509804, 0.97)

[node name="HeaderAccent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 28.0
offset_top = 24.0
offset_right = 34.0
offset_bottom = 94.0
mouse_filter = 2
color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 20.0
offset_right = 700.0
offset_bottom = 60.0
bbcode_enabled = true
text = "[font_size=30][color=#32d8ff]AUTOMATION[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 900.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]RULE ORCHESTRATION MATRIX  //  CHANNEL 012[/color]"
fit_content = true
scroll_active = false

[node name="SummaryLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 116.0
offset_right = 960.0
offset_bottom = 150.0
bbcode_enabled = true
text = "[color=#d6aa48]RULES  //  0    ENABLED  //  0    FAILED  //  0[/color]"
fit_content = true
scroll_active = false

[node name="RuleLayer" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 1

[node name="ErrorLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 54.0
offset_top = 824.0
offset_right = 966.0
offset_bottom = 884.0
bbcode_enabled = true
text = "[color=#ff4f62]AUTOMATION FAILURE[/color]"
scroll_active = false
'@

$files["packages/012_automation/demo/automation_demo.gd"] = @'
class_name AutomationDemo
extends Control
## Demonstrates Automation with local deterministic rules.


#region Nodes

@onready var _panel: AutomationPanel = %AutomationPanel

#endregion


#region State

var _service: AutomationService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = AutomationService.new()
	_service.name = "AutomationService"
	add_child(_service)

	var configuration := AutomationConfiguration.new()
	var repository := InMemoryAutomationRuleRepository.new()
	var executor := DemoAutomationActionExecutor.new()

	var configuration_result := _service.configure(
		configuration,
		repository
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_service.register_executor(executor)
	_service.start()
	_panel.bind_service(_service)

	_register_demo_rules()

#endregion


#region Private methods

func _register_demo_rules() -> void:
	var temperature_rule := AutomationRule.new(
		EntityId.generate(),
		&"cool_server_room",
		"SERVER ROOM COOLING",
		"Increase cooling when server-room temperature is high.",
		AutomationTrigger.new(
			&"server_temperature_trigger",
			&"hydra.environment.zone.updated",
			{&"zone_id": &"server_room"}
		),
		[
			AutomationCondition.new(
				&"temperature_condition",
				&"temperature",
				AutomationOperator.Value.GREATER_THAN,
				26.0
			),
		],
		[
			AutomationAction.new(
				&"cooling_action",
				&"demo",
				&"increase_cooling",
				{
					&"device_id": &"server_fan",
					&"speed_percent": 90.0,
				}
			),
		],
		5.0
	)
	temperature_rule.enable()
	_service.register_rule(temperature_rule)

	var security_rule := AutomationRule.new(
		EntityId.generate(),
		&"security_alert",
		"SECURITY ALERT RESPONSE",
		"Activate tactical alert response after a security alarm.",
		AutomationTrigger.new(
			&"security_alarm_trigger",
			&"hydra.home.security.changed",
			{&"current_state": "ALARM"}
		),
		[],
		[
			AutomationAction.new(
				&"security_response_action",
				&"demo",
				&"activate_security_response",
				{&"priority": &"critical"},
				false
			),
		],
		10.0
	)
	security_rule.enable()
	_service.register_rule(security_rule)

	_panel.rebuild_rules()

#endregion
'@

$files["packages/012_automation/demo/automation_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/012_automation/demo/automation_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/012_automation/scenes/automation_panel.tscn" id="2"]

[node name="AutomationDemo" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00392157, 0.0117647, 0.0196078, 1)

[node name="AutomationPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 450.0
offset_top = 90.0
offset_right = 1470.0
offset_bottom = 990.0
'@

$files["packages/012_automation/tests/unit/test_automation_condition.gd"] = @'
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
'@

$files["packages/012_automation/tests/unit/test_automation_rule.gd"] = @'
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
'@

$files["packages/012_automation/tests/unit/test_automation_execution_record.gd"] = @'
class_name AutomationExecutionRecordTest
extends RefCounted
## Provides AutomationExecutionRecord tests.


#region Tests

static func run() -> void:
	var record := AutomationExecutionRecord.new(
		&"execution_01",
		&"rule_01",
		1000
	)

	assert(
		record.get_state()
		== AutomationExecutionState.Value.QUEUED
	)

	record.mark_running()
	record.mark_action_completed()
	record.mark_succeeded()

	assert(
		record.get_state()
		== AutomationExecutionState.Value.SUCCEEDED
	)
	assert(record.get_completed_action_count() == 1)
	assert(record.get_completed_at_unix_ms() > 0)

#endregion
'@

$files["packages/012_automation/tests/integration/test_automation_service.gd"] = @'
class_name AutomationServiceTest
extends RefCounted
## Provides Automation service composition tests.


#region Tests

static func run() -> void:
	var service := AutomationService.new()
	var configuration := AutomationConfiguration.new()
	var repository := InMemoryAutomationRuleRepository.new()
	var executor := DemoAutomationActionExecutor.new()

	assert(
		service.configure(
			configuration,
			repository
		).is_success()
	)
	assert(service.register_executor(executor).is_success())

#endregion
'@

$files["autoload/automation.gd"] = @'
extends AutomationService
## Global Automation application service.
##
## Runtime composition must configure the repository and action executors.
'@

$files["docs/package-dependencies-012.md"] = @'
# Package dependency 012

```text
012_automation
├── 001_foundation
├── 002_design_system
├── 003_widget_library
├── 004_animation_system
├── 009_environment_hub
├── 010_device_hub
└── 011_ai_system
'@

Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing Package 012 - Automation..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

Write-Host ""
Write-Host "Package 012 installed." -ForegroundColor Green
Write-Host ""
Write-Host "Optional autoload:" -ForegroundColor Cyan
Write-Host "Automation res://autoload/automation.gd"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(automation): implement package 012"'
Write-Host "git push"