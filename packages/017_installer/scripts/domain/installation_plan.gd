class_name InstallationPlan
extends AggregateRoot
## Owns one installation plan and lifecycle.


#region Events

const EVENT_STATE_CHANGED: StringName = \
	&"hydra.installer.state_changed"
const EVENT_OPERATION_COMPLETED: StringName = \
	&"hydra.installer.operation_completed"
const EVENT_FAILED: StringName = \
	&"hydra.installer.failed"

#endregion


#region State

var _manifest: InstallationManifest
var _operations: Array[InstallationOperation] = []
var _state: InstallationState.Value = InstallationState.Value.DRAFT
var _completed_operations: int = 0
var _error: DomainError

#endregion


#region Construction

## Creates an installation plan.
func _init(
	id: EntityId,
	manifest: InstallationManifest,
	operations: Array[InstallationOperation]
) -> void:
	super(id)

	assert(
		manifest != null,
		"InstallationPlan requires manifest."
	)

	_manifest = manifest
	_operations = operations.duplicate()

#endregion


#region Public API

func get_manifest() -> InstallationManifest:
	return _manifest


func get_operations() -> Array[InstallationOperation]:
	return _operations.duplicate()


func get_state() -> InstallationState.Value:
	return _state


func get_completed_operations() -> int:
	return _completed_operations


func get_operation_count() -> int:
	return _operations.size()


func get_progress() -> float:
	if _operations.is_empty():
		return 1.0

	return float(_completed_operations) / float(_operations.size())


func get_error() -> DomainError:
	return _error


func validate_plan(
	maximum_operations: int
) -> Result:
	var manifest_result := _manifest.validate()

	if manifest_result.is_failure():
		return manifest_result

	if _operations.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Installation plan contains no operations."
			)
		)

	if _operations.size() > maximum_operations:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installation operation limit exceeded."
			)
		)

	for operation in _operations:
		var operation_result := operation.validate()

		if operation_result.is_failure():
			return operation_result

	_state = InstallationState.Value.VALIDATED
	_record_state_event()

	return Result.success()


func start_installation() -> Result:
	if _state != InstallationState.Value.VALIDATED:
		return _invalid_state("start")

	_state = InstallationState.Value.INSTALLING
	_record_state_event()

	return Result.success()


func record_operation_completed(
	operation: InstallationOperation
) -> void:
	_completed_operations += 1
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_OPERATION_COMPLETED,
			{
				&"package_id": _manifest.package_id,
				&"operation_id": operation.get_operation_id(),
				&"completed": _completed_operations,
				&"total": _operations.size(),
			}
		)
	)


func complete_installation() -> Result:
	if _state != InstallationState.Value.INSTALLING:
		return _invalid_state("complete")

	_state = InstallationState.Value.COMPLETED
	increment_version()
	_record_state_event()

	return Result.success()


func fail_installation(
	error: DomainError
) -> Result:
	_error = error
	_state = InstallationState.Value.FAILED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_FAILED,
			{
				&"package_id": _manifest.package_id,
				&"error": error.to_dictionary(),
			}
		)
	)

	_record_state_event()

	return Result.success()


func start_rollback() -> Result:
	_state = InstallationState.Value.ROLLING_BACK
	_record_state_event()

	return Result.success()


func complete_rollback() -> Result:
	_state = InstallationState.Value.ROLLED_BACK
	_record_state_event()

	return Result.success()

#endregion


#region Private methods

func _invalid_state(operation: String) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Installation state transition is invalid.",
			{
				&"operation": operation,
				&"state":
					InstallationState.to_string_name(_state),
			}
		)
	)


func _record_state_event() -> void:
	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_CHANGED,
			{
				&"package_id": _manifest.package_id,
				&"state":
					InstallationState.to_string_name(_state),
			}
		)
	)

#endregion