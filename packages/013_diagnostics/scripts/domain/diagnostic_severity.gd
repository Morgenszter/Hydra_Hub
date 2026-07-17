class_name DiagnosticSeverity
extends RefCounted
## Defines diagnostic finding severity.


#region Values

enum Value {
	TRACE,
	INFO,
	NOTICE,
	WARNING,
	ERROR,
	CRITICAL,
}

#endregion


#region Public API

## Returns a stable severity identifier.
static func to_string_name(severity: Value) -> StringName:
	match severity:
		Value.TRACE:
			return &"trace"
		Value.INFO:
			return &"info"
		Value.NOTICE:
			return &"notice"
		Value.WARNING:
			return &"warning"
		Value.ERROR:
			return &"error"
		Value.CRITICAL:
			return &"critical"
		_:
			return &"unknown"


## Returns a presentation color.
static func to_color(severity: Value) -> Color:
	match severity:
		Value.TRACE:
			return Color("#40515b")
		Value.INFO:
			return Color("#32d8ff")
		Value.NOTICE:
			return Color("#55f2a3")
		Value.WARNING:
			return Color("#ffbf47")
		Value.ERROR:
			return Color("#ff7a4d")
		Value.CRITICAL:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion