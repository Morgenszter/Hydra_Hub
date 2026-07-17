@abstract
class_name BootStep
extends RefCounted
## Defines one ordered Boot Loader operation.


#region Public API

## Returns a stable step identifier.
@abstract
func get_step_id() -> StringName


## Returns a human-readable step name.
@abstract
func get_display_name() -> String


## Returns the ascending execution order.
@abstract
func get_order() -> int


## Returns whether failure stops startup.
@abstract
func is_critical() -> bool


## Validates this step before startup.
func validate() -> Result:
	if get_step_id().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot step requires step_id."
			)
		)

	if get_display_name().strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot step requires display_name."
			)
		)

	return Result.success()


## Executes the boot step.
@abstract
func execute() -> Result

#endregion