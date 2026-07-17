class_name AutomationRuleState
extends RefCounted
## Defines lifecycle states for automation rules.


#region Values

enum Value {
	DRAFT,
	ENABLED,
	DISABLED,
	SUSPENDED,
	FAILED,
}

#endregion


#region Public API

## Returns a stable rule-state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.DRAFT:
			return &"draft"
		Value.ENABLED:
			return &"enabled"
		Value.DISABLED:
			return &"disabled"
		Value.SUSPENDED:
			return &"suspended"
		Value.FAILED:
			return &"failed"
		_:
			return &"unknown"


## Returns a presentation color for the state.
static func to_color(state: Value) -> Color:
	match state:
		Value.DRAFT:
			return Color("#6e8794")
		Value.ENABLED:
			return Color("#55f2a3")
		Value.DISABLED:
			return Color("#40515b")
		Value.SUSPENDED:
			return Color("#ffbf47")
		Value.FAILED:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion