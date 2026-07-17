class_name NotificationPriority
extends RefCounted
## Defines notification delivery priority.


#region Values

enum Value {
	LOW,
	NORMAL,
	HIGH,
	URGENT,
	CRITICAL,
}

#endregion


#region Public API

## Returns a stable priority identifier.
static func to_string_name(priority: Value) -> StringName:
	match priority:
		Value.LOW:
			return &"low"
		Value.NORMAL:
			return &"normal"
		Value.HIGH:
			return &"high"
		Value.URGENT:
			return &"urgent"
		Value.CRITICAL:
			return &"critical"
		_:
			return &"unknown"


## Returns a presentation color.
static func to_color(priority: Value) -> Color:
	match priority:
		Value.LOW:
			return Color("#40515b")
		Value.NORMAL:
			return Color("#32d8ff")
		Value.HIGH:
			return Color("#d6aa48")
		Value.URGENT:
			return Color("#ff8b3d")
		Value.CRITICAL:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion