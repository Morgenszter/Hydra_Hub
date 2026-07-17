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