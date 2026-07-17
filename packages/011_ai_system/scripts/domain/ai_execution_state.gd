class_name AiExecutionState
extends RefCounted
## Defines AI request lifecycle states.


#region Values

enum Value {
	IDLE,
	QUEUED,
	GENERATING,
	COMPLETED,
	CANCELLED,
	FAILED,
}

#endregion


#region Public API

## Returns a stable lowercase state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.IDLE:
			return &"idle"
		Value.QUEUED:
			return &"queued"
		Value.GENERATING:
			return &"generating"
		Value.COMPLETED:
			return &"completed"
		Value.CANCELLED:
			return &"cancelled"
		Value.FAILED:
			return &"failed"
		_:
			return &"unknown"


## Returns a presentation color for the supplied state.
static func to_color(state: Value) -> Color:
	match state:
		Value.IDLE:
			return Color("#40515b")
		Value.QUEUED:
			return Color("#d6aa48")
		Value.GENERATING:
			return Color("#32d8ff")
		Value.COMPLETED:
			return Color("#55f2a3")
		Value.CANCELLED:
			return Color("#6e8794")
		Value.FAILED:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion