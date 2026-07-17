class_name DebugLogLevel
extends RefCounted
## Defines Debug Tools log levels.


#region Values

enum Value {
	TRACE,
	DEBUG,
	INFO,
	WARNING,
	ERROR,
	CRITICAL,
}

#endregion


#region Public API

## Returns a stable lowercase identifier.
static func to_string_name(level: Value) -> StringName:
	match level:
		Value.TRACE:
			return &"trace"
		Value.DEBUG:
			return &"debug"
		Value.INFO:
			return &"info"
		Value.WARNING:
			return &"warning"
		Value.ERROR:
			return &"error"
		Value.CRITICAL:
			return &"critical"
		_:
			return &"unknown"


## Returns a presentation color.
static func to_color(level: Value) -> Color:
	match level:
		Value.TRACE:
			return Color("#40515b")
		Value.DEBUG:
			return Color("#6e8794")
		Value.INFO:
			return Color("#32d8ff")
		Value.WARNING:
			return Color("#ffbf47")
		Value.ERROR:
			return Color("#ff7a4d")
		Value.CRITICAL:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion