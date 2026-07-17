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