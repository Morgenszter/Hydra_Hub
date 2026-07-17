class_name VoiceSessionState
extends RefCounted
## Defines stable lifecycle states for a voice interaction session.


#region State

enum Value {
	IDLE,
	ARMED,
	LISTENING,
	PROCESSING,
	SPEAKING,
	COMPLETED,
	CANCELLED,
	FAILED,
}

#endregion


#region Public API

## Returns a stable lowercase identifier for the supplied state.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.IDLE:
			return &"idle"
		Value.ARMED:
			return &"armed"
		Value.LISTENING:
			return &"listening"
		Value.PROCESSING:
			return &"processing"
		Value.SPEAKING:
			return &"speaking"
		Value.COMPLETED:
			return &"completed"
		Value.CANCELLED:
			return &"cancelled"
		Value.FAILED:
			return &"failed"
		_:
			return &"unknown"

#endregion