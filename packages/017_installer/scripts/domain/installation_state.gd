class_name InstallationState
extends RefCounted
## Defines installation lifecycle states.


#region Values

enum Value {
	DRAFT,
	VALIDATED,
	INSTALLING,
	COMPLETED,
	FAILED,
	ROLLING_BACK,
	ROLLED_BACK,
	CANCELLED,
}

#endregion


#region Public API

## Returns a stable state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.DRAFT:
			return &"draft"
		Value.VALIDATED:
			return &"validated"
		Value.INSTALLING:
			return &"installing"
		Value.COMPLETED:
			return &"completed"
		Value.FAILED:
			return &"failed"
		Value.ROLLING_BACK:
			return &"rolling_back"
		Value.ROLLED_BACK:
			return &"rolled_back"
		Value.CANCELLED:
			return &"cancelled"
		_:
			return &"unknown"

#endregion