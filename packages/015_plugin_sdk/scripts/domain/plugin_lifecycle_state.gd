class_name PluginLifecycleState
extends RefCounted
## Defines plugin lifecycle states.


#region Values

enum Value {
	DISCOVERED,
	VALIDATING,
	VALIDATED,
	INITIALIZING,
	READY,
	STARTING,
	RUNNING,
	STOPPING,
	STOPPED,
	FAILED,
	DISPOSED,
}

#endregion


#region Public API

## Returns a stable lifecycle identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.DISCOVERED:
			return &"discovered"
		Value.VALIDATING:
			return &"validating"
		Value.VALIDATED:
			return &"validated"
		Value.INITIALIZING:
			return &"initializing"
		Value.READY:
			return &"ready"
		Value.STARTING:
			return &"starting"
		Value.RUNNING:
			return &"running"
		Value.STOPPING:
			return &"stopping"
		Value.STOPPED:
			return &"stopped"
		Value.FAILED:
			return &"failed"
		Value.DISPOSED:
			return &"disposed"
		_:
			return &"unknown"

#endregion