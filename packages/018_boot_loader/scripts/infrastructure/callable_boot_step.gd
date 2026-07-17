class_name CallableBootStep
extends BootStep
## Executes one Callable as a Boot Loader step.


#region State

var _step_id: StringName
var _display_name: String
var _order: int
var _critical: bool
var _operation: Callable

#endregion


#region Construction

func _init(
	step_id: StringName,
	display_name: String,
	order: int,
	critical: bool,
	operation: Callable
) -> void:
	_step_id = step_id
	_display_name = display_name.strip_edges()
	_order = order
	_critical = critical
	_operation = operation

#endregion


#region BootStep

func get_step_id() -> StringName:
	return _step_id


func get_display_name() -> String:
	return _display_name


func get_order() -> int:
	return _order


func is_critical() -> bool:
	return _critical


func validate() -> Result:
	var base_result := super()

	if base_result.is_failure():
		return base_result

	if not _operation.is_valid():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot step operation is invalid.",
				{&"step_id": _step_id}
			)
		)

	return Result.success()


func execute() -> Result:
	var response: Variant = _operation.call()

	if response is Result:
		return response as Result

	if response == null:
		return Result.success()

	return Result.success(response)

#endregion