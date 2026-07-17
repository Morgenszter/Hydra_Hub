class_name AiMessageRole
extends RefCounted
## Defines stable conversational message roles.


#region Values

enum Value {
	SYSTEM,
	USER,
	ASSISTANT,
	TOOL,
}

#endregion


#region Public API

## Returns a stable lowercase role identifier.
static func to_string_name(role: Value) -> StringName:
	match role:
		Value.SYSTEM:
			return &"system"
		Value.USER:
			return &"user"
		Value.ASSISTANT:
			return &"assistant"
		Value.TOOL:
			return &"tool"
		_:
			return &"unknown"

#endregion