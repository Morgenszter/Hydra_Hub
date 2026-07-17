class_name BootState
extends RefCounted
## Defines Boot Loader lifecycle states.


#region Values

enum Value {
	IDLE,
	VALIDATING,
	BOOTING,
	COMPLETED,
	FAILED,
	CANCELLED,
	TRANSITIONING,
}

#endregion


#region Public API

## Returns a stable boot-state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.IDLE:
			return &"idle"
		Value.VALIDATING:
			return &"validating"
		Value.BOOTING:
			return &"booting"
		Value.COMPLETED:
			return &"completed"
		Value.FAILED:
			return &"failed"
		Value.CANCELLED:
			return &"cancelled"
		Value.TRANSITIONING:
			return &"transitioning"
		_:
			return &"unknown"

#endregion