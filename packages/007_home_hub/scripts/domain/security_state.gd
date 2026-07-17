class_name SecurityState
extends RefCounted
## Defines stable residential security states.


#region Values

enum Value {
	UNKNOWN,
	DISARMED,
	ARMED_HOME,
	ARMED_AWAY,
	ALARM,
}

#endregion


#region Public API

## Returns a stable display label for the supplied state.
static func to_label(state: Value) -> String:
	match state:
		Value.DISARMED:
			return "DISARMED"
		Value.ARMED_HOME:
			return "ARMED HOME"
		Value.ARMED_AWAY:
			return "ARMED AWAY"
		Value.ALARM:
			return "ALARM"
		_:
			return "UNKNOWN"

#endregion