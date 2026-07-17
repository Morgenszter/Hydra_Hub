class_name DemoAutomationActionExecutor
extends AutomationActionExecutorPort
## Executes deterministic local automation actions for demos.


#region Constants

const EXECUTOR_ID: StringName = &"demo"

#endregion


#region AutomationActionExecutorPort

func get_executor_id() -> StringName:
	return EXECUTOR_ID


func can_execute(action: AutomationAction) -> bool:
	return (
		action != null
		and action.get_executor_id() == EXECUTOR_ID
	)


func execute(
	action: AutomationAction,
	context: AutomationExecutionContext
) -> Result:
	if not can_execute(action):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Demo executor cannot process the action."
			)
		)

	if action.requires_approval():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Demo executor cannot approve protected actions."
			)
		)

	print(
		"AUTOMATION DEMO EXECUTION: ",
		action.get_action_name(),
		" | ",
		action.get_arguments(),
		" | EXECUTION ",
		context.get_execution_id()
	)

	return Result.success(
		{
			&"action_id": action.get_action_id(),
			&"status": &"completed",
		}
	)

#endregion