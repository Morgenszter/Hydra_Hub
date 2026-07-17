class_name EnvironmentAlertLevel
extends RefCounted
## Defines environmental alert severity.


#region Values

enum Value {
	NORMAL,
	WARNING,
	CRITICAL,
	UNAVAILABLE,
}

#endregion


#region Public API

## Returns a stable alert label.
static func to_label(level: Value) -> String:
	match level:
		Value.NORMAL:
			return "NORMAL"
		Value.WARNING:
			return "WARNING"
		Value.CRITICAL:
			return "CRITICAL"
		Value.UNAVAILABLE:
			return "UNAVAILABLE"
		_:
			return "UNKNOWN"


## Returns the presentation color for an alert level.
static func to_color(level: Value) -> Color:
	match level:
		Value.NORMAL:
			return Color("#55f2a3")
		Value.WARNING:
			return Color("#ffbf47")
		Value.CRITICAL:
			return Color("#ff4f62")
		Value.UNAVAILABLE:
			return Color("#40515b")
		_:
			return Color.WHITE

#endregion