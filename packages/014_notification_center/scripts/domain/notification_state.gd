class_name NotificationState
extends RefCounted
## Defines notification lifecycle state.


#region Values

enum Value {
	PENDING,
	DELIVERED,
	ACKNOWLEDGED,
	EXPIRED,
	DISMISSED,
}

#endregion


#region Public API

## Returns a stable state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.PENDING:
			return &"pending"
		Value.DELIVERED:
			return &"delivered"
		Value.ACKNOWLEDGED:
			return &"acknowledged"
		Value.EXPIRED:
			return &"expired"
		Value.DISMISSED:
			return &"dismissed"
		_:
			return &"unknown"

#endregion