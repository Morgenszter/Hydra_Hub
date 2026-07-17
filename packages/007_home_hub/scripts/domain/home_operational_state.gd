class_name HomeOperationalState
extends RefCounted
## Defines stable operational states for a managed home.


#region Values

enum Value {
	UNKNOWN,
	OFFLINE,
	DEGRADED,
	NORMAL,
	ALERT,
	EMERGENCY,
}

#endregion


#region Public API

## Returns a stable lowercase identifier for the supplied state.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.OFFLINE:
			return &"offline"
		Value.DEGRADED:
			return &"degraded"
		Value.NORMAL:
			return &"normal"
		Value.ALERT:
			return &"alert"
		Value.EMERGENCY:
			return &"emergency"
		_:
			return &"unknown"


## Returns the presentation color for the supplied state.
static func to_color(state: Value) -> Color:
	match state:
		Value.OFFLINE:
			return Color("#40515b")
		Value.DEGRADED:
			return Color("#ffbf47")
		Value.NORMAL:
			return Color("#55f2a3")
		Value.ALERT:
			return Color("#ff8b3d")
		Value.EMERGENCY:
			return Color("#ff4f62")
		_:
			return Color("#6e8794")

#endregion