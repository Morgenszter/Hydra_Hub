class_name DeviceConnectionState
extends RefCounted
## Defines normalized device connection states.


#region Values

enum Value {
	UNKNOWN,
	DISCOVERING,
	CONNECTING,
	ONLINE,
	DEGRADED,
	OFFLINE,
	ERROR,
}

#endregion


#region Public API

## Returns a stable lowercase state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.DISCOVERING:
			return &"discovering"
		Value.CONNECTING:
			return &"connecting"
		Value.ONLINE:
			return &"online"
		Value.DEGRADED:
			return &"degraded"
		Value.OFFLINE:
			return &"offline"
		Value.ERROR:
			return &"error"
		_:
			return &"unknown"


## Returns a presentation color for the state.
static func to_color(state: Value) -> Color:
	match state:
		Value.DISCOVERING:
			return Color("#32d8ff")
		Value.CONNECTING:
			return Color("#d6aa48")
		Value.ONLINE:
			return Color("#55f2a3")
		Value.DEGRADED:
			return Color("#ffbf47")
		Value.OFFLINE:
			return Color("#40515b")
		Value.ERROR:
			return Color("#ff4f62")
		_:
			return Color("#6e8794")

#endregion