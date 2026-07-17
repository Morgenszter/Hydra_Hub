@abstract
class_name AutomationActionExecutorPort
extends RefCounted
## Defines a provider-independent action execution boundary.


#region Public API

## Returns the stable executor identifier.
@abstract
func get_executor_id() -> StringName


## Returns whether the executor can process an action.
@abstract
func can_execute(action: AutomationAction) -> bool


## Executes an automation action.
@abstract
func execute(
	action: AutomationAction,
	context: AutomationExecutionContext
) -> Result

#endregion