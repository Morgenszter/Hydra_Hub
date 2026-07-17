class_name SystemHealthState
extends RefCounted
## Defines aggregated system health states.


#region Values

enum Value {
	UNKNOWN,
	HEALTHY,
	DEGRADED,
	UNHEALTHY,
	CRITICAL,
}

#endregion


#region Public API

## Returns a stable health-state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.HEALTHY:
			return &"healthy"
		Value.DEGRADED:
			return &"degraded"
		Value.UNHEALTHY:
			return &"unhealthy"
		Value.CRITICAL:
			return &"critical"
		_:
			return &"unknown"


## Returns a presentation color.
static func to_color(state: Value) -> Color:
	match state:
		Value.HEALTHY:
			return Color("#55f2a3")
		Value.DEGRADED:
			return Color("#ffbf47")
		Value.UNHEALTHY:
			return Color("#ff7a4d")
		Value.CRITICAL:
			return Color("#ff4f62")
		_:
			return Color("#40515b")

#endregion